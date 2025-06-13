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
        var stmt = Statement{ .stmt_type = .Select };
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

pub fn prepare_statement(input: []const u8, stmt: *Statement) PrepareResult {
    if (std.mem.startsWith(u8, input, "select")) {
        stmt.stmt_type = .Select;
        return .Success;
    } else if (std.mem.startsWith(u8, input, "insert")) {
        stmt.stmt_type = .Insert;
        return .Success;
    } else if (std.mem.startsWith(u8, input, "update")) {
        stmt.stmt_type = .Update;
        return .Success;
    } else if (std.mem.startsWith(u8, input, "delete")) {
        stmt.stmt_type = .Delete;
        return .Success;
    } else {
        return .UnrecognizedStatement;
    }
}

pub fn execute_statement(stmt: *Statement) void {
    switch (stmt.stmt_type) {
        .Select => {
            print("Executing SELECT statement.\n", .{});
        },
        .Insert => {
            print("Executing INSERT statement.\n", .{});
        },
        .Update => {
            print("Executing UPDATE statement.\n", .{});
        },
        .Delete => {
            print("Executing DELETE statement.\n", .{});
        },
    }
}

pub const MetaCommandResult = enum { Exit, Success, UnrecognizedCommand };

pub const PrepareResult = enum {
    Success,
    SyntaxError,
    UnrecognizedStatement,
};

pub const StatementType = enum {
    Select,
    Insert,
    Update,
    Delete,
};

pub const Statement = struct { stmt_type: StatementType };
