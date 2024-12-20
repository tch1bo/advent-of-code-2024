const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readMap(path: []const u8) ![][]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLen = 10000;

    var lines = std.ArrayList([]u8).init(allocator);
    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLen)) |line| {
        try lines.append(line);
    }
    return lines.toOwnedSlice();
}

const kEast: usize = 0;
const kWest: usize = 1;
const kNorth: usize = 2;
const kSouth: usize = 3;
const kNumDirections: usize = 4;

fn rotate(d: usize) [2]usize {
    if (d == kEast or d == kWest) return .{ kNorth, kSouth };
    if (d == kNorth or d == kSouth) return .{ kEast, kWest };

    unreachable;
}

fn neighbour(i: usize, j: usize, d: usize) [2]usize {
    return switch (d) {
        kNorth => .{ i - 1, j },
        kSouth => .{ i + 1, j },
        kWest => .{ i, j - 1 },
        kEast => .{ i, j + 1 },
        else => unreachable,
    };
}

fn revNeighbour(i: usize, j: usize, d: usize) [2]usize {
    return switch (d) {
        kNorth => .{ i + 1, j },
        kSouth => .{ i - 1, j },
        kWest => .{ i, j + 1 },
        kEast => .{ i, j - 1 },
        else => unreachable,
    };
}

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

    // Part 1.
    const cost = try allocator.alloc([][kNumDirections]u64, map.len);
    var to_visit = std.AutoHashMap([3]usize, void).init(allocator);
    for (0..map.len) |i| {
        cost[i] = try allocator.alloc([kNumDirections]u64, map[0].len);
        for (cost[i]) |*c| {
            for (0..kNumDirections) |d| c.*[d] = std.math.maxInt(u64);
        }
    }
    defer {
        for (cost) |c| allocator.free(c);
        allocator.free(cost);
        to_visit.deinit();
    }

    const si: usize, const sj: usize = .{ map.len - 2, 1 };
    if (map[si][sj] != 'S') @panic("wrong position");

    const ei: usize, const ej: usize = .{ 1, map[0].len - 2 };
    if (map[ei][ej] != 'E') @panic("wrong position");

    cost[si][sj][kEast] = 0;

    for (0..map.len) |i| {
        for (0..map[0].len) |j| {
            if (map[i][j] == '#') continue;
            for (0..kNumDirections) |d| {
                try to_visit.put(.{ i, j, d }, {});
            }
        }
    }

    while (to_visit.count() > 0) {
        var cur: [3]usize = undefined;
        var mincost: u64 = std.math.maxInt(u64);
        var it = to_visit.keyIterator();
        while (it.next()) |k| {
            const i, const j, const d = k.*;
            if (mincost > cost[i][j][d]) {
                mincost = cost[i][j][d];
                cur = k.*;
            }
        }
        // print("{d} {d}\n", .{cur, mincost});
        if (mincost == std.math.maxInt(u64)) break;

        _ = to_visit.remove(cur);

        const i, const j, const d = cur;
        for (rotate(d)) |r| {
            const oldcost = cost[i][j][r];
            const newcost = cost[i][j][d] + 1000;
            if (oldcost > newcost) cost[i][j][r] = newcost;
        }

        const ni, const nj = neighbour(i, j, d);
        if (map[ni][nj] == '#') continue;

        const oldcost = cost[ni][nj][d];
        const newcost = cost[i][j][d] + 1;
        if (oldcost > newcost) cost[ni][nj][d] = newcost;
    }

    const ed = std.mem.indexOfMin(u64, &cost[ei][ej]);
    print("part 1: {d}\n", .{cost[ei][ej][ed]});

    // Part 2.
    var visited = std.AutoHashMap([3]usize, void).init(allocator);
    defer visited.deinit();

    var stack = std.ArrayList([3]usize).init(allocator);
    defer stack.deinit();

    try stack.append(.{ ei, ej, ed });
    while (stack.items.len > 0) {
        const i, const j, const d = stack.pop();
        if ((try visited.getOrPut(.{ i, j, d })).found_existing) continue;

        const c = cost[i][j][d];
        for (rotate(d)) |r| {
            if (c == cost[i][j][r] + 1000) try stack.append(.{ i, j, r });
        }

        const ni, const nj = revNeighbour(i, j, d);
        if (map[ni][nj] != '#' and c == cost[ni][nj][d] + 1) try stack.append(.{ ni, nj, d });
    }

    var visited_tiles = std.AutoHashMap([2]usize, void).init(allocator);
    defer visited_tiles.deinit();
    var it = visited.keyIterator();
    while (it.next()) |k| {
        const i, const j, _ = k.*;
        try visited_tiles.put(.{ i, j }, {});
    }
    print("part 2: {d}\n", .{visited_tiles.count()});
}
