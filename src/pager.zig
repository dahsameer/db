const std = @import("std");
const Row = @import("row.zig").Row;

pub const PAGE_SIZE: u16 = 4096;
pub const RowSize: u16 = @sizeOf(Row);
pub const ROWS_PER_PAGE: u16 = PAGE_SIZE / RowSize;
pub const TABLE_MAX_PAGES: u16 = 100;

pub const Page = [PAGE_SIZE]u8;

pub const Pager = struct {
    file: std.fs.File,
    file_len: u64,
    pages: [TABLE_MAX_PAGES]?*Page = [_]?*Page{null} ** TABLE_MAX_PAGES,
};

var gpa = std.heap.page_allocator;

pub fn get_page(pager: *Pager, page_num: usize) !*Page {
    if (page_num >= TABLE_MAX_PAGES) {
        std.log.err("Tried to access page number out of bounds: {d}", .{page_num});
        return error.PageOutOfBounds;
    }

    if (pager.pages[page_num]) |page| {
        return page;
    }

    const page_buffer = try gpa.create(Page);

    const num_pages_in_file: u16 = @intCast(pager.file_len / PAGE_SIZE);

    if (page_num < num_pages_in_file) {
        try pager.file.seekTo(@intCast(page_num * PAGE_SIZE));
        _ = try pager.file.read(page_buffer);
    }

    pager.pages[page_num] = page_buffer;
    return page_buffer;
}

pub fn flush(pager: *Pager, page_num: usize) !void {
    if (pager.pages[page_num] == null) {
        std.log.err("Tried to flush null page {d}", .{page_num});
        return error.TriedToFlushNullPage;
    }

    const page_to_flush = pager.pages[page_num].?;
    try pager.file.seekTo(@intCast(page_num * PAGE_SIZE));
    _ = try pager.file.write(page_to_flush);
}
