const std = @import("std");
const math = std.math;

/// A fixed-size list that stores its contents directly in the struct.
/// This is useful for small lists where heap allocation is not desired.
///
/// # Example use
///
/// ```
/// var list = FixedList(u32, 4).new();
/// list.push(1);
/// list.push(2);
/// var value1 = list.get(0); // 1
/// var value2 = list.pop(); // 2
/// ```
pub fn FixedList(comptime T: type, comptime capacity: usize) type {
    const length_bit_count = @bitSizeOf(usize) - @clz(capacity);
    const lengthType = std.meta.Int(std.builtin.Signedness.unsigned, length_bit_count);
    return struct {
        const Self = @This();

        array: [capacity]T,
        length: lengthType,

        pub fn new() Self {
            return Self{
                .array = undefined,
                .length = 0,
            };
        }

        pub fn try_push(self: *Self, value: T) !void {
            if (self.length >= capacity) {
                return error.OutOfSpace;
            }
            self.array[self.length] = value;
            self.length += 1;
        }
        pub fn push(self: *Self, value: T) void {
            self.try_push(value) catch @panic("Attempt to push into full list");
        }

        pub fn try_pop(self: *Self) !T {
            if (self.length == 0) {
                return error.OutOfBounds;
            }
            self.length -= 1;
            return self.array[self.length];
        }
        pub fn pop(self: *Self) T {
            return self.try_pop() catch @panic("Attempt to pop empty list");
        }

        pub fn try_get(self: *Self, index: usize) !T {
            if (index >= self.length) {
                return error.OutOfBounds;
            }
            return self.array[index];
        }
        pub fn get(self: *Self, index: usize) T {
            return self.try_get(index) catch @panic("index out of bounds");
        }
    };
}

const expect = std.testing.expect;
const expectError = std.testing.expectError;

test "sample use" {
    var list = FixedList(u32, 4).new();

    list.push(1);
    list.push(2);
    list.push(3);
    list.push(4);
    try expectError(error.OutOfSpace, list.try_push(5));

    try expect(list.get(0) == 1);
    try expect(list.get(1) == 2);
    try expect(list.get(2) == 3);
    try expect(list.get(3) == 4);
    try expectError(error.OutOfBounds, list.try_get(5));

    try expect(list.pop() == 4);
    try expect(list.pop() == 3);
    try expect(list.pop() == 2);
    try expect(list.pop() == 1);
    try expectError(error.OutOfBounds, list.try_pop());
}

fn test_size_align(comptime T: type, comptime size: usize, comptime alig: usize) !void {
    try expect(@sizeOf(T) == size);
    try expect(@alignOf(T) == alig);
}
test "size and align" {
    try test_size_align(FixedList(u8, 7), 8, 1); // [array 7][length 1 (u8)]
    try test_size_align(FixedList(u8, 8), 9, 1); // [array 8][length 1 (u8)]
    try test_size_align(FixedList(u16, 3), 8, 2); // [array 6][length 1 (u8)][padding 1]
    try test_size_align(FixedList(u16, 4), 10, 2); // [array 8][length 1 (u8)][padding 1]
    try test_size_align(FixedList(u8, 255), 256, 1); // [array 255][length 1 (u8)]
    try test_size_align(FixedList(u8, 256), 258, 2); // [array 256][length 2 (u9)]
    try test_size_align(FixedList(u8, 65535), 65538, 2); // [array 65535][padding 1][length 2 (u16)]
    try test_size_align(FixedList(u8, 65536), 65540, 4); // [array 65536][length 4 (u17)]
}
