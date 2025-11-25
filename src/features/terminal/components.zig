const std = @import("std");

const digger = @import("../digger/mod.zig");

const World = @import("ecs").World;
const Interpreter = @import("../interpreter/Interpreter.zig");
const Command = Interpreter.Command;

pub const Terminal = struct {};

/// All commands will be executed in FIFO order
pub const CommandExecutor = struct {
    queue: Queue,
    alloc: std.mem.Allocator,
    /// The timestamp of the previous command execution
    /// in miliseconds.
    /// The timer is started from the first commmands is added.
    timer: ?std.time.Timer = null,
    is_running: bool = false,

    const Queue = std.SinglyLinkedList;
    const Item = struct {
        data: Command,
        node: Queue.Node = .{},
    };

    pub fn init(alloc: std.mem.Allocator) CommandExecutor {
        return .{
            .queue = .{},
            .alloc = alloc,
        };
    }

    /// Drain nodes in the queue.
    pub fn denit(self: *CommandExecutor, _: std.mem.Allocator) void {
        while (self.dequeue()) |node| {
            self.removeNode(node);
        }
    }

    pub fn enqueue(self: *CommandExecutor, cmd: Command) !void {
        const it = try self.alloc.create(Item);
        errdefer self.alloc.destroy(it);
        it.* = .{ .data = cmd };

        if (self.queue.first == null) {
            self.is_running = true;
            self.timer = try .start();
            self.queue.first = &it.node;
        } else {
            var curr_node = self.queue.first.?;
            while (curr_node.next != null) {
                curr_node = curr_node.next.?;
            }

            curr_node.insertAfter(&it.node);
        }
    }

    /// Remove and return the first node in the queue.
    pub fn dequeue(self: *CommandExecutor) ?Command {
        const node = self.queue.popFirst() orelse return null;
        const item: *Item = @fieldParentPtr("node", node);
        const command = item.data;
        self.alloc.destroy(item);
        return command;
    }

    /// Execute next command in the queue in a duration
    pub fn execNext(
        self: *CommandExecutor,
        w: *World,
        /// (miliseconds)
        duration: u64,
    ) !void {
        if (self.timer) |*timer| {
            const target_ns = duration * std.time.ns_per_ms;
            const lap = timer.read();

            if (lap > target_ns) {
                if (self.dequeue()) |command| {
                    timer.reset();

                    try self.handleNode(w, command);
                } else {
                    self.timer = null;
                    self.is_running = false;
                }
            }
        }
    }

    fn handleNode(self: *CommandExecutor, w: *World, command: Command) !void {
        switch (command) {
            .move => |direction| try digger.move.control(w, direction),
            .@"if" => self.*.hanldeIfStatement(command),
        }
    }

    /// Remove all the commands of the `if` statement in the queue if
    /// the condition value is `false`.
    fn hanldeIfStatement(self: *CommandExecutor, if_command: Command) void {
        const info = if_command.@"if";
        if (info.num_of_cmds <= 0) return;
        var idx: usize = 1;

        if (!info.condition_value) {
            var curr_node = self.dequeue();
            while (curr_node != null and idx < info.num_of_cmds) {
                curr_node = self.dequeue();
                idx += 1;
            }
        }
    }
};
