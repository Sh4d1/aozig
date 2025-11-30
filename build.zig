const std = @import("std");
const aozig = @import("src/aozig/aozig.zig");
const DEFAULT_YEAR: usize = 2025;

pub const defaultBuild = aozig.defaultBuild;

pub fn build(b: *std.Build) !void {
    _ = b.addModule("aozig", .{
        .root_source_file = b.path("src/aozig/aozig.zig"),
    });

    try aozig.defaultBuild(b, .{
        .default_year = DEFAULT_YEAR,
    });
}
