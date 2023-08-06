const std = @import("std");
pub const main = @import("main.zig");
pub const nback = @import("nback_data.zig");
pub const game = @import("game.zig");

test {
    std.testing.refAllDecls(@This());
}
