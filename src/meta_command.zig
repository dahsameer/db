const std = @import("std");
const print = std.debug.print;

pub const MetaCommandResult = enum { Exit, Success, UnrecognizedCommand };

pub fn do_meta_command(input: []const u8) MetaCommandResult {
    if (std.mem.eql(u8, input, ".exit")) {
        return .Exit;
    } else if (std.mem.eql(u8, input, ".help")) {
        print("Available commands:\n", .{});
        print(".exit - Exit the program\n", .{});
        print(".help - Show this help message\n", .{});
        return .Success;
    } else {
        return .UnrecognizedCommand;
    }
}
