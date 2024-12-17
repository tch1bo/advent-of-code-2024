const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readMap(path: []const u8) ![][]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLen = 10000;

    var r = std.ArrayList([]u8).init(allocator);

    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLen)) |line| {
        try r.append(line);
    }
    return r.toOwnedSlice();
}

fn getSteps(map: [][]u8, i: usize, j: usize) ![][2]usize {
    var steps = std.ArrayList([2]usize).init(allocator);
    if (i > 0) try steps.append(.{ i - 1, j });
    if (i + 1 < map.len) try steps.append(.{ i + 1, j });
    if (j > 0) try steps.append(.{ i, j - 1 });
    if (j + 1 < map[0].len) try steps.append(.{ i, j + 1 });
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
    var segment_map = try allocator.alloc([]usize, map.len);
    for (0..map.len) |i| {
        var s = try allocator.alloc(usize, map[0].len);
        for (0..map[0].len) |j| s[j] = std.math.maxInt(usize);
        segment_map[i] = s;
    }
    defer {
        for (map) |line| allocator.free(line);
        allocator.free(map);

        for (segment_map) |line| allocator.free(line);
        allocator.free(segment_map);
    }

    var num_segments: usize = 0;

    // Compute the segments.
    var stack = std.ArrayList([2]usize).init(allocator);
    defer stack.deinit();
    try stack.append(.{ 0, 0 });
    while (stack.popOrNull()) |cur| {
        const i, const j = cur;

        const steps = try getSteps(map, i, j);
        defer allocator.free(steps);
        var s = segment_map[i][j];

        for (steps) |step| {
            const si, const sj = step;
            if (map[si][sj] == map[i][j]) {
                s = @min(s, segment_map[si][sj]);
            }
        }
        if (s == std.math.maxInt(usize)) {
            s = num_segments;
            num_segments += 1;
        }
        segment_map[i][j] = s;

        for (steps) |step| {
            const si, const sj = step;
            if (map[si][sj] != map[i][j]) {
                if (segment_map[si][sj] == std.math.maxInt(usize)) try stack.append(.{ si, sj });
            } else {
                if (segment_map[si][sj] > s) try stack.append(.{ si, sj });
            }
        }
    }

    const areas = try allocator.alloc(u64, num_segments);
    @memset(areas, 0);
    defer allocator.free(areas);

    const top_left = try allocator.alloc([2]usize, num_segments);
    for (top_left) |*x| x.* = .{ std.math.maxInt(usize), std.math.maxInt(usize) };
    defer allocator.free(top_left);

    {
        const perims = try allocator.alloc(u64, num_segments);
        @memset(perims, 0);
        defer allocator.free(perims);

        for (0..map.len) |i| {
            for (0..map[0].len) |j| {
                const s = segment_map[i][j];
                areas[s] += @as(u64, 1);

                const ci, const cj = top_left[s];
                if (i < ci or (i == ci and j < cj)) top_left[s] = .{ i, j };

                var p: u64 = 4;
                const steps = try getSteps(map, i, j);
                defer allocator.free(steps);
                for (steps) |step| {
                    const si, const sj = step;
                    if (segment_map[si][sj] == s) p -= 1;
                }
                perims[s] += p;
            }
        }

        var sum: u64 = 0;
        for (0..num_segments) |i| {
            // print("{d} {d}\n", .{ areas[i], perims[i] });
            sum += areas[i] * perims[i];
        }
        print("part 1: {d}\n", .{sum});
    }

    // for (segment_map) |l| print("{d}\n", .{l});
    // {
    //     for (0..num_segments) |s| {
    //         if (areas[s] == 0) continue;

    //         print("{d}\n", .{s});
    //         print("-----------------------------------\n", .{});
    //     }

    // var sum: u64 = 0;
    // for (0..num_segments) |i| {
    //     print("{d} {d}\n", .{ areas[i], num_walls[i] });
    //     sum += areas[i] * num_walls[i];
    // }
    // print("part 2: {d}\n", .{sum});
    // }
}
