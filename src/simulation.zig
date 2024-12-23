const constsants = @import("constants.zig");

pub const Cell = enum {
    Empty,
    Sand,
    Generator,
    Wall,
};
pub const State = struct {
    paused: bool = true,
    gridcell: [constsants.GRIDSIZE]Cell = undefined,
    active_brush: Cell = .Sand,

    //    pub fn print_grid(self: State) void {
    //        for (0..GRID_H) |j| {
    //            for (0..GRID_W) |i| {
    //                if (self.gridcell[i + j * GRID_W] == .Empty)
    //                    std.debug.print("1", .{})
    //                else
    //                    std.debug.print("0", .{});
    //            }
    //            std.debug.print("\n", .{});
    //        }
    //        std.debug.print("-------------------------------\n", .{});
    //    }
};

pub fn grid_coords_from_xy(x: usize, y: usize) usize {
    return @divFloor(x, constsants.CELLSIZE) + @divFloor(y, constsants.CELLSIZE) * constsants.GRID_W;
}
