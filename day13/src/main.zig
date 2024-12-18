const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Task = struct { ax: i64, ay: i64, bx: i64, by: i64, px: i64, py: i64 };

fn parseInt(line: []const u8, prefix: []const u8) !i64 {
    const i = std.mem.indexOf(u8, line, prefix) orelse unreachable;
    const start = i + prefix.len;
    const end = std.mem.indexOfPos(u8, line, start, ",") orelse line.len;
    return try std.fmt.parseInt(i64, line[start..end], 10);
}

fn readTasks(path: []const u8) ![]Task {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLen = 1000;

    var r = std.ArrayList(Task).init(allocator);
    var t = Task{ .ax = 0, .ay = 0, .bx = 0, .by = 0, .px = 0, .py = 0 };
    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLen)) |line| {
        defer allocator.free(line);

        if (std.mem.startsWith(u8, line, "Button A:")) {
            t.ax = try parseInt(line, "X+");
            t.ay = try parseInt(line, "Y+");
        } else if (std.mem.startsWith(u8, line, "Button B:")) {
            t.bx = try parseInt(line, "X+");
            t.by = try parseInt(line, "Y+");
        } else if (std.mem.startsWith(u8, line, "Prize:")) {
            t.px = try parseInt(line, "X=");
            t.py = try parseInt(line, "Y=");
            try r.append(t);
        }
    }

    return try r.toOwnedSlice();
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const tasks = try readTasks(args[1]);
    defer allocator.free(tasks);

    // Part 1.
    {
        var sum: i64 = 0;
        for (tasks) |t| {
            const det = (t.ax * t.by) - (t.ay * t.bx);
            if (det == 0) unreachable;
            const adet = t.px * t.by - t.py * t.bx;
            const bdet = t.ax * t.py - t.ay * t.px;
            if (@mod(adet, det) == 0 and @mod(bdet, det) == 0) {
                const tokens = @divExact(adet, det) * 3 + @divExact(bdet, det) * 1;
                sum += tokens;
            }
        }
        print("part 1: {d}\n", .{sum});
    }

    // Part 2.
    {
        var sum: i64 = 0;
        for (tasks) |t| {
            const det = (t.ax * t.by) - (t.ay * t.bx);
            if (det == 0) unreachable;
            const px = t.px + 10000000000000;
            const py = t.py + 10000000000000;
            const adet = px * t.by - py * t.bx;
            const bdet = t.ax * py - t.ay * px;
            if (@mod(adet, det) == 0 and @mod(bdet, det) == 0) {
                const tokens = @divExact(adet, det) * 3 + @divExact(bdet, det) * 1;
                sum += tokens;
            }
        }
        print("part 2: {d}\n", .{sum});
    }
}
