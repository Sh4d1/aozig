const std = @import("std");
const DEFAULT_YEAR: usize = 2025;

const DaySource = struct {
    day: usize,
    zig_path: []const u8,
    input_path: []const u8,
};

pub fn get_input(b: *std.Build, year: usize, day: usize, path: []const u8) !void {
    const allocator = std.heap.page_allocator;
    var client = std.http.Client{
        .allocator = allocator,
    };
    const uri = std.Uri.parse(b.fmt("https://adventofcode.com/{}/day/{}/input", .{ year, day })) catch unreachable;

    var buffer: [128]u8 = undefined;
    const token = try std.fs.cwd().readFile(".token", &buffer);

    const cookie_header = std.http.Header{ .name = "cookie", .value = b.fmt("session={s}", .{token}) };

    const input_file = try std.fs.cwd().createFile(path, .{});
    defer input_file.close();
    var file_writer = input_file.writer(&.{});

    const resp = try client.fetch(.{
        .method = .GET,
        .extra_headers = &[_]std.http.Header{cookie_header},
        .location = .{ .uri = uri },
        .response_writer = &file_writer.interface,
    });
    if (resp.status.class() != .success) {
        return error.HTTPError;
    }
}

pub fn test_day(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, source: DaySource, step: *std.Build.Step) !void {
    std.fs.Dir.access(std.fs.cwd(), source.zig_path, .{}) catch {
        return;
    };
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{ .optimize = optimize, .target = target, .root_source_file = b.path(source.zig_path) }),
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.step.dependOn(b.getInstallStep());
    step.dependOn(&run_unit_tests.step);
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const year = b.option(usize, "year", "Year to target") orelse DEFAULT_YEAR;
    const day = b.option(usize, "day", "Day to target");

    var day_sources: std.array_list.Aligned(DaySource, null) = .empty;
    defer day_sources.deinit(b.allocator);

    const base_dir = b.fmt("src/{}/", .{year});
    var day_dir = std.fs.cwd().openDir(base_dir, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => {
            return error.YearNotFound;
        },
        else => return err,
    };
    defer day_dir.close();

    var it = day_dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;
        if (entry.name.len <= 4) continue;
        if (!std.mem.startsWith(u8, entry.name, "day")) continue;

        const number_slice = entry.name[3 .. entry.name.len - 4];
        const parsed_day = std.fmt.parseInt(usize, number_slice, 10) catch continue;
        const zig_path = b.fmt("{s}{s}", .{ base_dir, entry.name });
        const input_path = b.fmt("{s}day{}.txt", .{ base_dir, parsed_day });

        try day_sources.append(b.allocator, .{
            .day = parsed_day,
            .zig_path = zig_path,
            .input_path = input_path,
        });
    }

    std.mem.sort(DaySource, day_sources.items, {}, struct {
        fn lessThan(_: void, lhs: DaySource, rhs: DaySource) bool {
            return lhs.day < rhs.day;
        }
    }.lessThan);

    if (day) |requested| {
        var selected_len: usize = 0;
        for (day_sources.items) |source| {
            if (source.day != requested) continue;
            day_sources.items[selected_len] = source;
            selected_len += 1;
        }
        day_sources.items.len = selected_len;
        if (selected_len == 0) return error.DayNotExists;
    } else if (day_sources.items.len == 0) {
        return error.DayNotExists;
    }

    for (day_sources.items) |source| {
        std.fs.Dir.access(std.fs.cwd(), source.input_path, .{}) catch {
            try get_input(b, year, source.day, source.input_path);
        };
    }

    const root_module = b.createModule(.{ .root_source_file = b.path("main.zig"), .target = target, .optimize = optimize });

    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = root_module,
    });

    var generated_contents: std.array_list.Aligned(u8, null) = .empty;
    defer generated_contents.deinit(b.allocator);
    var gen_writer = generated_contents.writer(b.allocator);
    try gen_writer.writeAll(
        \\pub const Day = struct {
        \\    day: usize,
        \\    input_path: []const u8,
        \\    module: type,
        \\};
        \\pub const days = [_]Day{
        \\
    );
    for (day_sources.items) |source| {
        try gen_writer.print(
            "    .{{ .day = {d}, .input_path = \"{s}\", .module = @import(\"day{d}\") }},\n",
            .{ source.day, source.input_path, source.day },
        );
    }
    try gen_writer.writeAll(
        \\};
        \\
    );
    const generated_source = try generated_contents.toOwnedSlice(b.allocator);
    defer b.allocator.free(generated_source);
    const write_files = b.addWriteFiles();
    const generated_lazy_path = write_files.add("days_generated.zig", generated_source);
    const days_module = b.createModule(.{
        .root_source_file = generated_lazy_path,
    });
    root_module.addImport("days_generated", days_module);

    for (day_sources.items) |source| {
        const module_name = b.fmt("day{}", .{source.day});
        const module = b.createModule(.{ .root_source_file = b.path(source.zig_path) });
        root_module.addImport(module_name, module);
        days_module.addImport(module_name, module);
    }

    const run_step = b.step("run", "Run");
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    } else if (day) |requested| {
        run_cmd.addArg(b.fmt("{}", .{requested}));
    }

    const test_step = b.step("test", "Test");
    for (day_sources.items) |source| {
        test_day(b, target, optimize, source, test_step) catch {};
    }
    run_step.dependOn(&run_cmd.step);
}
