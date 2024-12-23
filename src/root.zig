const std = @import("std");
const testing = std.testing;

extern "web" fn DrawRectangle(usize, usize, usize, usize, usize) void;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

const simulation = @import("simulation.zig");
const constants = @import("constants.zig");
var state = simulation.State{};

export fn init() void {
    var x: usize = 0;
    var y: usize = 0;

    while (x < constants.sW) : (x += constants.sW / constants.CELLSIZE) {
        while (y < constants.sH) : (y += constants.sH / constants.CELLSIZE) {
            state.gridcell[
                simulation.grid_coords_from_xy(x, y)
            ] = .Empty;
        }
    }
}

const BLACK = 0;
const YELLOW = 1;
const RED = 2;
const PURPLE = 3;
const BLUE = 4;

export fn draw_grid() void {
    var index: usize = 0;
    var x: usize = 0;
    var y: usize = 0;

    while (index < constants.GRIDSIZE) : (index += 1) {
        switch (state.gridcell[index]) {
            .Sand => {
                //                var linear = @as(f32, @floatFromInt(y));
                //                linear /= sW;
                //                const color_sand1 = rl.Color{ .r = 240, .g = 220, .b = 166, .a = 255 };
                //                const color_sand2 = rl.Color{ .r = 246, .g = 179, .b = 1, .a = 255 };
                //                rl.DrawRectangle(x, y, constants.CELLSIZE, constants.CELLSIZE, rl.ColorLerp(color_sand1, color_sand2, linear));
                DrawRectangle(x, y, constants.CELLSIZE, constants.CELLSIZE, YELLOW);
            },
            .Generator => DrawRectangle(x, y, constants.CELLSIZE, constants.CELLSIZE, PURPLE),
            .Wall => DrawRectangle(x, y, constants.CELLSIZE, constants.CELLSIZE, RED),
            .Water => DrawRectangle(x, y, constants.CELLSIZE, constants.CELLSIZE, BLUE),

            else => DrawRectangle(x, y, constants.CELLSIZE, constants.CELLSIZE, BLACK),
        }
        x += constants.CELLSIZE;
        if (x >= constants.sW) {
            x = @mod(x, constants.sW);
            y += constants.CELLSIZE;
            //            rl.DrawLine(0, y, sW, y, rl.BLACK);
        }
    }
}

export fn update() void {
    if (!state.paused)
        @import("update.zig").runPhysics(&state);
}

export fn handleMouseMove(x: usize, y: usize, mode: usize) void {
    const gc = simulation.grid_coords_from_xy(x, y);
    if (mode == 1) {
        state.gridcell[gc] = state.active_brush;
    } else if (mode == 2) {
        state.gridcell[gc] = .Empty;
    }
}

export fn active_brush() usize {
    return @intFromEnum(state.active_brush);
}

export fn handleKeyboard(key: usize) void {
    switch (key) {
        'p', 'P' => state.paused = !state.paused,
        '1' => state.active_brush = .Sand,
        '2' => state.active_brush = .Generator,
        '3' => state.active_brush = .Wall,
        '4' => state.active_brush = .Water,
        else => {},
    }
}
test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
