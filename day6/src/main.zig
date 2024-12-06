const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readMap(path: []const u8) !std.ArrayList([]u8) {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxNumLines = 10000;

    var lines = std.ArrayList([]u8).init(allocator);
    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxNumLines)) |line| {
        try lines.append(line);
    }
    return lines;
}

const kMaxUsize = std.math.maxInt(usize);
const Direction = enum {
    kUp,
    kDown,
    kRight,
    kLeft,
};
const kAllDirections = [_]Direction{ Direction.kUp, Direction.kDown, Direction.kLeft, Direction.kRight };

fn getChar(map: *const std.ArrayList([]u8), pos: [2]i32) ?u8 {
    if (pos[0] < 0 or pos[1] < 0) return null;

    const i = @as(usize, @intCast(pos[0]));
    const j = @as(usize, @intCast(pos[1]));
    if (i >= map.items.len or j >= map.items[i].len) return null;
    return map.items[i][j];
}

fn switchDirection(direction: Direction) Direction {
    return switch (direction) {
        Direction.kUp => Direction.kRight,
        Direction.kDown => Direction.kLeft,
        Direction.kLeft => Direction.kUp,
        Direction.kRight => Direction.kDown,
    };
}

fn makeStep(pos: [2]i32, direction: Direction) [2]i32 {
    return switch (direction) {
        Direction.kUp => .{ pos[0] - 1, pos[1] },
        Direction.kDown => .{ pos[0] + 1, pos[1] },
        Direction.kLeft => .{ pos[0], pos[1] - 1 },
        Direction.kRight => .{ pos[0], pos[1] + 1 },
    };
}

const PointAndDir = struct {
    p: [2]i32,
    d: Direction,
};

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const map = try readMap(args[1]);
    defer {
        for (map.items) |l| allocator.free(l);
        map.deinit();
    }

    var start_pos: [2]i32 = undefined;
    var start_dir: Direction = Direction.kDown;
    const found_start = outer: for (map.items, 0..) |line, i| {
        for (line, 0..) |c, j| {
            switch (c) {
                '^' => start_dir = Direction.kUp,
                '>' => start_dir = Direction.kRight,
                'v' => start_dir = Direction.kDown,
                '<' => start_dir = Direction.kLeft,
                else => continue,
            }
            start_pos = .{ @intCast(i), @intCast(j) };
            break :outer true;
        }
    } else false;
    if (!found_start) @panic("start not found");

    var visited = std.AutoHashMap([2]i32, void).init(allocator);
    defer visited.deinit();

    // Part 1.
    {
        var p = start_pos;
        var d = start_dir;
        while (true) {
            try visited.put(p, {});

            const next_pos = makeStep(p, d);
            if (getChar(&map, next_pos)) |c| {
                if (c == '#') {
                    d = switchDirection(d);
                } else {
                    p = next_pos;
                }
            } else {
                break;
            }
        }
    }
    print("part 1: {d}\n", .{visited.count()});

    // Part 2.
    {
        var blocks_to_try = std.AutoHashMap([2]i32, void).init(allocator);
        defer blocks_to_try.deinit();
        {
            var it = visited.keyIterator();
            while (it.next()) |p| {
                for (kAllDirections) |d| {
                    const block = makeStep(p.*, d);
                    if (visited.contains(block)) {
                        try blocks_to_try.put(block, {});
                    }
                }
            }
        }

        var it = blocks_to_try.keyIterator();
        var sum : u32 = 0;
        while (it.next()) |block| {
            var visitedPAndD = std.AutoHashMap(PointAndDir, void).init(allocator);
            defer visitedPAndD.deinit();

            const pi = @as(usize, @intCast(block[0]));
            const pj = @as(usize, @intCast(block[1]));
            map.items[pi][pj] = '#';

            var p = start_pos;
            var d = start_dir;
            sum += while (true) {
                const p_and_d = PointAndDir{ .d = d, .p = p };
                if (visitedPAndD.contains(p_and_d)) {
                    // Completed the loop.
                    break 1;
                }
                try visitedPAndD.put(p_and_d, {});

                const next_pos = makeStep(p, d);

                if (getChar(&map, next_pos)) |c| {
                    if (c == '#') {
                        d = switchDirection(d);
                    } else {
                        p = next_pos;
                    }
                } else {
                    break 0;
                }
            };
            map.items[pi][pj] = '.';
        }
        print("part 2: {d}\n", .{sum});
    }
}
