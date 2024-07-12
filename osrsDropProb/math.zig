const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;
const float = @import("util.zig").float;
const uint = @import("util.zig").uint;

pub const Param = struct {
    kills: uint = 0,
    drops: uint = 0,
    prob: float = 0,
};

/// n choose k: amount of unordered combinations of k elements from a set of n
fn nCk(n: uint, k: uint) float {
    if (n == 0) return 1; //top of Pascals triangle
    if (k == 0) return 1; //left edge of Pascals triangle
    if (n == k) return 1; //right edge of Pascals triangle
    assert(k < n); // k <= n is a strict definition of nCk

    var num: float = 1;
    var denom: float = 1;
    for (0..k, 1..) |numIter, denomIter| {
        num *= @floatFromInt((n - numIter));
        denom *= @floatFromInt((denomIter));
    }
    return @round(num / denom);
}
test "combinations" {
    const pascalsPyramid: [5][5]float = .{
        .{ 1, 0, 0, 0, 0 },
        .{ 1, 1, 0, 0, 0 },
        .{ 1, 2, 1, 0, 0 },
        .{ 1, 3, 3, 1, 0 },
        .{ 1, 4, 6, 4, 1 },
    };
    var res: float = undefined;
    outer: for (pascalsPyramid, 0..) |row, n| {
        for (row, 0..) |val, k| {
            if (n < k) {
                continue :outer;
            }
            res = nCk(n, k);
            expect(res == val) catch |err| {
                std.debug.print("nCk({}, {})\nExpected: {}\nReturned {}\n", .{ n, k, val, res });
                return err;
            };
        }
    }

    try expect(nCk(40, 20) == 137846528820);
    //overflow checks
    _ = nCk(100, 50);
    _ = nCk(1000, 500);
}

///Returns the probability to recieve exactly "drops" amount of drops
/// from "kills" amount of kills given a drop probability of "prob"
pub fn probExactDrop(param: Param) float {
    if (param.kills == 0) return 0; //cant get drops without kills
    if (param.kills < param.drops) return 0; //cant get more drops than kills
    assert(param.prob <= 1);

    const combF: float = nCk(param.kills, param.drops);
    const killsF: float = @floatFromInt(param.kills);
    const dropsF: float = @floatFromInt(param.drops);

    // nCk(kills, drops) * prob^drops * (1 - prob)^(kills - drops)
    return combF * std.math.pow(float, param.prob, dropsF) *
        std.math.pow(float, (1 - param.prob), killsF - dropsF);
}
fn probExactDropTest(param: Param, expected: float) !void {
    const prob = probExactDrop(param);
    expect(std.math.approxEqAbs(float, prob, expected, 1e-8)) catch |err| {
        std.debug.print("probExactDrop: {}\n", .{prob});
        return err;
    };
}
test "probExactDrop test" {
    try probExactDropTest(.{ .kills = 42, .drops = 1337, .prob = 1 }, 0);
    try probExactDropTest(.{ .kills = 42, .drops = 42, .prob = 1 }, 1);
    try probExactDropTest(.{ .kills = 42, .drops = 2, .prob = 1 }, 0);
    try probExactDropTest(.{ .kills = 0, .drops = 2, .prob = 1.0 / 50.0 }, 0);
    try probExactDropTest(.{ .kills = 100, .drops = 2, .prob = 1.0 / 50.0 }, 0.27341391157);
    try probExactDropTest(.{ .kills = 20, .drops = 4, .prob = 1.0 / 5.0 }, 0.218199401946);
    try probExactDropTest(.{ .kills = 20000, .drops = 4, .prob = 1.0 / 5000.0 }, 0.195386354263);
    try probExactDropTest(.{ .kills = 20, .drops = 0, .prob = 1.0 / 5.0 }, 0.0115292150461);
    try probExactDropTest(.{ .kills = 100, .drops = 50, .prob = 1.0 / 2.0 }, 0.0795892373872);
}

///Returns the probability to receive at least one drop
/// from "kills" amount of kills given a drop probability of "prob"
pub fn probSingleDrop(param: Param) float {
    if (param.kills == 0) return 0; //cant get drops without kills
    if (param.prob >= 1) return 1; //guaranteed drop
    return 1 - probExactDrop(param);
}
fn probSingleDropTest(param: Param, expected: float) !void {
    const prob = probSingleDrop(param);
    expect(std.math.approxEqAbs(float, prob, expected, 1e-8)) catch |err| {
        std.debug.print("probSingleDrop: {}\n", .{prob});
        return err;
    };
}
test "probSingleDrop" {
    try probSingleDropTest(.{ .kills = 100, .prob = 1.0 / 50.0 }, 0.867380444105);
    try probSingleDropTest(.{ .kills = 1000, .prob = 1.0 / 423.0 }, 0.906225752753);
    try probSingleDropTest(.{ .kills = 0, .prob = 1 / 423 }, 0);
    try probSingleDropTest(.{ .kills = 0, .prob = 1 }, 0);
    try probSingleDropTest(.{ .kills = 42, .prob = 1 }, 1);
}

///Returns the probability to receive at least "drops" amount of drops
/// from "kills" amount of kills given a drop probability of "prob"
pub fn probMultiDrop(param: Param) float {
    if (param.kills == 0) return 0; //cant get drops without kills
    assert(param.prob <= 1);

    var q: float = 0;
    var paramExact = param;
    for (0..param.drops) |value| {
        paramExact.drops = value;
        q += probExactDrop(paramExact);
    }
    return 1 - q;
}
fn probMultiDropTest(param: Param, expected: float) !void {
    const prob = probMultiDrop(param);
    expect(std.math.approxEqAbs(float, prob, expected, 1e-8)) catch |err| {
        std.debug.print("probMultiDrop: {}\n", .{prob});
        return err;
    };
}
test "probMultiDrop" {
    try probMultiDropTest(.{ .kills = 100, .drops = 2, .prob = 1.0 / 50.0 }, 0.596728289218);
    try probMultiDropTest(.{ .kills = 3000, .drops = 2, .prob = 1.0 / 3000.0 }, 0.26424111425);
    try probMultiDropTest(.{ .kills = 0, .drops = 2, .prob = 1.0 / 3000.0 }, 0);
    try probMultiDropTest(.{ .kills = 42, .drops = 0, .prob = 1.0 / 1337.0 }, 1);
    try probMultiDropTest(.{ .kills = 3, .drops = 4, .prob = 1 }, 0);
    try probMultiDropTest(.{ .kills = 4, .drops = 4, .prob = 1 }, 1);
    try probMultiDropTest(.{ .kills = 4, .drops = 2, .prob = 1 }, 1);
}
