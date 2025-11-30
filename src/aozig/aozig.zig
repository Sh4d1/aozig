/// aozig - A framework for solving Advent of Code puzzles in Zig
const build_impl = @import("aozig_build.zig");
const runtime_impl = @import("runtime.zig");

/// Build configuration options for aozig
pub const Config = build_impl.Config;

/// Build context holding discovered days and build state
pub const Context = build_impl.Context;

/// Represents a single day's source file and metadata
pub const DaySource = build_impl.DaySource;

/// Default build function that sets up automatic day discovery and compilation
pub const defaultBuild = build_impl.defaultBuild;

/// Runtime entry point for executing day solutions
pub const run = runtime_impl.run;

/// Benchmarking harness for measuring solution performance
pub const bench = runtime_impl.bench;

/// Heap analyzer for finding minimum memory requirements
pub const heap = runtime_impl.heap;
