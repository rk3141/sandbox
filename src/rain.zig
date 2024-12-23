const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const math = std.math;

const rl = @cImport({
    @cInclude("raylib.h");
});

const sW = 1260;
const sH = 450;

fn noise() f32 {
    return @as(f32, @floatFromInt(rl.GetRandomValue(-100, 100))) / 20.0;
}

fn Rain(comptime size: usize) type {
    return struct {
        droplets: [size]Droplet,
        cloudStart: c_int,
        cloudEnd: c_int,
        const Droplet = struct {
            pos: rl.Vector2,
            vel: rl.Vector2 = .{},
            acc: rl.Vector2 = .{},
        };

        const Self = @This();

        pub fn new(cloudStart: c_int, cloudEnd: c_int) !Self {
            var droplets: [size]Droplet = undefined;

            for (0..size) |i| {
                droplets[i] = (newDropletInit(cloudStart, cloudEnd));
            }

            return .{ .droplets = droplets, .cloudStart = cloudStart, .cloudEnd = cloudEnd };
        }

        fn newDroplet(self: *Self) Droplet {
            return Droplet{ .pos = .{
                .x = @floatFromInt(rl.GetRandomValue(self.cloudStart, self.cloudEnd)),
                .y = 0,
            } };
        }

        fn newDropletInit(
            cloudStart: c_int,
            cloudEnd: c_int,
        ) Droplet {
            return Droplet{ .pos = .{
                .x = @floatFromInt(rl.GetRandomValue(cloudStart, cloudEnd)),
                .y = @floatFromInt(rl.GetRandomValue(0, sH)),
            } };
        }

        pub fn Update(self: *Self, mouse: rl.Vector2) void {
            for (0..size) |i| {
                var drop = &self.droplets[i];
                if (drop.pos.y > sH - 10) {
                    drop.* = self.newDroplet();
                    continue;
                }

                const dx = drop.pos.x - mouse.x;
                const dy = drop.pos.y - mouse.y;
                const dmouse = math.sqrt(math.pow(f32, dx, 2) + math.pow(f32, dy, 2));

                const K = 600.0;
                const force = rl.Vector2{
                    .x = K / 30 * dx / math.pow(f32, dmouse, 2),
                    .y = K * dy / math.pow(f32, dmouse, 2),
                };

                drop.pos.x += drop.vel.x;
                drop.pos.y += drop.vel.y;

                drop.vel.y += drop.acc.y;
                drop.vel.x += drop.acc.x;

                drop.acc.y = 5 - drop.vel.y / 2 + force.y;
                drop.acc.x = force.x;
            }
        }

        pub fn Draw(self: *Self) void {
            for (self.droplets) |drop| {
                rl.DrawRectangleV(.{ .x = drop.pos.x - 2.5, .y = drop.pos.y - 5 }, .{ .x = 5, .y = 10 }, .{ .a = 150, .r = 2, .g = 126, .b = 255 });
            }
        }
    };
}
pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    // var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    // defer arena.deinit();

    // const allocator = arena.allocator();
    const rkblue: rl.Color = .{ .r = 0, .g = 100, .b = 255, .a = 255 };

    rl.InitWindow(sW, sH, "raylib example");
    rl.SetTargetFPS(60);

    rl.HideCursor();

    var rain = try Rain(1000).new(10, sW - 10);

    while (!rl.WindowShouldClose()) {
        const mouse = rl.GetMousePosition();
        rain.Update(mouse);

        // Begin Drawing
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.RAYWHITE);

        rl.DrawCircleSectorLines(mouse, 110, 0, -180, 10, rkblue);
        rl.DrawRectangleV(mouse, .{
            .x = 10,
            .y = 10,
        }, rkblue);

        rain.Draw();

        rl.DrawFPS(10, 10);
    }

    rl.CloseWindow();
}
