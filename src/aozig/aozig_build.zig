const std = @import("std");

/// Configuration for aozig build system
pub const Config = struct {
    default_year: usize,
    src_root: []const u8 = "src",
    binary_name: []const u8 = "main",
    runtime_dependency: ?*std.Build.Dependency = null,
    runtime_module: ?*std.Build.Module = null,
};

/// Metadata for a single day's source file and inputs
pub const DaySource = struct {
    day: usize,
    zig_path: []const u8,
    input_path: []const u8,
    input_abs: []const u8,
    module_name: []const u8,
    module: ?*std.Build.Module = null,
};

/// Build context managing day discovery, input fetching, and module wiring
pub const Context = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    config: Config,
    year: usize,
    day: ?usize,
    day_sources: std.array_list.Aligned(DaySource, null),
    fail_msg: ?[]const u8 = null,
    generated_module: ?*std.Build.Module = null,
    main_source: ?std.Build.LazyPath = null,

    /// Initialize build context and discover day solutions
    pub fn init(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, config: Config) !Context {
        var ctx = Context{
            .b = b,
            .target = target,
            .optimize = optimize,
            .config = config,
            .year = b.option(usize, "year", "Year to target") orelse config.default_year,
            .day = b.option(usize, "day", "Day to target"),
            .day_sources = .empty,
        };
        try ctx.discoverDays();
        return ctx;
    }

    /// Clean up allocated resources
    pub fn deinit(ctx: *Context) void {
        ctx.day_sources.deinit(ctx.b.allocator);
    }

    /// Scan filesystem for dayN.zig files and collect metadata
    fn discoverDays(ctx: *Context) !void {
        const base_dir = ctx.b.fmt("{s}/{}/", .{ ctx.config.src_root, ctx.year });
        var dir = std.fs.cwd().openDir(base_dir, .{ .iterate = true }) catch |err| switch (err) {
            error.FileNotFound => {
                ctx.fail_msg = ctx.b.fmt("No Advent of Code solutions found for year {d}. Pass -Dyear=<available year>.", .{ctx.year});
                return;
            },
            else => return err,
        };
        defer dir.close();

        var it = dir.iterate();
        while (try it.next()) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;
            if (!std.mem.startsWith(u8, entry.name, "day")) continue;

            const number_slice = entry.name[3 .. entry.name.len - 4];
            const parsed_day = std.fmt.parseInt(usize, number_slice, 10) catch continue;
            const zig_path = ctx.b.fmt("{s}{s}", .{ base_dir, entry.name });
            const input_path = ctx.b.fmt("{s}day{}.txt", .{ base_dir, parsed_day });
            const input_abs = try ctx.b.build_root.join(ctx.b.allocator, &.{input_path});
            const module_name = ctx.b.fmt("day{}", .{parsed_day});

            try ctx.day_sources.append(ctx.b.allocator, .{
                .day = parsed_day,
                .zig_path = zig_path,
                .input_path = input_path,
                .input_abs = input_abs,
                .module_name = module_name,
            });
        }

        std.mem.sort(DaySource, ctx.day_sources.items, {}, struct {
            fn lessThan(_: void, lhs: DaySource, rhs: DaySource) bool {
                return lhs.day < rhs.day;
            }
        }.lessThan);

        if (ctx.day) |requested| {
            var selected: usize = 0;
            for (ctx.day_sources.items) |source| {
                if (source.day != requested) continue;
                ctx.day_sources.items[selected] = source;
                selected += 1;
            }
            ctx.day_sources.items.len = selected;
            if (selected == 0) return error.DayNotExists;
        } else if (ctx.day_sources.items.len == 0 and ctx.fail_msg == null) {
            ctx.fail_msg = ctx.b.fmt("No Advent of Code solutions found for year {d}. Pass -Dyear=<available year>.", .{ctx.year});
        }
    }

    /// Check if any valid days were discovered
    pub fn hasDays(ctx: *Context) bool {
        return ctx.fail_msg == null;
    }

    /// Add failure step when no days found for requested year
    pub fn addMissingYearFail(ctx: *Context, step: *std.Build.Step) void {
        if (ctx.fail_msg) |msg| {
            const fail = ctx.b.addFail(msg);
            step.dependOn(&fail.step);
        }
    }

    /// Queue steps to download missing inputs via the fetcher executable
    pub fn ensureInputs(
        ctx: *Context,
        fetch_exe: *std.Build.Step.Compile,
        run_step: *std.Build.Step,
        test_step: *std.Build.Step,
        install_step: *std.Build.Step,
        run_artifact_step: *std.Build.Step,
    ) void {
        for (ctx.day_sources.items) |source| {
            std.fs.Dir.access(std.fs.cwd(), source.input_path, .{}) catch {
                const fetch_cmd = ctx.b.addRunArtifact(fetch_exe);
                fetch_cmd.addArgs(&.{
                    ctx.b.fmt("{}", .{ctx.year}),
                    ctx.b.fmt("{}", .{source.day}),
                    source.input_abs,
                });
                run_step.dependOn(&fetch_cmd.step);
                test_step.dependOn(&fetch_cmd.step);
                install_step.dependOn(&fetch_cmd.step);
                run_artifact_step.dependOn(&fetch_cmd.step);
            };
        }
    }

    /// Generate days_generated.zig and wire up all day modules
    pub fn installDayModules(ctx: *Context, root_module: *std.Build.Module, runtime_module: *std.Build.Module, generated_import: []const u8) !*std.Build.Module {
        if (ctx.generated_module) |gm| {
            root_module.addImport(generated_import, gm);
            return gm;
        }

        var generated_contents: std.array_list.Aligned(u8, null) = .empty;
        defer generated_contents.deinit(ctx.b.allocator);
        var gen_writer = generated_contents.writer(ctx.b.allocator);
        try gen_writer.writeAll(
            \\pub const Day = struct {
            \\    day: usize,
            \\    input_path: []const u8,
            \\    module: type,
            \\};
            \\pub const days = [_]Day{
            \\
        );
        for (ctx.day_sources.items) |source| {
            try gen_writer.print(
                "    .{{ .day = {d}, .input_path = \"{s}\", .module = @import(\"{s}\") }},\n",
                .{ source.day, source.input_abs, source.module_name },
            );
        }
        try gen_writer.writeAll(
            \\};
            \\
        );
        const generated_source = try generated_contents.toOwnedSlice(ctx.b.allocator);
        defer ctx.b.allocator.free(generated_source);
        const write_files = ctx.b.addWriteFiles();
        const generated_lazy_path = write_files.add("days_generated.zig", generated_source);
        const days_module = ctx.b.createModule(.{
            .root_source_file = generated_lazy_path,
        });
        ctx.generated_module = days_module;
        root_module.addImport(generated_import, days_module);

        for (ctx.day_sources.items) |*source| {
            const module = ctx.b.createModule(.{ .root_source_file = ctx.b.path(source.zig_path) });
            module.addImport("aozig", runtime_module);
            source.module = module;
            root_module.addImport(source.module_name, module);
            days_module.addImport(source.module_name, module);
        }

        return days_module;
    }

    /// Add appropriate command-line arguments to run step
    pub fn addRunArgs(ctx: *Context, run_cmd: *std.Build.Step.Run) void {
        if (ctx.b.args) |args| {
            run_cmd.addArgs(args);
        } else if (ctx.day) |requested| {
            run_cmd.addArg(ctx.b.fmt("{}", .{requested}));
        }
    }

    /// Register test steps for all discovered days
    pub fn addDayTests(ctx: *Context, step: *std.Build.Step, runtime_module: *std.Build.Module) void {
        for (ctx.day_sources.items) |source| {
            testDay(ctx, source, step, runtime_module) catch {};
        }
    }

    /// Generate main.zig that calls aozig.run() with discovered days
    pub fn generatedMain(ctx: *Context) std.Build.LazyPath {
        if (ctx.main_source) |lp| return lp;
        const wf = ctx.b.addWriteFiles();
        const lp = wf.add("aozig_main.zig",
            \\const aozig = @import("aozig");
            \\const days = @import("days_generated").days;
            \\
            \\pub fn main() !void {
            \\    return aozig.run(days);
            \\}
            \\
        );
        ctx.main_source = lp;
        return lp;
    }
};

/// Template for a new day solution
const day_template =
    \\const std = @import("std");
    \\const aozig = @import("aozig");
    \\
    \\pub var alloc: std.mem.Allocator = undefined;
    \\
    \\pub fn parse(input: []const u8) !void {{
    \\    _ = input;
    \\    // TODO: Parse input
    \\}}
    \\
    \\pub fn solve1(_: void) usize {{
    \\    // TODO: Solve part 1
    \\    return 0;
    \\}}
    \\
    \\pub fn solve2(_: void) usize {{
    \\    // TODO: Solve part 2
    \\    return 0;
    \\}}
    \\
    \\test "example" {{
    \\    const input =
    \\        \\
    \\    ;
    \\    _ = try parse(input);
    \\    try std.testing.expectEqual(@as(usize, 0), solve1({{}}));
    \\    try std.testing.expectEqual(@as(usize, 0), solve2({{}}));
    \\}}
    \\
;

/// Default build entry point with automatic day discovery and input fetching
pub fn defaultBuild(b: *std.Build, config: Config) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Check for 'new' command to generate a template
    if (b.option(usize, "new", "Create a new day from template (e.g., -Dnew=5)")) |day_num| {
        const year = b.option(usize, "year", "Year to target") orelse config.default_year;
        try generateDayTemplate(b, config.src_root, year, day_num);
        return;
    }

    var ctx = try Context.init(b, target, optimize, config);
    defer ctx.deinit();

    const runtime_module: *std.Build.Module = blk: {
        if (config.runtime_module) |m| break :blk m;
        if (config.runtime_dependency) |dep| break :blk dep.module("aozig");
        break :blk b.createModule(.{ .root_source_file = b.path("src/aozig/aozig.zig") });
    };
    const fetch_source = blk: {
        if (config.runtime_dependency) |dep| break :blk dep.path("src/aozig/fetch_inputs.zig");
        break :blk b.path("src/aozig/fetch_inputs.zig");
    };
    const fetch_inputs_exe = b.addExecutable(.{
        .name = "aozig_fetch_inputs",
        .root_module = b.createModule(.{
            .root_source_file = fetch_source,
            .target = target,
            .optimize = optimize,
        }),
    });

    const root_module = b.createModule(.{
        .root_source_file = ctx.generatedMain(),
        .target = target,
        .optimize = optimize,
    });
    root_module.addImport("aozig", runtime_module);

    const exe = b.addExecutable(.{
        .name = config.binary_name,
        .root_module = root_module,
    });

    const run_step = b.step("run", "Run");
    const test_step = b.step("test", "Test");
    const install_step = b.getInstallStep();

    if (!ctx.hasDays()) {
        ctx.addMissingYearFail(run_step);
        ctx.addMissingYearFail(test_step);
        ctx.addMissingYearFail(install_step);
        return;
    }

    const run_cmd = b.addRunArtifact(exe);
    ctx.addRunArgs(run_cmd);

    b.installArtifact(exe);
    ctx.ensureInputs(fetch_inputs_exe, run_step, test_step, install_step, &run_cmd.step);
    _ = try ctx.installDayModules(root_module, runtime_module, "days_generated");

    run_step.dependOn(&run_cmd.step);

    ctx.addDayTests(test_step, runtime_module);
}

/// Generate a new day file from template
fn generateDayTemplate(b: *std.Build, src_root: []const u8, year: usize, day: usize) !void {
    const year_dir = b.fmt("{s}/{}/", .{ src_root, year });
    const day_file = b.fmt("{s}day{}.zig", .{ year_dir, day });

    // Create year directory if it doesn't exist
    std.fs.cwd().makePath(year_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    // Check if file already exists
    std.fs.cwd().access(day_file, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            // File doesn't exist, create it
            const file = try std.fs.cwd().createFile(day_file, .{});
            defer file.close();
            try file.writeAll(day_template);
            std.log.info("Created {s}", .{day_file});
            std.log.info("", .{});
            std.log.info("Next steps:", .{});
            std.log.info("  1. Edit {s} and implement your solution", .{day_file});
            std.log.info("  2. Run with: zig build run -Dday={}", .{day});
            std.log.info("  3. Test with: zig build test -Dday={}", .{day});
            std.log.info("  4. Benchmark with: zig build run -- bench", .{});
            return;
        },
        else => return err,
    };

    std.log.err("File {s} already exists. Not overwriting.", .{day_file});
    return error.FileExists;
}

fn testDay(ctx: *Context, source: DaySource, step: *std.Build.Step, runtime_module: *std.Build.Module) !void {
    std.fs.Dir.access(std.fs.cwd(), source.zig_path, .{}) catch {
        return;
    };
    const test_module = ctx.b.createModule(.{
        .optimize = ctx.optimize,
        .target = ctx.target,
        .root_source_file = ctx.b.path(source.zig_path),
    });
    test_module.addImport("aozig", runtime_module);

    const unit_tests = ctx.b.addTest(.{
        .root_module = test_module,
    });
    const run_unit_tests = ctx.b.addRunArtifact(unit_tests);
    run_unit_tests.step.dependOn(ctx.b.getInstallStep());
    step.dependOn(&run_unit_tests.step);
}
