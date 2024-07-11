const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;
const float = f64;
const int = u64;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const Allocator = std.heap.page_allocator;

    //parsing arguments
    const args = try std.process.argsAlloc(Allocator);
    if (args.len < 2) {
        try stdout.print("\nRun with argument \"-h\" to show instructions.\n\n", .{});
        return;
    }

    if (std.mem.eql(u8, args[1], "-h")) {
        try stdout.print("OSRS drop prob calulcator\n" ++
            "help coming soon\n\n", .{});
    }

    // catch med fina prints
    const kills = try std.fmt.parseInt(int, args[1], 10);
    const prob = try std.fmt.parseFloat(float, args[2]);

    try stdout.print("Dropprob to get at least one drop given args[1] kills and args[2] prob: {d:.2}%\n", .{dropProbSingle(kills, prob) * 100});
}

/// nCr(n, k)
fn comb(n: int, k: int) int {
    if (n == 0) return 1;
    if (k == 0) return 1;
    if (n == k) return 1;
    assert(n > k);

    var nom: int = 1;
    var denom: int = 1;
    const start = n - k + 1;
    const end = n + 1; // excluding end

    for (start..end, 1..) |value, index| {
        nom *= value;
        denom *= index;
    }

    //std.debug.print("{}\n", .{nom / denom});
    return nom / denom;
}
test "combinations" {
    try expect(comb(0, 0) == 1);
    try expect(comb(1, 0) == 1);
    try expect(comb(1, 1) == 1);
    try expect(comb(2, 0) == 1);
    try expect(comb(2, 1) == 2);
    try expect(comb(2, 2) == 1);
    try expect(comb(3, 0) == 1);
    try expect(comb(3, 1) == 3);
    try expect(comb(3, 2) == 3);
    try expect(comb(3, 3) == 1);
}

///Returns the probability to recieve exactly "drops" amount of drops
/// from "kills" amount of kills given a drop probability of 1/probDenom
///
/// probDenom must be greater than 1
fn dropProb(kills: int, drops: int, probDenom: float) float {
    if (kills == 0) return 0;
    assert(probDenom > 1);
    const combF: float = @floatFromInt(comb(kills, drops));
    const killsF: float = @floatFromInt(kills);
    const dropsF: float = @floatFromInt(drops);

    // nCr(kills, drops) * 1/probDenom^drops * (1 - 1/probDenom)^(kills - drops)
    return combF / std.math.pow(float, probDenom, dropsF) *
        std.math.pow(float, (1 - 1 / probDenom), killsF - dropsF);
}
fn dropProbTest(n: int, k: int, p: float, result: float) !void {
    const prob = dropProb(n, k, p);
    expect(std.math.approxEqAbs(float, prob, result, 1e-8)) catch |err| {
        std.debug.print("dropProb: {}\n", .{prob});
        return err;
    };
}
test "dropProb test" {
    try dropProbTest(0, 2, 50, 0);
    try dropProbTest(100, 2, 50, 0.27341391157);
    try dropProbTest(20, 4, 5, 0.218199401946);
    try dropProbTest(20000, 4, 5000, 0.195386354263);
    try dropProbTest(20, 0, 5, 0.0115292150461);
}

///returns the probability to receive at least one drop, given "kills"
/// amount of kills and "prob" drop probability denominator
///
/// probDenom must be greater than 1
fn dropProbSingle(kills: int, probDenom: float) float {
    if (kills == 0) return 0;
    assert(probDenom > 1);
    return 1 - dropProb(kills, 0, probDenom);
}
fn dropProbSingleTest(n: int, p: float, result: float) !void {
    try expect(std.math.approxEqAbs(float, dropProbSingle(n, p), result, 1e-8));
}
test "dropProbSingle" {
    try dropProbSingleTest(100, 50, 0.867380444105);
    try dropProbSingleTest(1000, 423, 0.906225752753);
    try dropProbSingleTest(0, 423, 0);
}

//fn dropProbMulti
