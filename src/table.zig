const Pager = @import("pager.zig").Pager;

pub const Table = struct {
    pager: Pager,
    num_rows: usize,
};
