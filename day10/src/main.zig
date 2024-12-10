const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const maxSize = 100;
fn readMap(path: []const u8) ![][]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    var r = std.ArrayList([]u8).init(allocator);

    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxSize)) |line| {
        try r.append(line);
    }
    return try r.toOwnedSlice();
}

const kDirections = [4][2]i64{
    .{ -1, 0 },
    .{ 1, 0 },
    .{ 0, -1 },
    .{ 0, 1 },
};

fn makeSteps(i: usize, j: usize, map: [][]u8) ![][2]usize {
    var steps = std.ArrayList([2]usize).init(allocator);
    for (kDirections) |d| {
        const di: i64 = @as(i64, @intCast(i)) + d[0];
        const dj: i64 = @as(i64, @intCast(j)) + d[1];
        if (di >= 0 and di < map.len and dj >= 0 and dj < map[0].len) {
            try steps.append(.{ @intCast(di), @intCast(dj) });
        }
    }
    return steps.toOwnedSlice();
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
        for (map) |line| allocator.free(line);
        allocator.free(map);
    }

    // Part 1.
    {
        var sum: u32 = 0;
        var visited = std.mem.zeroes([maxSize][maxSize]bool);
        for (map, 0..) |line, i| {
            for (line, 0..) |c, j| {
                if (c != '0') continue;

                var q = std.ArrayList([2]usize).init(allocator);
                defer q.deinit();

                visited = std.mem.zeroes([maxSize][maxSize]bool);
                try q.append(.{ i, j });
                var q_top: usize = 0;
                while (q_top < q.items.len) {
                    const pi, const pj = q.items[q_top];
                    q_top += 1;
                    if (visited[pi][pj]) continue;

                    visited[pi][pj] = true;
                    // print("{d} {d}\n", .{pi, pj});
                    if (map[pi][pj] == '9') {
                        sum += 1;
                        continue;
                    }

                    const steps = try makeSteps(pi, pj, map);
                    defer allocator.free(steps);
                    for (steps) |s| {
                        if (map[s[0]][s[1]] == map[pi][pj] + 1) try q.append(s);
                    }
                }
            }
        }
        print("part 1: {d}\n", .{sum});
    }

    // Part 2.
    {
        var sum: u32 = 0;
        var num_paths = std.mem.zeroes([maxSize][maxSize]u32);
        for (map, 0..) |line, i| {
            for (line, 0..) |c, j| {
                if (c != '0') continue;

                num_paths = std.mem.zeroes([maxSize][maxSize]u32);
                num_paths[i][j] = 1;

                var cur_list = std.ArrayList([2]usize).init(allocator);
                defer cur_list.deinit();

                try cur_list.append(.{ i, j });
                var cur_char: u8 = '0';
                while (cur_list.items.len != 0 and cur_char <= '9') {
                    var new_items = std.AutoHashMap([2]usize, void).init(allocator);
                    defer new_items.deinit();

                    for (cur_list.items) |p| {
                        const pi, const pj = p;
                        if (cur_char == '9') {
                            sum += num_paths[pi][pj];
                        } else {
                            const steps = try makeSteps(pi, pj, map);
                            defer allocator.free(steps);
                            for (steps) |s| {
                                const si, const sj = s;
                                if (map[si][sj] == cur_char + 1) {
                                    num_paths[si][sj] += num_paths[pi][pj];
                                    try new_items.put(.{ si, sj }, {});
                                }
                            }
                        }
                    }
                    cur_char += 1;
                    cur_list.shrinkRetainingCapacity(0);
                    var it = new_items.keyIterator();
                    while (it.next()) |s| try cur_list.append(s.*);
                }
            }
        }
        print("part 2: {d}\n", .{sum});
    }
}
