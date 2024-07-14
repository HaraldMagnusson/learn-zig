const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;
const float = @import("util.zig").float;
const uint = @import("util.zig").uint;
const math = @import("math.zig");

const Cmd = enum { help, exit, gif, gifn, exact, drops, when };
var reader = StdinReader(10).new();

test "force testing of math.zig" {
    _ = @import("math.zig");
}

pub fn main() !void {
    clearTerm();
    printHelp();

    var cmd: Cmd = undefined;
    while (true) {
        printText("> ");

        cmd = try reader.readCmd() orelse {
            printText("Enter a valid command\n");
            continue;
        };

        switch (cmd) {
            .help => {
                clearTerm();
                printHelp();
            },
            .exit => {
                break;
            },
            .gif => {
                actions.gif();
                reader.waitForInput();
                clearTerm();
            },
            .gifn => {
                actions.gifn();
                reader.waitForInput();
                clearTerm();
            },
            .exact => {
                actions.exact();
                reader.waitForInput();
                clearTerm();
            },
            .drops => {
                actions.drops();
                reader.waitForInput();
                clearTerm();
            },
            .when => {
                actions.when();
                reader.waitForInput();
                clearTerm();
            },
        }
    }

    printText("exiting\n");
}

/// prints help message
fn printHelp() void {
    const helpStr =
        \\Valid commands are the following. Arguments are requested afterwards.
        \\    help    - Displays this message
        \\    exit    - Exit the calculator
        \\    gif     - What is the probability to receive at least one drop?
        \\    gifn    - What is the probability to receive at least n drops?
        \\    exact   - What is the probability to receive exactly n drops?
        \\    drops   - How many drops can be expected?
        \\    when    - How many kc are required to meet a certain drop probability?
        \\
    ;
    printText(helpStr);
}

/// clears the terminal and prints welcome message
fn clearTerm() void {
    print(@import("util.zig").clearTerminal, .{});
    printText("Welcome to the OSRS drop probability calculator!\n\n");
}

/// a shortcut to printing without extra arguments
fn printText(comptime fmt: []const u8) void {
    print(fmt, .{});
}

/// wrapper around std.io.getStdOut().writer().print() to ignore errors
fn print(comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print(fmt, args) catch {};
}

/// returns a struct used for reading inputs from stdin
pub fn StdinReader(comptime capacity: usize) type {
    return struct {
        const Self = @This();

        buffer: [capacity]u8,

        pub fn new() Self {
            return Self{
                .buffer = undefined,
            };
        }

        /// reads one line from stdin
        /// returns an empty string if user enters too many characters
        pub fn read(self: *Self) ![]u8 {
            const stdin = std.io.getStdIn().reader();
            self.buffer = .{0} ** capacity;
            var bufStream = std.io.fixedBufferStream(&self.buffer);
            stdin.streamUntilDelimiter(bufStream.writer(), '\n', capacity) catch |err| {
                switch (err) {
                    error.StreamTooLong => { // too many characters entered
                        self.clear();
                        return self.buffer[0..0];
                    },
                    else => return err,
                }
            };

            // slice out string from input until
            for (self.buffer, 0..) |char, index| {
                if ((char == '\r') or (char == 0) or (index == capacity - 1)) {
                    return self.buffer[0..index];
                }
            }
            unreachable;
        }

        /// clears stdin
        fn clear(self: *Self) void {
            const stdin = std.io.getStdIn().reader();
            while (true) {
                const readBytes = stdin.read(self.buffer[0..]) catch |err| {
                    std.debug.print("err: {}\n", .{err});
                    return;
                };
                if (readBytes < capacity) return;
            }
        }

        /// reads a line from stdin using read() and interprets it as a Cmd enum
        pub fn readCmd(self: *Self) !?Cmd {
            const input = try self.read();
            const eql = std.mem.eql;
            if (eql(u8, input, "help")) return .help;
            if (eql(u8, input, "exit")) return .exit;
            if (eql(u8, input, "gif")) return .gif;
            if (eql(u8, input, "gifn")) return .gifn;
            if (eql(u8, input, "exact")) return .exact;
            if (eql(u8, input, "drops")) return .drops;
            if (eql(u8, input, "when")) return .when;
            return null;
        }

        /// reads a line from stdin using read() and interprets it as a uint
        pub fn readInt(self: *Self) !uint {
            const input = try self.read();
            return try std.fmt.parseInt(uint, input, 10);
        }

        /// reads a line from stdin using read() and interprets it as a float
        pub fn readFloat(self: *Self) !float {
            const input = try self.read();
            return try std.fmt.parseFloat(float, input);
        }

        /// waits until the user presses Enter
        pub fn waitForInput(self: *Self) void {
            printText("Press Enter to continue\n");
            _ = self.read() catch {};
        }
    };
}

/// namespace for functions prompting the user for input
const prompt = struct {
    ///asks user for kill count
    pub fn kills() uint {
        printText("Enter the kill count: ");
        var input: uint = 0;
        while (true) {
            input = reader.readInt() catch {
                printText("Enter a valid positive integer: ");
                continue;
            };
            return input;
        }
    }

    ///asks user for drop rate demoninator
    pub fn dropRate() float {
        printText("Enter the denominator of the drop probability: ");
        var probDenom: float = undefined;
        while (true) {
            probDenom = reader.readFloat() catch {
                printText("Enter a valid number larger than 1: ");
                continue;
            };

            if (probDenom < 1 or
                std.math.isNan(probDenom) or
                std.math.isInf(probDenom))
            {
                printText("Enter a valid number larger than 1: ");
                continue;
            }

            return probDenom;
        }
    }

    ///asks user for an amount of drops
    pub fn drops() uint {
        printText("Enter the number of drops: ");
        var input: uint = 0;
        while (true) {
            input = reader.readInt() catch {
                printText("Enter a valid positive integer: ");
                continue;
            };
            return input;
        }
    }

    ///asks user for a probability in %
    /// returns value as probability 0<P<=1
    pub fn prob() float {
        printText("Enter a probability of receiving a drop in %: ");
        var input: float = undefined;
        while (true) {
            input = reader.readFloat() catch {
                printText("Enter a valid number between 0 and 100: ");
                continue;
            };

            if (input <= 0 or
                input > 100 or
                std.math.isNan(input) or
                std.math.isInf(input))
            {
                printText("Enter a valid number between 0 and 100: ");
                continue;
            }

            return input / 100;
        }
    }
};

/// namespace for actions to be taken on commands received
const actions = struct {
    /// prompts the user for drop rate and kills
    /// calls math.probSingleDrop and prints the results
    pub fn gif() void {
        clearTerm();
        printText("What is the probability to receive at least one drop?\n");

        const probDenom = prompt.dropRate();

        const param = math.Param{
            .kills = prompt.kills(),
            .prob = 1 / probDenom,
        };

        const result = math.probSingleDrop(param);
        const plural = if (param.kills == 1) "\n" else "s\n";

        const boldStart = @import("util.zig").boldStart;
        const boldEnd = @import("util.zig").boldEnd;

        print(
            "\nThe probability to receive at least one drop given {d} kill{s}" ++
                "and a droprate of 1 in {d} is " ++ boldStart ++ "{d:.2}%" ++
                boldEnd ++ " or " ++ boldStart ++ "1 in {d:.2}" ++ boldEnd ++ ".\n\n",
            .{
                param.kills,
                plural,
                probDenom,
                result * 100,
                1 / result,
            },
        );
    }

    /// prompts the user for drop rate, kills, and drop amount
    /// calls math.probMultiDrop and prints the result
    pub fn gifn() void {
        clearTerm();
        printText("What is the probability to receive at least N drops?\n");

        const probDenom = prompt.dropRate();
        const param = math.Param{
            .kills = prompt.kills(),
            .drops = prompt.drops(),
            .prob = 1 / probDenom,
        };

        const result = math.probMultiDrop(param);
        const pluralDrops = if (param.drops == 1) "" else "s";
        const pluralKills = if (param.kills == 1) "\n" else "s\n";

        const boldStart = @import("util.zig").boldStart;
        const boldEnd = @import("util.zig").boldEnd;

        print(
            "\nThe probability to receive at least {} drop{s} given {d} kill{s}" ++
                "and a droprate of 1 in {d} is " ++ boldStart ++ "{d:.2}%" ++
                boldEnd ++ " or " ++ boldStart ++ "1 in {d:.2}" ++ boldEnd ++ ".\n\n",
            .{
                param.drops,
                pluralDrops,
                param.kills,
                pluralKills,
                probDenom,
                result * 100,
                1 / result,
            },
        );
    }

    /// prompts the user for drop rate, kills, and drop amount
    /// calls math.probExactDrop and prints the result
    pub fn exact() void {
        clearTerm();
        printText("What is the probability to receive exactly N drops?\n");

        const probDenom = prompt.dropRate();
        const param = math.Param{
            .kills = prompt.kills(),
            .drops = prompt.drops(),
            .prob = 1 / probDenom,
        };

        const result = math.probExactDrop(param);
        const pluralDrops = if (param.drops == 1) "" else "s";
        const pluralKills = if (param.kills == 1) "\n" else "s\n";

        const boldStart = @import("util.zig").boldStart;
        const boldEnd = @import("util.zig").boldEnd;

        print(
            "\nThe probability to receive exactly {} drop{s} given {d} kill{s}" ++
                "and a droprate of 1 in {d} is " ++ boldStart ++ "{d:.2}%" ++
                boldEnd ++ " or " ++ boldStart ++ "1 in {d:.2}" ++ boldEnd ++ ".\n\n",
            .{
                param.drops,
                pluralDrops,
                param.kills,
                pluralKills,
                probDenom,
                result * 100,
                1 / result,
            },
        );
    }

    /// prompts the user for drop rate and kills
    /// calls math.probExactDrop multiple times and prints the results
    pub fn drops() void {
        const maxIter = 10000;
        clearTerm();
        printText("How many drops can be expected?\n");

        const probDenom = prompt.dropRate();
        var param = math.Param{
            .kills = prompt.kills(),
            .prob = 1 / probDenom,
        };

        // find where drops start being likely (can be at 0)
        for (0..maxIter) |val| {
            param.drops = val;
            const result = math.probExactDrop(param);
            if (result >= 0.0001) {
                break;
            }
        }

        defer printText("\n");
        if (param.drops == maxIter) {
            printText("Maximum iterations reached, drop is too unlikely or variance too large\n");
            return;
        }
        const boldStart = @import("util.zig").boldStart;
        const boldEnd = @import("util.zig").boldEnd;

        printText("\nThe probability to receive a certain amount of drops is:\n");
        printText("(only drops over 0.01% are shown)\n");
        printText(boldStart ++ "drops\tprob(%)\tprob(1/x)\n" ++ boldEnd);

        // start at point where previous loop stopped
        for (param.drops..maxIter) |val| {
            param.drops = val;
            const result = math.probExactDrop(param);
            if (result < 0.0001) break;
            print("{d}\t{d:.2}\t1/{d:.2}\n", .{ val, result * 100, 1 / result });
        }
    }

    /// prompts user for drop rate and probability
    /// calls math.probSingleDrop to find kills and prints the results
    pub fn when() void {
        const maxIter = 100000;
        clearTerm();
        printText("How many kc are required to meet a certain drop probability?\n");

        const probDenom = prompt.dropRate();
        const probDesired = prompt.prob();
        var param = math.Param{
            .prob = 1 / probDenom,
        };

        const boldStart = @import("util.zig").boldStart;
        const boldEnd = @import("util.zig").boldEnd;
        printText("\nThe amount of kills required to have a given probability to receive\n");
        printText("at least one drop is:\n");
        printText(boldStart ++ "kills\tprob(%)\tprob(1/x)\n" ++ boldEnd);
        defer printText("\n");

        var resultOld: float = 0;
        var result: float = 0;
        for (0..maxIter) |kill| {
            param.kills = kill;
            resultOld = result;
            result = math.probSingleDrop(param);
            if (result >= probDesired) {
                if (kill > 0) {
                    print("{d}\t{d:.2}\t{d:.2}\t(last kill under probability)\n", .{ kill - 1, resultOld * 100, 1 / resultOld });
                }
                print("{d}\t{d:.2}\t{d:.2}\t(first kill over probability)\n", .{ kill, result * 100, 1 / result });
                return;
            }
        }
        printText("Maximum iterations reached, drop is too unlikely\n");
    }
};
