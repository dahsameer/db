const std = @import("std");
const repl = @import("repl.zig");
const db = @import("db.zig");

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len < 2) {
        try std.io.getStdErr().writer().print("Usage: {s} <database_filename>\n", .{args[0]});
        return;
    }
    const filename = args[1];

    var table = try db.db_open(filename);

    defer {
        std.log.info("closing database.", .{});
        db.db_close(&table) catch |err| {
            std.log.err("failed to close database: {any}", .{err});
        };
    }

    try repl.start(&table);
}
