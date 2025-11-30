# aozig

`aozig` is an Advent of Code wrapper for Zig projects. 

This repository also includes 2023 & 2025 examples (`src/2023`, `src/2025`) so you can see a complete setup in action.

## How puzzles should look

Each puzzle module lives at `src/<year>/dayN.zig` next to its input `dayN.txt`. The runtime expects the following interface:

- `pub fn parse(data: []const u8) !T` – mandatory parser for part 1 (and part 2 if you don’t define `parse2`).
- `pub fn solve1(parsed: T) U` – part 1 solver.
- `pub fn solve2(parsed_or_other: anytype) U` – part 2 solver. If you define `parse2`, the runtime feeds its result into `solve2`; otherwise it reuses the value returned by `parse`.
- `pub fn parse2(data: []const u8) !T2` – optional specialised parser solely for part 2.
- Optional `pub var alloc: std.mem.Allocator = ...;` – if present the runtime assigns the day-specific allocator before calling any parse/solve function.

## CLI commands

`zig build run [-- <args>]`: Executes every discovered day (or just the selected one; see build flags below). Inside the executable you can also pass:
  - `bench [runs]` – measures parse/solve timings. Default `runs=10`.
  - `heap` – estimates the memory required
  - `<number>` – run a single day directly, bypassing `-Dday`.

`zig build test`: Runs unit tests for every selected day module. Each `dayN.zig` can contain `test "name" { … }` blocks as usual.

### Build flags

- `-Dyear=2025` – choose which `src/<year>` directory to use (defaults to whatever you set in `Config.default_year`).
- `-Dday=5` – restricts discovery to a single day. The build helper filters both `run` and `test` to that day and forwards `5` to the executable when you don’t provide custom args.

## Expected repository layout

```
repo/
├─ build.zig
├─ build.zon
├─ src/
│  ├─ 2025/
│  │  ├─ day1.zig
│  │  ├─ day1.txt
│  │  └─ …
│  └─ 2023/
│     └─ …
└─ .token        # Advent of Code session token used for input downloads
```

`.token` must contain your Advent of Code session cookie. The helper only downloads an input the first time its `dayN.txt` is missing.

## Getting the library (`zig fetch`)

```bash
zig fetch --save git+https://github.com/Sh4d1/aozig#main
```

`zig fetch` prints a content hash and amends your `build.zon` like:

```zig
.{
    .dependencies = .{
        .aozig = .{
            .url = "git+https://github.com/Sh4d1/aozig#main",
            .hash = "1220…", // from zig fetch output
        },
    },
}
```

Then wire it into `build.zig`:

```zig
const std = @import("std");
const aozig = @import("aozig");

pub fn build(b: *std.Build) !void {
    const dep = b.dependency("aozig", .{});
    try aozig.defaultBuild(b, .{
        .default_year = 2025,
        .binary_name = "aoc",
        .runtime_dependency = dep,
    });
}
```

`defaultBuild` installs the executable, generates the entrypoint that calls `aozig.run`, ensures inputs exist, and registers `run`/`test` steps.

## Configuration reference

`aozig.Config` fields:

- `default_year`: which folder to use when `-Dyear` is omitted.
- `src_root`: root directory scanned for `year/dayN` files (defaults to `src`).
- `binary_name`: name of the produced executable (`main` if unspecified).
- `runtime_dependency`: provide when you depend on `aozig` via `zig fetch`.
- `runtime_module`: override the module used at runtime (defaults to the same `aozig` source the build script imports).

### Input Fetching 

Create a `.token` file in your project root containing your Advent of Code session cookie. To get it:
  1. Log in to https://adventofcode.com
  2. Open browser DevTools (F12)
  3. Go to Application/Storage > Cookies
  4. Copy the value of the 'session' cookie
  5. Save it to `.token`

### Benchmarking

It might be a good idea to run it with `-Doptimize=ReleaseFast`!

```bash
# Run 100 iterations for better statistics
zig build run -- bench 100

# Check minimum heap usage for a specific day
zig build run -Dday=5 -- heap

# Profile a single day
zig build run -Dday=5
```

The benchmark output shows:
- **Min/Max**: Best and worst case timings
- **Mean**: Average time across all runs
- **Median**: Middle value (more robust against outliers)
- **Stddev**: Consistency of your solution (lower is better)

### Template Generator

Create new day files quickly:

```bash
# Create day 5 for the default year
zig build -Dnew=5

# Create day 10 for a specific year
zig build -Dnew=10 -Dyear=2024
```

Happy Advent of Coding!
