const std = @import("std");

pub const std_options: std.Options = .{
    .http_disable_tls = false,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next(); // exe name
    const year_str = args.next() orelse return usageError("missing year argument");
    const day_str = args.next() orelse return usageError("missing day argument");
    const output_path = args.next() orelse return usageError("missing output path argument");
    const token_path = args.next() orelse ".token";

    const year = std.fmt.parseInt(u16, year_str, 10) catch return usageError("invalid year");
    const day = std.fmt.parseInt(u8, day_str, 10) catch return usageError("invalid day");

    const uri_text = try std.fmt.allocPrint(allocator, "https://adventofcode.com/{d}/day/{d}/input", .{ year, day });
    defer allocator.free(uri_text);
    const uri = try std.Uri.parse(uri_text);

    const token_buf = std.fs.cwd().readFileAlloc(allocator, token_path, 256) catch |err| {
        std.log.err("Failed to read token file '{s}': {}", .{ token_path, err });
        std.log.err("Create a .token file containing your Advent of Code session cookie in the project root.", .{});
        std.log.err("Or pass a custom token path as the fourth argument to aozig_fetch_inputs.", .{});
        return err;
    };
    defer allocator.free(token_buf);
    const token = std.mem.trim(u8, token_buf, " \t\r\n");

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const cookie_header = std.http.Header{
        .name = "cookie",
        .value = try std.fmt.allocPrint(allocator, "session={s}", .{token}),
    };
    defer allocator.free(cookie_header.value);

    const file = try std.fs.cwd().createFile(output_path, .{});
    defer file.close();
    var writer = file.writer(&.{});

    const resp = try client.fetch(.{
        .method = .GET,
        .extra_headers = &.{cookie_header},
        .location = .{ .uri = uri },
        .response_writer = &writer.interface,
    });
    if (resp.status.class() != .success) {
        std.log.err("failed to download {s}: {}", .{ output_path, resp.status });
        return error.HTTPError;
    }
}

fn usageError(msg: []const u8) !void {
    std.log.err("input fetcher usage: fetch_inputs <year> <day> <output_path> [token_path]", .{});
    std.log.err("{s}", .{msg});
    return error.InvalidArgs;
}
