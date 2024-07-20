const std = @import("std");
const dataTypes = @import("dataTypes");
const extra = @import("extra.zig");

pub fn main() !void {
    std.debug.print("im here\n", .{});

    var list = dataTypes.FixedList(u8, 2).new();

    list.push('ö');
    std.debug.print("len = {}\n", .{list.length});
}
