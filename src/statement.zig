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
