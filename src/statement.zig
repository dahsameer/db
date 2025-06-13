const std = @import("std");
const print = std.debug.print;
const Row = @import("database.zig").Row;

pub const StatementType = enum {
    Select,
    Insert,
    Update,
    Delete,
};

pub const PrepareResult = enum {
    Success,
    SyntaxError,
    UnrecognizedStatement,
};

pub const Statement = struct {
    stmt_type: StatementType,
    row_to_work_with: Row,
};

pub fn prepare_statement(input: []const u8, stmt: *Statement) PrepareResult {
    var tokenizer = std.mem.tokenizeScalar(u8, input, ' ');
    var args: usize = 0;
    if (std.mem.startsWith(u8, input, "select")) {
        stmt.stmt_type = .Select;
        return .Success;
    } else if (std.mem.startsWith(u8, input, "insert")) {
        stmt.stmt_type = .Insert;
        _ = tokenizer.next();
        if (tokenizer.next()) |arg| {
            stmt.row_to_work_with.id = std.fmt.parseInt(u32, arg, 10) catch return .SyntaxError;
            args += 1;
        }
        if (tokenizer.next()) |arg| {
            stmt.row_to_work_with.username_length = arg.len;
            std.mem.copyForwards(u8, stmt.row_to_work_with.username[0..arg.len], arg);
            args += 1;
        }
        if (tokenizer.next()) |arg| {
            stmt.row_to_work_with.email_length = arg.len;
            std.mem.copyForwards(u8, stmt.row_to_work_with.email[0..arg.len], arg);
            args += 1;
        }
        if (args < 3) {
            return .SyntaxError;
        }
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
            print("insert into users values({}, {s}, {s})\n", .{ stmt.row_to_work_with.id, stmt.row_to_work_with.username[0..stmt.row_to_work_with.username_length], stmt.row_to_work_with.email[0..stmt.row_to_work_with.email_length] });
        },
        .Update => {
            print("Executing UPDATE statement.\n", .{});
        },
        .Delete => {
            print("Executing DELETE statement.\n", .{});
        },
    }
}
