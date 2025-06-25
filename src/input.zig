const std = @import("std");

pub const InputBuffer = struct {
    buffer: [1024]u8 = undefined,
    len: usize = 0,

    pub fn new() InputBuffer {
        return InputBuffer{};
    }
};
