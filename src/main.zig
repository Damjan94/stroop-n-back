const std = @import("std");
const Game = @import("game.zig");
const r = @import("raylib.zig").r;
const stimuli = @import("stimuli.zig");
const gui = @import("gui_elements.zig");
const State = enum {
    main_menu,
    before_play,
    play,
    after_play,
};
const GameOptions = struct {
    game_state: State,
    max_n_back_level: u8,
    rounds_total: u8,
    n_back_variable: bool,
};
const SWITCH_NEXT_PAIR_TIME = 2;
const GAME_NAME = "Stroop n back";
const screen = gui.Screen{ .width = 1280, .height = 720 };
const font_size: i16 = @intFromFloat(screen.width / 30);

pub fn main() !void {
    var creater_allocator = std.heap.GeneralPurposeAllocator(.{ .never_unmap = true, .retain_metadata = true }){};
    // var creater_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = creater_allocator.allocator();
    r.InitWindow(screen.width, screen.height, GAME_NAME);
    r.SetTargetFPS(60);
    defer r.CloseWindow();
    {
        var random = std.rand.DefaultPrng.init(@bitCast(std.time.timestamp()));
        const stimuli_count = 2;
        var options: GameOptions = .{
            .game_state = .main_menu,
            .max_n_back_level = 2,
            .n_back_variable = true,
            .rounds_total = 20,
        };
        var n_game: ?Game = null;
        defer {
            if (n_game) |*game| {
                game.deinit(allocator);
            }
        }
        var level_text_buffer = [_]u8{0} ** 256;
        while (!r.WindowShouldClose()) {
            r.BeginDrawing();
            defer r.EndDrawing();
            r.ClearBackground(r.RAYWHITE);
            switch (options.game_state) {
                .main_menu => {
                    options = mainMenu(options);
                },
                .before_play => {
                    if (n_game) |*game| {
                        game.deinit(allocator);
                    }
                    n_game = try Game.init(allocator, random.random(), stimuli_count, stimuli.colors.len, options.rounds_total);
                    n_game.?.last_round_start_time = r.GetTime();
                    options.game_state = .play;
                },
                .play => {
                    options = playGame(options, &level_text_buffer, &n_game.?);
                },
                .after_play => {
                    options = drawScore(options);
                },
            }
        }
    }
    const check = creater_allocator.deinit();
    switch (check) {
        .ok => {
            std.debug.print("no leak detected\n", .{});
        },
        .leak => {
            std.debug.print("there was a leak\n", .{});
        },
    }
}

fn mainMenu(options: GameOptions) GameOptions {
    var new_options = options;

    const check_box_variable = gui.CheckboxNBackIsVariable(screen);
    _ = r.GuiCheckBox(check_box_variable.position, check_box_variable.text, &new_options.n_back_variable);

    const button_play = gui.ButtonPlayGame(screen);
    if (r.GuiButton(button_play.position, button_play.text) > 0) {
        new_options.game_state = .before_play;
    }

    return new_options;
}

fn playGame(options: GameOptions, text_buffer: []u8, n_game: *Game) GameOptions {
    var new_options = options;
    const current_time = r.GetTime();
    {
        const label_level = gui.LabelLevel(screen, font_size, text_buffer, options.max_n_back_level);
        const old_text_size = r.GuiGetStyle(r.DEFAULT, r.TEXT_SIZE);
        r.GuiSetStyle(r.DEFAULT, r.TEXT_SIZE, font_size);
        defer r.GuiSetStyle(r.DEFAULT, r.TEXT_SIZE, old_text_size);
        _ = r.GuiLabel(label_level.position, label_level.text);
    }

    drawStimulants(current_time, n_game.*);
    const button_color_match = gui.ButtonSameColor(screen);
    if (r.GuiButton(button_color_match.position, button_color_match.text) > 0) {
        n_game.guess(0);
    }
    const button_text_match = gui.ButtonSameText(screen);
    if (r.GuiButton(button_text_match.position, button_text_match.text) > 0) {
        n_game.guess(1);
    }

    if (current_time - n_game.last_round_start_time > SWITCH_NEXT_PAIR_TIME) {
        n_game.last_round_start_time = current_time;
        n_game.nextRound(options.max_n_back_level);
    }
    if (n_game.isGameFinished(new_options.rounds_total)) {
        const correctness_ratio = n_game.correctnessRatio();
        if (correctness_ratio < 0.5) {
            new_options.rounds_total = @max(5, new_options.rounds_total - 2);
            new_options.max_n_back_level = @max(1, new_options.max_n_back_level - 1);
        }
        if (correctness_ratio > 0.8) {
            new_options.max_n_back_level += 1;
            new_options.rounds_total += 2;
        }
        new_options.game_state = .after_play;
    }
    return new_options;
}

fn drawStimulants(current_time: f64, n_game: Game) void {
    const transition_period = 0.1;
    if (current_time - n_game.last_round_start_time > transition_period) {
        const current_color = n_game.getCurrentAtIndex(@TypeOf(stimuli.colors[0]), &stimuli.colors, 0);
        const current_text = n_game.getCurrentAtIndex(@TypeOf(stimuli.colors_text[0]), &stimuli.colors_text, 1);

        const old_text_size = r.GuiGetStyle(r.DEFAULT, r.TEXT_SIZE);
        r.GuiSetStyle(r.DEFAULT, r.TEXT_SIZE, font_size);
        defer r.GuiSetStyle(r.DEFAULT, r.TEXT_SIZE, old_text_size);

        const old_text_color = r.GuiGetStyle(r.DEFAULT, r.TEXT_COLOR_NORMAL);
        r.GuiSetStyle(r.DEFAULT, r.TEXT_COLOR_NORMAL, r.ColorToInt(current_color));
        defer r.GuiSetStyle(r.DEFAULT, r.TEXT_COLOR_NORMAL, old_text_color);

        const label_text = gui.LabelTextColor(screen, font_size, current_text);
        _ = r.GuiLabel(label_text.position, label_text.text);

        // r.DrawText(current_text.ptr, text_position.xToInt(), text_position.yToInt(), font_size, current_color);
    }
}

fn drawScore(options: GameOptions) GameOptions {
    var new_options = options;
    const button_play = gui.ButtonPlayGame(screen);
    if (r.GuiButton(button_play.position, button_play.text) > 0) {
        new_options.game_state = .before_play;
    }
    const button_main_menu = gui.ButtonMainMenu(screen);
    if (r.GuiButton(button_main_menu.position, button_main_menu.text) > 0) {
        new_options.game_state = .main_menu;
    }

    return new_options;
}
