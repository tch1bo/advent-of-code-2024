const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readMap(path: []const u8) ![][]const u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLen = 10000;
    var r = std.ArrayList([]const u8).init(allocator);

    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLen)) |line| {
        try r.append(line);
    }
    return r.toOwnedSlice();
}

fn find_tile(map: [][]const u8, tile: u8) [2]usize {
    for (map, 0..) |line, i| {
        for (line, 0..) |c, j| {
            if (c == tile) return .{ i, j };
        }
    }
    unreachable;
}

fn neighbours(map: [][]const u8, i: usize, j: usize) ![][2]usize {
    var r = std.ArrayList([2]usize).init(allocator);
    const undef = .{ std.math.maxInt(usize), std.math.maxInt(usize) };
    if (i > 0) try r.append(.{ i - 1, j }) else try r.append(undef);
    if (i + 1 < map.len) try r.append(.{ i + 1, j }) else try r.append(undef);
    if (j > 0) try r.append(.{ i, j - 1 }) else try r.append(undef);
    if (j + 1 < map[0].len) try r.append(.{ i, j + 1 }) else try r.append(undef);
    return try r.toOwnedSlice();
}

fn bfs(map: [][]const u8, p: [2]usize) !std.AutoHashMap([2]usize, u64) {
    var q = std.ArrayList([2]u64).init(allocator);
    defer q.deinit();
    var dist = std.AutoHashMap([2]usize, u64).init(allocator);
    var qi: usize = 0;
    try q.append(p);
    try dist.put(q.items[0], 0);
    while (qi < q.items.len) {
        const i, const j = q.items[qi];
        const d = dist.get(q.items[qi]).?;
        qi += 1;

        const ns = try neighbours(map, i, j);
        defer allocator.free(ns);
        for (ns) |n| {
            const ni, const nj = n;
            if (map[ni][nj] == '#') continue;
            const it = try dist.getOrPut(n);
            if (it.found_existing) continue;
            it.value_ptr.* = d + 1;
            try q.append(n);
        }
    }
    return dist;
}

const cheat_duration: usize = 20;

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const map = try readMap(args[1]);
    defer {
        for (map) |l| allocator.free(l);
        allocator.free(map);
    }

    const si, const sj = find_tile(map, 'S');
    const ei, const ej = find_tile(map, 'E');

    var dist_from_end = try bfs(map, .{ ei, ej });
    defer dist_from_end.deinit();

    var dist_from_start = try bfs(map, .{ si, sj });
    defer dist_from_start.deinit();

    var reachable_tiles = std.ArrayList([2]usize).init(allocator);
    defer reachable_tiles.deinit();
    var it = dist_from_start.iterator();
    while (it.next()) |item| {
        const d_to_end = dist_from_end.get(item.key_ptr.*);
        if (d_to_end != null) try reachable_tiles.append(item.key_ptr.*);
    }

    var cheats = std.AutoHashMap(u64, u64).init(allocator);
    defer cheats.deinit();

    for (reachable_tiles.items) |p1| {
        for (reachable_tiles.items) |p2| {
            const ia, const ja = p1;
            const ib, const jb = p2;
            const d = @as(usize, @abs(@as(i64, @intCast(ia)) - @as(i64, @intCast(ib))) +
                @abs(@as(i64, @intCast(ja)) - @as(i64, @intCast(jb))));
            if (d > cheat_duration) continue;

            const old_time = dist_from_end.get(p1).?;
            const new_time = d + dist_from_end.get(p2).?;
            if (old_time > new_time) {
                const saved = old_time - new_time;
                const c = try cheats.getOrPut(saved);
                if (!c.found_existing) c.value_ptr.* = 0;
                c.value_ptr.* += 1;
            }
        }
    }
    var sum: u64 = 0;
    var it2 = cheats.iterator();
    while (it2.next()) |item| {
        if (item.key_ptr.* >= 100) sum += item.value_ptr.*;
    }
    print("{d}\n", .{sum});
}
