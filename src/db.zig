const std = @import("std");
const Pager = @import("pager.zig").Pager;
const Page = @import("pager.zig").Page;
const pager_consts = @import("pager.zig");
const Table = @import("table.zig").Table;
const Row = @import("row.zig").Row;
const get_page = @import("pager.zig").get_page;
const row_size = 4 + 32 + 255;

var gpa = std.heap.page_allocator;

pub fn row_slot(table: *Table, row_num: usize) !*Row {
    const page_num = row_num / pager_consts.ROWS_PER_PAGE;
    var page = try get_page(&table.pager, page_num);

    const row_offset = row_num % pager_consts.ROWS_PER_PAGE;
    const byte_offset = row_offset * row_size;

    return @ptrCast(@alignCast(&page[byte_offset]));
}

pub fn db_open(filename: []const u8) !Table {
    const file = std.fs.cwd().openFile(filename, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => try std.fs.cwd().createFile(filename, .{ .read = true }),
        else => return err,
    };

    const file_len = try file.getEndPos();

    const pager = Pager{
        .file = file,
        .file_len = file_len,
    };

    return Table{
        .pager = pager,
        .num_rows = @intCast(file_len / row_size),
    };
}

pub fn db_close(table: *Table) !void {
    var i: usize = 0;
    while (i < pager_consts.TABLE_MAX_PAGES) : (i += 1) {
        if (table.pager.pages[i]) |page| {
            try pager_consts.flush(&table.pager, i);

            gpa.destroy(page);
            table.pager.pages[i] = null;
        }
    }

    try table.pager.file.setEndPos(@intCast(table.num_rows * row_size));
    table.pager.file.close();
}
