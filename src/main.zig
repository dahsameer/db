const std = @import("std");

const print = std.debug.print;

const InputBuffer = @import("input.zig").InputBuffer;
const Statement = @import("statement.zig").Statement;
const MetaCommandResult = @import("meta_command.zig").MetaCommandResult;
const prepare_statement = @import("statement.zig").prepare_statement;
const execute_statement = @import("statement.zig").execute_statement;
const do_meta_command = @import("meta_command.zig").do_meta_command;

fn printPrompt() void {
    print("db > ", .{});
}

fn readInput(input_buffer: *InputBuffer) !void {
    const stdin = std.io.getStdIn().reader();

    input_buffer.buffer.clearRetainingCapacity();

    try stdin.readUntilDelimiterArrayList(&input_buffer.buffer, '\n', 1024);
    if (@import("builtin").os.tag == .windows) {
        if (input_buffer.buffer.items.len > 0 and input_buffer.buffer.items[input_buffer.buffer.items.len - 1] == '\r') {
            _ = input_buffer.buffer.pop();
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_buffer = InputBuffer.init(allocator);
    defer input_buffer.deinit();

    while (true) {
        var stmt: Statement = undefined;
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

        if (input[0] == '.') {
            const meta_result = do_meta_command(input);
            switch (meta_result) {
                .Success => {
                    continue;
                },
                .Exit => {
                    print("Exiting the program.\n", .{});
                    return;
                },
                else => {
                    print("Unrecognized command '{s}'.\n", .{input});
                    continue;
                },
            }
        }
        const prepare_result = prepare_statement(input, &stmt);
        switch (prepare_result) {
            .Success => {
                print("Statement prepared successfully: {s}\n", .{input});
            },
            else => {
                print("Error preparing statement: {s}\n", .{input});
                continue;
            },
        }
        execute_statement(&stmt);
    }
}
