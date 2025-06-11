const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const InputBuffer = struct {
    buffer: ArrayList(u8),

    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{
            .buffer = ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.buffer.deinit();
    }

    pub fn getInput(self: *Self) []const u8 {
        return self.buffer.items;
    }
};

fn printPrompt() void {
    print("db > ", .{});
}

fn readInput(input_buffer: *InputBuffer) !void {
    const stdin = std.io.getStdIn().reader();

    input_buffer.buffer.clearRetainingCapacity();

    try stdin.readUntilDelimiterArrayList(&input_buffer.buffer, '\n', 1024);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_buffer = InputBuffer.init(allocator);
    defer input_buffer.deinit();

    while (true) {
        printPrompt();

        readInput(&input_buffer) catch |err| switch (err) {
            error.EndOfStream => {
                print("Goodbye!\n", .{});
                return;
            },
            else => {
                print("Error reading input: {}\n", .{err});
                continue;
            },
        };

        const input = input_buffer.getInput();

        if (std.mem.eql(u8, input, ".exit")) {
            print("Goodbye!\n", .{});
            return;
        } else {
            print("Unrecognized command '{s}'.\n", .{input});
        }
    }
}
