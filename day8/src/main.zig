const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readMap(path: []const u8) ![][]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxNumLines = 10000;

    var r = std.ArrayList([]u8).init(allocator);
    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxNumLines)) |line| {
        try r.append(line);
    }
    return try r.toOwnedSlice();
}

fn addAntinodePt1(a: [2]i32, b: [2]i32, map: [][]u8, antinodes: *std.AutoHashMap([2]i32, void)) !void {
    const i = 2 * b[0] - a[0];
    const j = 2 * b[1] - a[1];
    if (i >= 0 and i < map.len and j >= 0 and j < map[@intCast(i)].len) {
        try antinodes.put(.{ i, j }, {});
    }
}

fn addAntinodePt2(a: [2]i32, b: [2]i32, map: [][]u8, antinodes: *std.AutoHashMap([2]i32, void)) !void {
    const di = a[0] - b[0];
    const dj = a[1] - b[1];
    if (dj == 0) {
        // It's a vertical line.
        for (0..map.len) |i| try antinodes.put(.{ @intCast(i), a[1] }, {});
    } else {
        for (0..map[0].len) |j| {
            const M = (@as(i32, @intCast(j)) - a[1]) * di;
            if (@mod(M, dj) == 0) {
                const i = @divExact(M, dj) + a[0];
                if (i >= 0 and i < map.len) {
                    try antinodes.put(.{ i, @as(i32, @intCast(j)) }, {});
                }
            }
        }
    }
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
    {
        var antennas = std.AutoHashMap(u8, std.ArrayList([2]i32)).init(allocator);
        defer {
            var it = antennas.valueIterator();
            while (it.next()) |v| v.deinit();
            antennas.deinit();
        }
        for (map, 0..) |line, i| {
            for (line, 0..) |c, j| {
                if (c == '.') continue;
                var v = try antennas.getOrPut(c);
                if (!v.found_existing) v.value_ptr.* = std.ArrayList([2]i32).init(allocator);
                try v.value_ptr.append(.{ @intCast(i), @intCast(j) });
            }
        }
        var it = antennas.valueIterator();
        var antinodes = std.AutoHashMap([2]i32, void).init(allocator);
        defer antinodes.deinit();
        while (it.next()) |points| {
            for (points.items, 0..) |a, indexa| {
                for (points.items[indexa + 1 ..]) |b| {
                    try addAntinodePt1(a, b, map, &antinodes);
                    try addAntinodePt1(b, a, map, &antinodes);
                }
            }
        }
        print("part 1: {d}\n", .{antinodes.count()});
    }

    // Part 2.
    {
        var antennas = std.AutoHashMap(u8, std.ArrayList([2]i32)).init(allocator);
        defer {
            var it = antennas.valueIterator();
            while (it.next()) |v| v.deinit();
            antennas.deinit();
        }
        for (map, 0..) |line, i| {
            for (line, 0..) |c, j| {
                if (c == '.') continue;
                var v = try antennas.getOrPut(c);
                if (!v.found_existing) v.value_ptr.* = std.ArrayList([2]i32).init(allocator);
                try v.value_ptr.append(.{ @intCast(i), @intCast(j) });
            }
        }
        var it = antennas.valueIterator();
        var antinodes = std.AutoHashMap([2]i32, void).init(allocator);
        defer antinodes.deinit();
        while (it.next()) |points| {
            for (points.items, 0..) |a, indexa| {
                for (points.items[indexa + 1 ..]) |b| {
                    try addAntinodePt2(a, b, map, &antinodes);
                }
            }
        }
        print("part 2: {d}\n", .{antinodes.count()});
    }
}
