pub const Row = struct {
    id: u32,
    username: [COLUMN_USERNAME_SIZE:0]u8,
    email: [COLUMN_EMAIL_SIZE:0]u8,
};

pub const COLUMN_USERNAME_SIZE = 32;
pub const COLUMN_EMAIL_SIZE = 255;

pub fn print(row: *const Row, writer: anytype) !void {
    try writer.print("({d}, {s}, {s})\n", .{
        row.id,
        row.username,
        row.email,
    });
}
