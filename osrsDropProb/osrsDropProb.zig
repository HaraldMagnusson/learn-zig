const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;
const float = @import("util.zig").float;
const uint = @import("util.zig").uint;
const math = @import("math.zig");

//const print = @import("util.zig").print;
pub fn print(comptime fmt: []const u8, args: anytype) void {
    const stdout = @import("std").io.getStdOut().writer();
    stdout.print(fmt, args) catch {};
}

pub fn main() !void {
    const Allocator = std.heap.page_allocator;

    print("\n", .{});
    defer print("\n", .{});

    //parsing arguments
    const args = try std.process.argsAlloc(Allocator);
    if (args.len < 2) {
        print("Run with argument \"-h\" to show instructions.\n", .{});
        return;
    }

    if (std.mem.eql(u8, args[1], "-h")) {
        print("OSRS drop prob calulcator\n" ++
            "help coming soon\n", .{});
        return;
    }

    if (args.len < 3) {
        print("Current features require 2 arguments.\n", .{});
        return;
    }

    const kills = std.fmt.parseInt(uint, args[1], 10) catch {
        print("First argument must be an integer, the amount of kc.\n", .{});
        return;
    };
    const probDenum = std.fmt.parseFloat(float, args[2]) catch {
        print("Second argument must be a float, the denominator of the items drop probability.\n", .{});
        return;
    };

    const param: math.Param = .{ .kills = kills, .prob = 1 / probDenum };
    const atLeastOne = math.probSingleDrop(param);
    print("Dropprob to get at least one drop given args[1] kills and 1/args[2] prob: {d:.2}% or 1 in {d:.2}\n", .{ atLeastOne * 100, 1 / atLeastOne });
}
