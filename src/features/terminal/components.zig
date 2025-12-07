const std = @import("std");

const digger = @import("../digger/mod.zig");

const World = @import("ecs").World;
const Command = @import("../interpreter/command.zig").Command;

const QueryError = @import("ecs").World.QueryError;

pub const Terminal = struct {};
