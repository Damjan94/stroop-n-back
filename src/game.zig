const std = @import("std");
const NBack = @import("nback_data.zig");

const array = std.MultiArrayList(NBack.Data);
nback_data: array,
rounds_played: u8 = 0,

last_round_start_time: f64 = 0,

pub fn init(allocator: std.mem.Allocator, random: std.rand.Random, stimuli_count: u8, max_index: u8, rounds_total: u8) !@This() {
    var nback_data = array{};
    try nback_data.ensureTotalCapacity(allocator, stimuli_count);
    for (0..stimuli_count) |_| {
        nback_data.appendAssumeCapacity(try NBack.Data.init(allocator, random, rounds_total, max_index));
    }
    return .{
        .nback_data = nback_data,
    };
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    var slice = self.nback_data.slice();
    for (0..slice.len) |i| {
        var nback = slice.get(i);
        nback.deinit(allocator);
    }
    self.nback_data.deinit(allocator);
}

pub fn guess(self: *@This(), stimulus_index: usize) void {
    self.nback_data.items(.did_guess)[stimulus_index] = true;
}

pub fn nextRound(self: *@This(), nback_level: u8) void {
    var slice = self.nback_data.slice();
    const nback_data = slice.items(.nback);
    const did_guess = slice.items(.did_guess);
    var total_guesses = slice.items(.correct_total_guesses);
    var user_guesses = slice.items(.correct_user_guesses);
    for (nback_data, did_guess, total_guesses, user_guesses) |nback, d_guess, *correct_total, *correct_user| {
        if (self.rounds_played < nback_level) {
            continue;
        }
        const is_correct_guess = NBack.isCorrectGuess(nback.items, nback_level, self.rounds_played);
        if (is_correct_guess) {
            correct_total.* = correct_total.* + 1;
            if (d_guess) {
                correct_user.* = correct_user.* + 1;
            } else {
                correct_user.* = correct_user.* -| 1;
            }
        }
        if (d_guess and !is_correct_guess) {
            correct_user.* = correct_user.* -| 1;
        }
    }
    self.rounds_played += 1;
}

pub fn getCurrentAtIndex(self: @This(), comptime item: type, items: []const item, index: usize) item {
    const item_index = self.nback_data.items(.nback)[index].items[self.rounds_played];
    return items[item_index];
}

pub fn isGameFinished(self: @This(), rounds_total: u8) bool {
    return rounds_total == self.rounds_played;
}
pub fn correctnessRatio(self: @This()) f32 {
    var ratio: f32 = 0;
    const slice = self.nback_data.slice();

    for (slice.items(.correct_user_guesses), slice.items(.correct_total_guesses)) |correct_user, correct_total| {
        if (correct_total == 0) {
            ratio += 0.5;
            continue;
        }
        ratio += @as(f32, @floatFromInt(correct_user)) / @as(f32, @floatFromInt(correct_total));
    }
    return ratio / @as(f32, @floatFromInt(slice.len));
}

test "game" {
    var rand = std.rand.DefaultPrng.init(0);
    var game = try @This().init(std.testing.allocator, rand.random(), 3, 10, 9);
    defer game.deinit(std.testing.allocator);
}

test "game.nextRound" {
    var rand = std.rand.DefaultPrng.init(0);
    var game = try @This().init(std.testing.allocator, rand.random(), 3, 10, 9);
    defer game.deinit(std.testing.allocator);

    game.nextRound(3);
    try std.testing.expectEqual(@as(u8, 1), game.rounds_played);
}

// test "game.getCurrentAtIndex" {
//     var rand = std.rand.DefaultPrng.init(0);
//     var game = try @This().init(std.testing.allocator, rand.random(), 3, 10, 9);
//     defer game.deinit(std.testing.allocator);

//     const items = [_]u8{ 12, 23, 24, 25, 43, 56 };

//     const current = game.getCurrentAtIndex(u8, &items, 0);
//     try std.testing.expectEqual(@as(u8, 12), current);
// }
