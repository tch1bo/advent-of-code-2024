const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readMapAndMoves(path: []const u8) !struct { [][]u8, []u8 } {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLen = 10000;
    var map = std.ArrayList([]u8).init(allocator);
    var directions = std.ArrayList(u8).init(allocator);

    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLen)) |line| {
        if (line.len == 0) {
            allocator.free(line);
        } else if (line[0] == '#') {
            try map.append(line);
        } else {
            for (line) |c| {
                if (c == '<' or c == '>' or c == 'v' or c == '^') try directions.append(c);
            }
            allocator.free(line);
        }
    }
    return .{ try map.toOwnedSlice(), try directions.toOwnedSlice() };
}

fn findRobot(map: [][]u8) [2]usize {
    for (0..map.len) |i| {
        for (0..map[0].len) |j| {
            if (map[i][j] == '@') {
                return .{ i, j };
            }
        }
    }
    unreachable;
}

fn step(i: usize, j: usize, d: u8) [2]usize {
    return switch (d) {
        '<' => .{ i, j - 1 },
        '>' => .{ i, j + 1 },
        '^' => .{ i - 1, j },
        'v' => .{ i + 1, j },
        else => unreachable,
    };
}

fn move(map: [][]u8, ri: *usize, rj: *usize, d: u8) void {
    var i, var j = step(ri.*, rj.*, d);
    while (true) {
        if (map[i][j] == '#' or map[i][j] == '.') break;
        i, j = step(i, j, d);
    }
    if (map[i][j] == '.') {
        map[ri.*][rj.*] = '.';
        ri.*, rj.* = step(ri.*, rj.*, d);
        if (map[ri.*][rj.*] == 'O') map[i][j] = 'O';
        map[ri.*][rj.*] = '@';
    }
}

fn move2(map: [][]u8, ri: *usize, rj: *usize, d: u8) !void {
    if (d == '<' or d == '>') {
        const i = ri.*;
        _, var j = step(i, rj.*, d);
        while (map[i][j] == '[' or map[i][j] == ']') _, j = step(i, j, d);
        if (map[i][j] == '#') return;

        const revd: u8 = if (d == '>') '<' else '>';
        while (j != rj.*) {
            _, const nj = step(i, j, revd);
            map[i][j] = map[i][nj];
            j = nj;
        }
        map[i][rj.*] = '.';
        _, rj.* = step(i, rj.*, d);
    } else {
        var needs_to_be_free = std.ArrayList(std.ArrayList(usize)).init(allocator);
        defer {
            for (needs_to_be_free.items) |x| x.deinit();
            needs_to_be_free.deinit();
        }

        const j = rj.*;
        try needs_to_be_free.append(std.ArrayList(usize).init(allocator));
        var cur = &needs_to_be_free.items[needs_to_be_free.items.len - 1];
        try cur.append(j);

        var i, _ = step(ri.*, j, d);
        while (true) {
            try needs_to_be_free.append(std.ArrayList(usize).init(allocator));
            var next = &needs_to_be_free.items[needs_to_be_free.items.len - 1];
            cur = &needs_to_be_free.items[needs_to_be_free.items.len - 2];
            for (cur.items) |n| {
                const c = map[i][n];
                if (c == '.') {
                    continue;
                } else if (c == '#') {
                    // Not possible to move the boxes, keep everything as is.
                    return;
                } else {
                    try next.append(n);
                    if (c == ']') {
                        try next.append(n - 1);
                    } else {
                        try next.append(n + 1);
                    }
                }
            }
            if (cur.items.len == 0) break;
            i, _ = step(i, j, d);
        }

        const revd: u8 = if (d == 'v') '^' else 'v';
        var row = needs_to_be_free.items.len - 2;
        while (i != ri.*) {
            const ni, _ = step(i, j, revd);
            for (needs_to_be_free.items[row].items) |n| map[i][n] = map[ni][n];
            for (needs_to_be_free.items[row].items) |n| map[ni][n] = '.';
            i = ni;
            if (i != ri.*) row -= 1;
        }
        map[ri.*][j] = '.';
        ri.*, _ = step(i, j, d);
    }
}

fn expandMap(map: [][]u8) ![][]u8 {
    const newmap = try allocator.alloc([]u8, map.len);
    for (map, 0..) |line, i| {
        newmap[i] = try allocator.alloc(u8, line.len * 2);
        const l = newmap[i];
        for (line, 0..) |c, j| {
            switch (c) {
                '#' => {
                    l[2 * j] = '#';
                    l[2 * j + 1] = '#';
                },
                'O' => {
                    l[2 * j] = '[';
                    l[2 * j + 1] = ']';
                },
                '.' => {
                    l[2 * j] = '.';
                    l[2 * j + 1] = '.';
                },
                '@' => {
                    l[2 * j] = '@';
                    l[2 * j + 1] = '.';
                },
                else => unreachable,
            }
        }
    }
    return newmap;
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Part 1.
    {
        const map, const directions = try readMapAndMoves(args[1]);
        defer {
            allocator.free(directions);
            for (map) |line| allocator.free(line);
            allocator.free(map);
        }
        var ri, var rj = findRobot(map);
        var sum: usize = 0;
        for (directions) |d| move(map, &ri, &rj, d);
        for (map, 0..) |line, i| {
            for (line, 0..) |c, j| {
                if (c == 'O') {
                    sum += i * 100 + j;
                }
            }
        }
        print("part 1: {d}\n", .{sum});
    }

    // Part 2.
    {
        const map, const directions = try readMapAndMoves(args[1]);
        defer {
            allocator.free(directions);
            for (map) |line| allocator.free(line);
            allocator.free(map);
        }
        // const newmap = map; //try expandMap(map);
        const newmap = try expandMap(map);
        defer {
            for (newmap) |line| allocator.free(line);
            allocator.free(newmap);
        }
        var ri, var rj = findRobot(newmap);
        var sum: usize = 0;
        for (directions) |d| {
            try move2(newmap, &ri, &rj, d);
        }
        for (newmap, 0..) |line, i| {
            for (line, 0..) |c, j| {
                if (c == '[') {
                    sum += i * 100 + j;
                }
            }
        }
        print("part 2: {d}\n", .{sum});
    }
}
