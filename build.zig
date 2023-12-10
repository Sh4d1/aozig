const std = @import("std");

pub fn get_input(b: *std.Build, year: usize, day: usize) !void {
    const allocator = std.heap.page_allocator;
    var client = std.http.Client{
        .allocator = allocator,
    };
    const uri = std.Uri.parse(b.fmt("https://adventofcode.com/{}/day/{}/input", .{ year, day })) catch unreachable;

    var file = try std.fs.cwd().openFile(".token", .{});
    defer file.close();

    const token = try file.reader().readAllAlloc(allocator, 200);

    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("cookie", b.fmt("session={s}", .{token}));

    const resp = try client.fetch(allocator, .{ .method = .GET, .headers = headers, .location = .{ .uri = uri } });

    try std.fs.cwd().writeFile(b.fmt("src/day{}.txt", .{day}), resp.body.?);
}

pub fn test_day(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode, day: usize, step: *std.build.Step) !void {
    if (day == 0) {
        return;
    }
    const utils_module = b.createModule(.{ .source_file = .{ .path = "utils/utils.zig" } });
    const path = b.fmt("src/day{}.zig", .{day});
    std.fs.Dir.access(std.fs.cwd(), path, std.fs.File.OpenFlags{}) catch {
        return;
    };

    std.fs.Dir.access(std.fs.cwd(), b.fmt("src/day{}.txt", .{day}), .{}) catch {
        try get_input(b, 2023, day);
    };

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = path },
        .target = target,
        .optimize = optimize,
    });
    unit_tests.addModule("utils", utils_module);
    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.step.dependOn(b.getInstallStep());
    step.dependOn(&run_unit_tests.step);
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const utils_module = b.createModule(.{ .source_file = .{ .path = "utils/utils.zig" } });

    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = .{ .path = "main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();

    for (1..25) |i| {
        std.fs.Dir.access(std.fs.cwd(), b.fmt("src/day{}.zig", .{i}), .{}) catch {
            continue;
        };
        std.fs.Dir.access(std.fs.cwd(), b.fmt("src/day{}.txt", .{i}), .{}) catch {
            try get_input(b, 2023, @intCast(i));
        };
        exe.addModule(b.fmt("day{}", .{i}), b.createModule(.{ .dependencies = &[_]std.build.ModuleDependency{.{ .name = "utils", .module = utils_module }}, .source_file = .{ .path = b.fmt("src/day{}.zig", .{i}) } }));
    }

    const run_step = b.step("run", "Run");
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    if (b.args) |args| {
        const d = std.fmt.parseInt(usize, args[0], 10) catch 0;
        test_day(b, target, optimize, d, &run_cmd.step) catch {};
    } else {
        for (1..25) |i| {
            test_day(b, target, optimize, i, &run_cmd.step) catch {};
        }
    }
    run_step.dependOn(&run_cmd.step);
}
