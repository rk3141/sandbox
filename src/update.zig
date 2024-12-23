const GRID_H = @import("constants.zig").GRID_H;
const GRID_W = @import("constants.zig").GRID_W;
const GRIDSIZE = @import("constants.zig").GRIDSIZE;
const Cell = @import("simulation.zig").Cell;
const State = @import("simulation.zig").State;

fn count_alive_neighbors(grid: []Cell, index: usize) usize {
    var alive: usize = 0;
    const x = @mod(index, GRID_W);
    const y = @divFloor(index, GRID_W);
    // LEFT
    if (x > 0 and grid[x - 1 + y * GRID_W].state) alive += 1;
    // RIGHT
    if (x < GRID_W - 1 and grid[x + 1 + y * GRID_W].state) alive += 1;
    // TOP LEFT
    if (x > 0 and y > 0 and grid[x - 1 + (y - 1) * GRID_W].state) alive += 1;
    // TOP RIGHT
    if (x < GRID_W - 1 and y > 0 and grid[x + 1 + (y - 1) * GRID_W].state) alive += 1;
    // BOTTOM LEFT
    if (x > 0 and y < GRID_H - 1 and grid[x - 1 + (y + 1) * GRID_W].state) alive += 1;
    // BOTTOM RIGHT
    if (x < GRID_W - 1 and y < GRID_H - 1 and grid[x + 1 + (y + 1) * GRID_W].state) alive += 1;
    // TOP
    if (y > 0 and grid[x + (y - 1) * GRID_W].state) alive += 1;
    // BOTTOM
    if (y < GRID_H - 1 and grid[x + (y + 1) * GRID_W].state) alive += 1;
    return alive;
}

pub fn runConway(state: *State) void {
    var new_state = State{};
    new_state.paused = state.paused;

    var index: usize = 0;
    while (index < GRIDSIZE) : (index += 1) {
        const alive = count_alive_neighbors(&state.gridcell, index);
        //        std.debug.print("{}", .{alive});
        //        if (@mod(index + 1, GRID_W) == 0) {
        //            std.debug.print("\n", .{});
        //        }
        if (state.gridcell[index].state) {
            new_state.gridcell[index].state = !(alive < 2 or alive > 3);
        } else {
            new_state.gridcell[index].state = alive == 3;
        }
    }
    state.* = new_state;
}

var prng = @import("std").rand.DefaultPrng.init(0x40808);
const rand = prng.random();
pub fn runPhysics(state: *State) void {
    var new_state = State{};

    var x: usize = 0;
    var y: usize = 0;

    var index: usize = 0;
    while (index < GRIDSIZE) : (index += 1) {
        if (state.gridcell[index] != .Empty) {
            new_state.gridcell[index] = state.gridcell[index];
            if (y < GRID_H - 1) {
                switch (state.gridcell[index]) {
                    .Sand => {
                        if (state.gridcell[index + GRID_W] == .Empty) {
                            new_state.gridcell[index] = .Empty;
                            new_state.gridcell[index + GRID_W] = .Sand;
                        } else if (state.gridcell[index + GRID_W] == .Water) {
                            new_state.gridcell[index] = .Water;
                            new_state.gridcell[index + GRID_W] = .Sand;
                        } else {
                            const left = rand.boolean();
                            if (left and x > 0 and state.gridcell[index + GRID_W - 1] == .Empty) {
                                new_state.gridcell[index] = .Empty;
                                new_state.gridcell[index + GRID_W - 1] = .Sand;
                            } else if (left and x > 0 and state.gridcell[index + GRID_W - 1] == .Water) {
                                new_state.gridcell[index] = .Water;
                                new_state.gridcell[index + GRID_W - 1] = .Sand;
                            } else if (!left and x < GRID_W - 1 and state.gridcell[index + GRID_W + 1] == .Empty) {
                                new_state.gridcell[index] = .Empty;
                                new_state.gridcell[index + GRID_W + 1] = .Sand;
                            } else if (!left and x < GRID_W - 1 and state.gridcell[index + GRID_W + 1] == .Water) {
                                new_state.gridcell[index] = .Water;
                                new_state.gridcell[index + GRID_W + 1] = .Sand;
                            }
                        }
                    },
                    .Generator => {
                        new_state.gridcell[index + GRID_W] = .Sand;
                    },
                    .Water => {
                        new_state.gridcell[index] = .Empty;
                        if (state.gridcell[index + GRID_W] == .Empty) {
                            new_state.gridcell[index + GRID_W] = .Water;
                        } else {
                            const left = rand.boolean();
                            const right_empty =
                                x < GRID_W - 1 and state.gridcell[index + 1] == .Empty;
                            const left_empty =
                                x > 0 and state.gridcell[index - 1] == .Empty;
                            const bleft =
                                x > 0 and state.gridcell[index + GRID_W - 1] == .Empty;
                            const bright =
                                x < GRID_W - 1 and state.gridcell[index + GRID_W + 1] == .Empty;
                            if (left_empty and right_empty) {
                                if (left) {
                                    new_state.gridcell[index - 1] = .Water;
                                } else {
                                    new_state.gridcell[index + 1] = .Water;
                                }
                            } else if (left_empty) {
                                new_state.gridcell[index - 1] = .Water;
                            } else if (right_empty) {
                                new_state.gridcell[index + 1] = .Water;
                            } else if (bleft and bright) {
                                if (left) {
                                    new_state.gridcell[index + GRID_W - 1] = .Water;
                                } else {
                                    new_state.gridcell[index + GRID_W + 1] = .Water;
                                }
                            } else if (left_empty) {
                                new_state.gridcell[index + GRID_W - 1] = .Water;
                            } else if (right_empty) {
                                new_state.gridcell[index + GRID_W + 1] = .Water;
                            } else {
                                new_state.gridcell[index] = .Water;
                            }
                        }
                    },
                    else => {},
                }
            }
        }
        x += 1;
        if (@mod(x, GRID_W) == 0) {
            y += 1;
            x = 0;
        }
    }
    @memcpy(&state.gridcell, &new_state.gridcell);
}
