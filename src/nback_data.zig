const std = @import("std");
const array = std.ArrayListUnmanaged(u8);

pub const Data = struct {
    nback: array,
    did_guess: bool = false,
    correct_user_guesses: u8 = 0,
    correct_total_guesses: u8 = 0,

    pub fn init(allocator: std.mem.Allocator, random: std.rand.Random, round_tries: u8, max_index: u8) !@This() {
        var nback_array = try array.initCapacity(allocator, round_tries);
        populateWithRandomIndexies(&nback_array, random, round_tries, max_index);
        return .{
            .nback = nback_array,
        };
    }
    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.nback.deinit(allocator);
    }
};

pub fn populateWithRandomIndexies(nback: *array, rand: std.rand.Random, round_tries: u8, max_index: u8) void {
    for (0..round_tries) |_| {
        nback.appendAssumeCapacity(rand.uintLessThanBiased(u8, max_index));
    }
}

pub fn isCorrectGuess(indicies: []const u8, nback: u8, current_index: u8) bool {
    return indicies[current_index] == indicies[current_index - nback];
}

const testing_allocator = std.testing.allocator;
test "correct_guess" {
    const capacity = 4;
    var b = try array.initCapacity(testing_allocator, capacity);
    defer b.deinit(testing_allocator);
    b.appendAssumeCapacity(4);
    b.appendAssumeCapacity(5);
    b.appendAssumeCapacity(3);
    b.appendAssumeCapacity(5);
    try std.testing.expectEqual(true, isCorrectGuess(b.items, 2, capacity - 1));
    try std.testing.expectEqual(false, isCorrectGuess(b.items, 3, capacity - 1));
}

test "data" {
    var rand = std.rand.DefaultPrng.init(0);
    var nback = try Data.init(std.testing.allocator, rand.random(), 20, 8);
    defer nback.deinit(std.testing.allocator);
}
