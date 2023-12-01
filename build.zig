const std = @import("std");

pub fn get_input(b: *std.Build, year: u32, day: u32) !void {
    var allocator = std.heap.page_allocator;
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

    var resp = try client.fetch(allocator, .{ .method = .GET, .headers = headers, .location = .{ .uri = uri } });

    try std.fs.cwd().writeFile(b.fmt("src/day{}.txt", .{day}), resp.body.?);
}

pub fn build_day(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode, day: u32) !void {
    const path = b.fmt("src/day{}.zig", .{day});
    std.fs.Dir.access(std.fs.cwd(), path, std.fs.File.OpenFlags{}) catch {
        return;
    };

    std.fs.Dir.access(std.fs.cwd(), b.fmt("src/day{}.txt", .{day}), .{}) catch {
        try get_input(b, 2023, day);
    };

    const run_step = b.step(b.fmt("run{}", .{day}), "Run day");

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = path },
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.step.dependOn(b.getInstallStep());
    run_step.dependOn(&run_unit_tests.step);

    const exe = b.addExecutable(.{
        .name = b.fmt("day{}", .{day}),
        .root_source_file = .{ .path = path },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(&run_unit_tests.step);
    run_step.dependOn(&run_cmd.step);
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var i: u32 = 1;
    while (i <= 25) : (i += 1) {
        build_day(b, target, optimize, i) catch {};
    }
}
