const std = @import("std");
const print = std.debug.print;
const db = @import("database.zig");

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

pub const ExecuteResult = enum {
    Success,
    TableFull,
    DuplicateKey,
    NotFound,
};

pub const Statement = struct {
    stmt_type: StatementType,
    row_to_work_with: db.Row,
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

pub fn execute_statement(stmt: *Statement, table: *db.Table) void {
    switch (stmt.stmt_type) {
        .Select => {
            return execute_select(table);
        },
        .Insert => {
            print("insert into users values({}, {s}, {s})\n", .{ stmt.row_to_work_with.id, stmt.row_to_work_with.username[0..stmt.row_to_work_with.username_length], stmt.row_to_work_with.email[0..stmt.row_to_work_with.email_length] });
            return execute_insert(stmt, table);
        },
        .Update => {
            print("Executing UPDATE statement.\n", .{});
        },
        .Delete => {
            print("Executing DELETE statement.\n", .{});
        },
    }
}

pub fn execute_insert(stmt: *Statement, table: *db.Table) ExecuteResult {
    if (table.num_rows >= db.TABLE_MAX_ROWS) {
        return .TableFull;
    }
    var row_to_insert = stmt.row_to_work_with;
    db.serialize_row(&row_to_insert, db.row_slot(table, table.num_rows));
    table.num_rows += 1;
    return .Success;
}

pub fn execute_select(table: *db.Table) void {
    var row: db.Row = undefined;
    for (0..table.num_rows) |i| {
        const r = db.row_slot(table, i);
        db.deserialize_row(r, &row);
        print("Row {}: id={}, username={}, email={}\n", .{ i, row.id, row.username[0..row.username_length], row.email[0..row.email_length] });
    }
}
