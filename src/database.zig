const std = @import("std");

pub const Row = struct {
    id: u32,
    username: [32]u8,
    username_length: usize,
    email: [100]u8,
    email_length: usize,
};

pub const ID_SIZE: usize = @sizeOf(u32);
pub const USERNAME_LENGTH_SIZE: usize = @sizeOf(usize);
pub const USERNAME_SIZE: usize = @sizeOf([32]u8);
pub const EMAIL_LENGTH_SIZE: usize = @sizeOf(usize);
pub const EMAIL_SIZE: usize = @sizeOf([100]u8);

pub const ROW_SIZE: usize = @sizeOf(Row);

pub const PAGE_SIZE: usize = 4096;
pub const TABLE_MAX_PAGES: usize = 100;
pub const ROWS_PER_PAGE: usize = PAGE_SIZE / ROW_SIZE;
pub const TABLE_MAX_ROWS: usize = ROWS_PER_PAGE * TABLE_MAX_PAGES;

pub const Table = struct {
    num_rows: u32,
    pages: [TABLE_MAX_PAGES][PAGE_SIZE]u8,
};

pub fn row_slot(table: *Table, row_num: u32) *anyopaque {
    const page_num: usize = row_num / ROWS_PER_PAGE;
    var page = table.pages[page_num];
    if (page == null) {
        const mem = std.heap.page_allocator.alloc(u8, PAGE_SIZE) catch unreachable;
        page = @ptrCast(mem.ptr);
        table.pages[page_num] = page;
    }
    const row_offset = row_num % ROWS_PER_PAGE;
    const byte_offset = row_offset * ROW_SIZE;
    const page_buf: [*]u8 = @ptrCast(page.?);
    return page_buf + byte_offset;
}

pub fn serialize_row(source: *Row, dest: *anyopaque) void {
    const row_ptr: *Row = @ptrCast(dest);
    row_ptr.id = source.id;
    row_ptr.username_length = source.username_length;
    std.mem.copyForwards(u8, row_ptr.username[0..source.username_length], source.username[0..source.username_length]);
    row_ptr.email_length = source.email_length;
    std.mem.copyForwards(u8, row_ptr.email[0..source.email_length], source.email[0..source.email_length]);
}

pub fn deserialize_row(source: *anyopaque, dest: *Row) void {
    const row_ptr: *Row = @ptrCast(source);
    dest.id = row_ptr.id;
    dest.username_length = row_ptr.username_length;
    std.mem.copyForwards(u8, dest.username[0..row_ptr.username_length], row_ptr.username[0..row_ptr.username_length]);
    dest.email_length = row_ptr.email_length;
    std.mem.copyForwards(u8, dest.email[0..row_ptr.email_length], row_ptr.email[0..row_ptr.email_length]);
}
