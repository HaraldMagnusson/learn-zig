const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "osrsDropProbCalculator",
        .root_source_file = b.path("osrsDropProb.zig"),
        .target = b.host,
        .optimize = .ReleaseSafe,
    });

    b.installArtifact(exe);

    const testStep = b.step("test", "Run unit tests");
    const unitTests = b.addTest(.{
        .root_source_file = b.path("osrsDropProb.zig"),
        .target = b.host,
        .optimize = .ReleaseSafe,
    });
    const runUnitTests = b.addRunArtifact(unitTests);
    testStep.dependOn(&runUnitTests.step);
}
