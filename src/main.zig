const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const math = std.math;

const rl = @cImport({
    @cInclude("raylib.h");
});

const Vector2 = rl.Vector2;

const constants = @import("constants.zig");
const simulation = @import("simulation.zig");
const update = @import("update.zig");

const CELLSIZE = constants.CELLSIZE;
const GRID_W = constants.GRID_W;
const GRID_H = constants.GRID_H;
const sW = constants.sW;
const sH = constants.sH;

fn handleMouseClick(state: *simulation.State) void {
    const x = rl.GetMouseX();
    const y = rl.GetMouseY();
    const gc = simulation.grid_coords_from_xy(@intCast(x), @intCast(y));
    if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
        state.gridcell[gc] = state.active_brush;
    } else if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_RIGHT)) {
        state.gridcell[gc] = .Empty;
    }
}
fn handleKeyboard(state: *simulation.State) void {
    if (rl.GetKeyPressed() == rl.KEY_P) {
        state.paused = !state.paused;
    }
    if (rl.IsKeyDown(rl.KEY_ONE)) {
        state.active_brush = .Sand;
    }
    if (rl.IsKeyDown(rl.KEY_TWO)) {
        state.active_brush = .Generator;
    }
    if (rl.IsKeyDown(rl.KEY_THREE)) {
        state.active_brush = .Wall;
    }
    if (rl.IsKeyDown(rl.KEY_FOUR)) {
        state.active_brush = .Water;
    }
}

fn drawGrid(state: simulation.State) void {
    var index: usize = 0;
    var x: c_int = 0;
    var y: c_int = 0;
    for (0..GRID_W) |i| {
        rl.DrawLine(@intCast(i * CELLSIZE), 0, @intCast(i * CELLSIZE), sH, rl.BLACK);
    }
    while (index < constants.GRIDSIZE) : (index += 1) {
        switch (state.gridcell[index]) {
            .Sand => {
                var linear = @as(f32, @floatFromInt(y));
                linear /= sW;
                const color_sand1 = rl.Color{ .r = 240, .g = 220, .b = 166, .a = 255 };
                const color_sand2 = rl.Color{ .r = 246, .g = 179, .b = 1, .a = 255 };
                rl.DrawRectangle(x, y, CELLSIZE, CELLSIZE, rl.ColorLerp(color_sand1, color_sand2, linear));
            },
            .Generator => rl.DrawRectangle(x, y, CELLSIZE, CELLSIZE, rl.PURPLE),
            .Wall => rl.DrawRectangle(x, y, CELLSIZE, CELLSIZE, rl.RED),
            .Water => rl.DrawRectangle(x, y, CELLSIZE, CELLSIZE, rl.BLUE),

            else => rl.DrawRectangle(x, y, CELLSIZE, CELLSIZE, rl.BLACK),
        }
        x += CELLSIZE;
        if (x >= sW) {
            x = @mod(x, sW);
            y += CELLSIZE;
            rl.DrawLine(0, y, sW, y, rl.BLACK);
        }
    }
}

pub fn main() !void {
    rl.InitWindow(sW, sH, "raylib example");
    rl.SetTargetFPS(60);

    var x: usize = 0;
    var y: usize = 0;

    var state = simulation.State{};

    while (x < sW) : (x += sW / CELLSIZE) {
        while (y < sH) : (y += sH / CELLSIZE) {
            state.gridcell[
                simulation.grid_coords_from_xy(x, y)
            ] = .Empty;
        }
    }

    while (!rl.WindowShouldClose()) {
        // Begin Drawing
        rl.BeginDrawing();
        rl.ClearBackground(rl.WHITE);
        defer rl.EndDrawing();

        drawGrid(state);
        //        state.print_grid();

        handleMouseClick(&state);
        handleKeyboard(&state);
        if (!state.paused) {
            //            runConway(&state);
            update.runPhysics(&state);
            //            state.print_grid();
        }
        rl.DrawFPS(10, 10);
    }

    rl.CloseWindow();
}

fn isVectorOutOfBounds(vec: Vector2, a: Vector2, b: Vector2) bool {
    return (vec.y < a.y or vec.y > b.y) or (vec.x > b.x or vec.x < a.x);
}

fn lerp(v1: Vector2, v2: Vector2, w: f32) Vector2 {
    return .{
        .x = v1.x + (v2.x - v1.x) * w,
        .y = v1.y + (v2.y - v1.y) * w,
    };
}
