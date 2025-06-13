const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const InputBuffer = struct {
    buffer: ArrayList(u8),

    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{
            .buffer = ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.buffer.deinit();
    }

    pub fn getInput(self: *Self) []const u8 {
        return self.buffer.items;
    }
};
