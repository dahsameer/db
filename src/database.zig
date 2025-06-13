pub const Row = struct {
    id: u32,
    username: [32]u8,
    username_length: usize,
    email: [100]u8,
    email_length: usize,
};
