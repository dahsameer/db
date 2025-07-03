const std = @import("std");
const InputBuffer = @import("input.zig").InputBuffer;
const Row = @import("row.zig").Row;
const column_sizes = @import("row.zig");
const row_print = @import("row.zig").print;
const Table = @import("table.zig").Table;
const pager_consts = @import("pager.zig");
const db = @import("db.zig");

const PrepareResult = enum {
    Success,
    Unrecognized,
    SyntaxError,
};

const Statement = struct {
    kind: enum {
        Insert,
        Select,
    },
    row_to_insert: Row,
};

const MetaCommandResult = enum { Exit, Success, UnrecognizedCommand };

fn do_meta_command(input: []const u8, writer: anytype) !MetaCommandResult {
    if (std.mem.eql(u8, input, ".exit")) {
        return .Exit;
    } else if (std.mem.eql(u8, input, ".help")) {
        try writer.print("Available commands:\n.exit - Exit the program\n.help - Show this help message\n", .{});
        return .Success;
    } else {
        return .UnrecognizedCommand;
    }
}

fn prepare_statement(input: []const u8, statement: *Statement) PrepareResult {
    var tokenizer = std.mem.tokenizeScalar(u8, input, ' ');
    if (std.mem.startsWith(u8, input, "insert")) {
        statement.kind = .Insert;

        var id: u32 = 0;
        var username_buf: [column_sizes.COLUMN_USERNAME_SIZE]u8 = undefined;
        var email_buf: [column_sizes.COLUMN_EMAIL_SIZE]u8 = undefined;

        if (tokenizer.next()) |first_part| {
            if (!std.mem.eql(u8, first_part, "insert")) {
                return .SyntaxError;
            }
        } else {
            return .SyntaxError;
        }

        if (tokenizer.next()) |id_str| {
            id = std.fmt.parseInt(u32, id_str, 10) catch {
                return .SyntaxError;
            };
        } else {
            return .SyntaxError;
        }

        if (tokenizer.next()) |username_str| {
            if (username_str.len >= column_sizes.COLUMN_USERNAME_SIZE) {
                return .SyntaxError;
            }
            @memcpy(username_buf[0..username_str.len], username_str);
            username_buf[username_str.len] = 0;
        } else {
            return .SyntaxError;
        }

        if (tokenizer.next()) |email_str| {
            if (email_str.len >= column_sizes.COLUMN_EMAIL_SIZE) {
                return .SyntaxError;
            }
            @memcpy(email_buf[0..email_str.len], email_str);
            email_buf[email_str.len] = 0;
        } else {
            return .SyntaxError;
        }

        if (tokenizer.next() != null) {
            return .SyntaxError;
        }

        statement.row_to_insert.id = id;
        @memcpy(&statement.row_to_insert.username, &username_buf);
        @memcpy(&statement.row_to_insert.email, &email_buf);

        return .Success;
    }

    if (std.mem.eql(u8, input, "select")) {
        statement.kind = .Select;
        return .Success;
    }

    return .Unrecognized;
}

fn execute_statement(statement: *const Statement, table: *Table, writer: anytype) !void {
    switch (statement.kind) {
        .Insert => {
            const max_rows = pager_consts.TABLE_MAX_PAGES * pager_consts.ROWS_PER_PAGE;
            if (table.num_rows >= max_rows) {
                try writer.print("Error: Table is full.\n", .{});
                return;
            }

            const dest = try db.row_slot(table, table.num_rows);
            dest.* = statement.row_to_insert;
            table.num_rows += 1;

            try writer.print("Executed.\n", .{});
        },
        .Select => {
            var i: usize = 0;
            while (i < table.num_rows) : (i += 1) {
                const row = try db.row_slot(table, i);
                try row_print(row, writer);
            }
            try writer.print("Executed.\n", .{});
        },
    }
}

pub fn start(table: *Table) !void {
    var input_buffer = InputBuffer.new();
    const stdout = std.io.getStdOut().writer();

    while (true) {
        try stdout.print("db > ", .{});

        const raw_input = (try std.io.getStdIn().reader().readUntilDelimiterOrEof(
            &input_buffer.buffer,
            '\n',
        )) orelse {
            try stdout.print("\nBye!\n", .{});
            return;
        };

        const command = std.mem.trim(u8, raw_input, " \r\n\t");

        if (command.len > 0 and command[0] == '.') {
            const meta_result = try do_meta_command(command, stdout);
            switch (meta_result) {
                .Success => {
                    continue;
                },
                .Exit => {
                    try stdout.print("Exiting the program.\n", .{});
                    return;
                },
                else => {
                    try stdout.print("Unrecognized command '{s}'.\n", .{command});
                    continue;
                },
            }
        }

        var statement: Statement = undefined;
        switch (prepare_statement(command, &statement)) {
            .Success => {
                try execute_statement(&statement, table, stdout);
            },
            .SyntaxError => {
                try stdout.print("Syntax error. Could not parse statement.\n", .{});
            },
            .Unrecognized => {
                try stdout.print("Unrecognized keyword at start of '{s}'.\n", .{command});
            },
        }
    }
}
