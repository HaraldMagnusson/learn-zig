const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "files",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
        .optimize = .Debug,
    });

    const dataTypes = b.addModule("dataTypes", .{
        .root_source_file = b.path("../dataTypes/dataTypes.zig"),
    });
    exe.root_module.addImport("dataTypes", dataTypes);
    b.installArtifact(exe);
}
