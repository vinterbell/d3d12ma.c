const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zwindows_dep = b.dependency("zwindows", .{});

    const d3d12ma = b.addLibrary(.{
        .name = "d3d12ma",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .sanitize_c = .off,
            .link_libc = true,
        }),
    });
    d3d12ma.root_module.addCSourceFile(.{
        .file = b.path("code/d3d12ma/build.cpp"),
        .language = .cpp,
        .flags = &.{
            "-std=c++17",
            "-fno-sanitize=undefined",
            // does this == NULL for some reason?
            "-Wno-tautological-undefined-compare",
            // code handles all cases except for TYPE_COUNT, should fix but oh well...
            "-Wno-switch",
        },
    });
    d3d12ma.addIncludePath(b.path("code/d3d12ma"));
    // d3d12ma.addIncludePath(b.path("code/third_party/d3d12/"));
    d3d12ma.installHeader(b.path("code/d3d12ma/d3d12ma.h"), "d3d12ma.h");
    b.installArtifact(d3d12ma);

    if (target.result.abi != .msvc) {
        d3d12ma.root_module.link_libcpp = true;
    }

    const zd3d12ma = b.addModule("d3d12ma", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zwindows", .module = zwindows_dep.module("zwindows") },
        },
    });
    zd3d12ma.linkLibrary(d3d12ma);
}
