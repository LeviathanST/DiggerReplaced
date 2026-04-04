const std = @import("std");
const ecs = @import("ecs");

pub const std_options: std.Options = .{
    .log_level = .err,
};

fn query(allocator: std.mem.Allocator) void {
    const Position = struct {
        x: i32,
        y: i32,
    };
    const Weapon = struct {
        name: []const u8,
        dmg: i32,
    };

    var w: ecs.World = .init(allocator);
    defer w.deinit();

    _ = w.spawnEntity(&.{Position}, .{.{ .x = 1, .y = 1 }});
    _ = w.spawnEntity(&.{ Position, Weapon }, .{ .{ .x = 1, .y = 1 }, .{ .name = "Sword", .dmg = 6 } });

    _ = w.query(&.{Weapon}) catch unreachable;
}

pub fn main() !void {
    var base_alloc = std.heap.DebugAllocator(.{}).init;
    defer {
        if (base_alloc.deinit() == .leak) @panic("Leak memory have been detected in ECS query benchmark!");
    }
    const alloc = base_alloc.allocator();
    query(alloc);
}
