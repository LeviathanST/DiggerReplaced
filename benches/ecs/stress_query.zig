const std = @import("std");
const ecs = @import("ecs");

pub const std_options: std.Options = .{
    .log_level = .err,
};

fn stressQuery(allocator: std.mem.Allocator) void {
    const Position = struct {
        x: i32,
        y: i32,
    };
    const Velocity = struct {
        x: f32,
        y: f32,
    };
    const Weapon = struct {
        name: []const u8,
        dmg: i32,
    };

    var w: ecs.World = .init(allocator);
    defer w.deinit();

    for (0..1000) |_| {
        _ = w.spawnEntity(&.{ Position, Velocity }, .{ .{ .x = 1, .y = 1 }, .{ .x = 0.0, .y = 0.0 } });
        _ = w.spawnEntity(&.{ Position, Weapon }, .{ .{ .x = 1, .y = 1 }, .{ .name = "Sword", .dmg = 6 } });
    }

    _ = w.query(&.{Weapon}) catch unreachable;
    _ = w.query(&.{ Weapon, Velocity }) catch unreachable;
    _ = w.query(&.{ Position, Velocity }) catch unreachable;
    _ = w.query(&.{Position}) catch unreachable;
}

pub fn main() !void {
    var base_alloc = std.heap.DebugAllocator(.{}).init;
    defer {
        if (base_alloc.deinit() == .leak) @panic("Leak memory have been detected in ECS stress query benchmark!");
    }
    const alloc = base_alloc.allocator();
    stressQuery(alloc);
}
