const r = @import("raylib.zig").r;
const std = @import("std");
pub const Screen = struct {
    width: f32,
    height: f32,
};

pub const TextPosition = struct {
    x: f32,
    y: f32,

    pub fn xToInt(self: @This()) i32 {
        return @intFromFloat(self.x);
    }
    pub fn yToInt(self: @This()) i32 {
        return @intFromFloat(self.y);
    }
};
const GuiItem = struct {
    position: r.Rectangle,
    text: [*]const u8,
};
pub fn ButtonSameColor(screen: Screen) GuiItem {
    const size = ButtonBigSize(screen);
    return .{
        .position = .{
            .x = screen.width * 0.55,
            .y = screen.height * 0.8,
            .width = size.x,
            .height = size.y,
        },

        .text = "Same Color".ptr,
    };
}
pub fn ButtonSameText(screen: Screen) GuiItem {
    const size = ButtonBigSize(screen);
    return .{
        .position = .{
            .x = screen.width * 0.45 - size.x,
            .y = screen.height * 0.8,
            .width = size.x,
            .height = size.y,
        },

        .text = "Same Text".ptr,
    };
}
pub fn ButtonPlayGame(screen: Screen) GuiItem {
    const size = ButtonSmallSize(screen);
    return .{
        .position = .{
            .x = screen.width * 0.6,
            .y = screen.height * 0.8,
            .width = size.x,
            .height = size.y,
        },

        .text = "Play!".ptr,
    };
}
pub fn ButtonMainMenu(screen: Screen) GuiItem {
    const size = ButtonSmallSize(screen);
    return .{
        .position = .{
            .x = screen.width * 0.4 - size.x,
            .y = screen.height * 0.8,
            .width = size.x,
            .height = size.y,
        },

        .text = "Main Menu".ptr,
    };
}

pub fn CheckboxNBackIsVariable(screen: Screen) GuiItem {
    const size = ButtonSmallSize(screen);
    return .{
        .position = .{
            .x = screen.width * 0.05,
            .y = screen.height * 0.04,
            .width = size.x,
            .height = size.y,
        },

        .text = "Variable N Back".ptr,
    };
}

pub fn LabelLevel(screen: Screen, font_size: i16, text_buffer: []u8, level: u8) GuiItem {
    const size = ButtonBigSize(screen);
    const text = std.fmt.bufPrint(text_buffer, "Current N back is {}", .{level}) catch "N back level too high";
    const position = textAtFractionOfScreen(text, screen, .{ .x = 0.5, .y = 0.05 }, font_size);
    return .{
        .position = .{
            .x = position.x,
            .y = position.y,
            .width = size.x * 2,
            .height = size.y,
        },

        .text = text.ptr,
    };
}
pub fn LabelTextColor(screen: Screen, font_size: i16, text: []const u8) GuiItem {
    const size = ButtonBigSize(screen);
    const position = textAtFractionOfScreen(text, screen, .{ .x = 0.5, .y = 0.5 }, font_size);
    return .{
        .position = .{
            .x = position.x,
            .y = position.y,
            .width = size.x * 2,
            .height = size.y,
        },

        .text = text.ptr,
    };
}
pub fn textAtFractionOfScreen(text: []const u8, s: Screen, fraction: r.Vector2, font_size: i16) TextPosition {
    const text_len: f32 = @floatFromInt(r.MeasureText(text.ptr, font_size));
    return .{
        .x = s.width * fraction.x - text_len * 0.5,
        .y = s.height * fraction.y,
    };
}
fn ButtonBigSize(screen: Screen) r.Vector2 {
    return .{
        .x = screen.width * 0.2,
        .y = screen.height * 0.2,
    };
}
fn ButtonSmallSize(screen: Screen) r.Vector2 {
    return .{
        .x = screen.width * 0.1,
        .y = screen.height * 0.1,
    };
}
