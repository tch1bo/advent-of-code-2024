const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readPairs(path: []const u8) ![][2]usize {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLen = 10000;

    var r = std.ArrayList([2]usize).init(allocator);
    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLen)) |line| {
        defer allocator.free(line);
        var nums: [2]usize = undefined;
        var it = std.mem.splitSequence(u8, line, ",");
        nums[0] = try std.fmt.parseInt(usize, it.next().?, 10);
        nums[1] = try std.fmt.parseInt(usize, it.next().?, 10);
        try r.append(nums);
    }
    return try r.toOwnedSlice();
}

// const SIZE: usize = 7;
// const num_bytes_to_simulate: usize = 12;
const SIZE: usize = 71;
const num_bytes_to_simulate: usize = 1024;

fn neighbours(i: usize, j: usize) ![][2]usize {
    var r = std.ArrayList([2]usize).init(allocator);
    if (i > 0) try r.append(.{ i - 1, j });
    if (i + 1 < SIZE) try r.append(.{ i + 1, j });
    if (j > 0) try r.append(.{ i, j - 1 });
    if (j + 1 < SIZE) try r.append(.{ i, j + 1 });
    return try r.toOwnedSlice();
}

fn populate(map: *[SIZE][SIZE]u8, pairs: [][2]usize) void {
    for (pairs) |p| map[p[1]][p[0]] = '#';
}

fn calc_dist(map: [SIZE][SIZE]u8) !?u64 {
    var q = std.ArrayList([2]u64).init(allocator);
    defer q.deinit();
    var dist = std.AutoHashMap([2]usize, u64).init(allocator);
    defer dist.deinit();
    var qi: usize = 0;
    try q.append(.{ 0, 0 });
    try dist.put(q.items[0], 0);
    while (qi < q.items.len) {
        const i, const j = q.items[qi];
        const d = dist.get(q.items[qi]).?;
        qi += 1;

        const ns = try neighbours(i, j);
        defer allocator.free(ns);
        for (ns) |n| {
            const ni, const nj = n;
            if (map[ni][nj] == '#') continue;
            const it = try dist.getOrPut(n);
            if (it.found_existing) continue;
            if (ni == SIZE - 1 and nj == SIZE - 1) return d + 1;
            it.value_ptr.* = d + 1;
            try q.append(n);
        }
    }
    return null;
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const pairs = try readPairs(args[1]);
    defer allocator.free(pairs);

    // Part 1.
    {
        var map = std.mem.zeroes([SIZE][SIZE]u8);
        populate(&map, pairs[0..num_bytes_to_simulate]);
        const d = try calc_dist(map);
        print("part 1: {d}\n", .{d.?});
    }

    // Part 2.
    {
        var lower = num_bytes_to_simulate;
        var upper = pairs.len - 1;
        while (lower + 1 < upper) {
            const mid = lower + @divFloor(upper - lower, 2);
            var map = std.mem.zeroes([SIZE][SIZE]u8);
            populate(&map, pairs[0 .. mid + 1]);
            const d = try calc_dist(map);
            if (d == null) {
                upper = mid;
            } else {
                lower = mid;
            }
            print("{d} {d} {d} {?}\n", .{lower, mid, upper, d});
        }

        print("{d} {d}\n", .{lower, upper});
        print("part 2: {d}\n", .{pairs[upper]});
    }
}
