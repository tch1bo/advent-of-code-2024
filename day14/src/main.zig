const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Robot = struct {
    x: i64,
    y: i64,
    vx: i64,
    vy: i64,
};

fn parseInts(line: []const u8, prefix: []const u8) ![2]i64 {
    const i = std.mem.indexOf(u8, line, prefix) orelse unreachable;
    const start1 = i + prefix.len;
    const end1 = std.mem.indexOfPos(u8, line, start1, ",") orelse unreachable;
    const start2 = end1 + 1;
    const end2 = std.mem.indexOfPos(u8, line, start2, " ") orelse line.len;
    return .{ try std.fmt.parseInt(i64, line[start1..end1], 10), try std.fmt.parseInt(i64, line[start2..end2], 10) };
}

fn readMap(path: []const u8) ![]Robot {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLen = 10000;
    var robots = std.ArrayList(Robot).init(allocator);

    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLen)) |line| {
        defer allocator.free(line);
        const x, const y = try parseInts(line, "p=");
        const vx, const vy = try parseInts(line, "v=");
        try robots.append(.{ .x = x, .y = y, .vx = vx, .vy = vy });
    }
    return robots.toOwnedSlice();
}

fn dims(input_file: []const u8) [2]i64 {
    if (std.mem.indexOf(u8, input_file, "example") != null) return .{ 7, 11 };
    return .{ 103, 101 };
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const robots = try readMap(args[1]);
    defer allocator.free(robots);

    const M, const N = dims(args[1]);
    // for (robots) |r| print("{any}\n", .{r});

    // Part 1.
    {
        const num_secs = 100;
        const halfM = @divFloor(M, 2);
        const halfN = @divFloor(N, 2);
        var q_sums: [4]u64 = .{0} ** 4;
        for (robots) |r| {
            const vx = if (r.vx >= 0) r.vx else N + r.vx;
            const vy = if (r.vy >= 0) r.vy else M + r.vy;

            const x = @mod(r.x + vx * num_secs, N);
            const y = @mod(r.y + vy * num_secs, M);

            if (y < halfM and x < halfN) {
                q_sums[0] += 1;
            } else if (y < halfM and x > halfN) {
                q_sums[1] += 1;
            } else if (y > halfM and x < halfN) {
                q_sums[2] += 1;
            } else if (y > halfM and x > halfN) {
                q_sums[3] += 1;
            }
        }
        var sum: u64 = 1;
        for (q_sums) |q| sum *= q;
        print("part 1: {d}\n", .{sum});
    }

    // Part 2.
    {
        const m = @as(usize, @intCast(M));
        const n = @as(usize, @intCast(N));
        var lines = try allocator.alloc([]u8, m);
        defer allocator.free(lines);
        for (0..m) |i| lines[i] = try allocator.alloc(u8, n);
        defer {
            for (0..m) |i| allocator.free(lines[i]);
        }
        const halfM = @divFloor(M, 2);
        const halfN = @divFloor(N, 2);
        const num_tiles_in_row = try allocator.alloc([2]u64, lines.len);
        defer allocator.free(num_tiles_in_row);
        for (0..10000000) |num_secs| {
            for (0..m) |i| {
                for (0..n) |j| lines[i][j] = ' ';
            }
            for (num_tiles_in_row) |*num| num.* = .{ 0, 0 };
            var q_sums: [4]u64 = .{0} ** 4;
            for (robots) |r| {
                const vx = if (r.vx >= 0) r.vx else N + r.vx;
                const vy = if (r.vy >= 0) r.vy else M + r.vy;

                const ns: i64 = @intCast(num_secs);
                const x = @mod(r.x + vx * ns, N);
                const y = @mod(r.y + vy * ns, M);

                const nr = &num_tiles_in_row[@as(usize, @intCast(y))];
                if (x < halfN) {
                    nr.*[0] += 1;
                } else if (x > halfN) {
                    nr.*[1] += 1;
                }

                lines[@as(usize, @intCast(y))][@as(usize, @intCast(x))] = '*';
                if (y < halfM and x < halfN) {
                    q_sums[0] += 1;
                } else if (y < halfM and x > halfN) {
                    q_sums[1] += 1;
                } else if (y > halfM and x < halfN) {
                    q_sums[2] += 1;
                } else if (y > halfM and x > halfN) {
                    q_sums[3] += 1;
                }
            }
            for (num_tiles_in_row) |nr| {
                if (nr[0] != nr[1]) break;
            } else {
                print("{d}\n", .{num_secs});
                for (lines) |line| print("{s}|\n", .{line});
                print("--------------------------------------------------------------------------------------------\n", .{});
            }
        }
        // print("part 1: {d}\n", .{sum});
    }
}
