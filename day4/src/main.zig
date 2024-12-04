const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const maxSize = 200;

fn readLetters(path: []const u8, letters: *[maxSize][maxSize]u8) usize {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    var row_index: usize = 0;
    while (file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxSize) catch {
        unreachable;
    }) |line| {
        defer allocator.free(line);
        for (line, 0..line.len) |c, i| letters[row_index][i] = c;
        row_index += 1;
    }
    return row_index;
}
const directions = [8][2]i32{
    [2]i32{ -1, -1 },
    [2]i32{ -1, 0 },
    [2]i32{ -1, 1 },
    [2]i32{ 0, -1 },
    [2]i32{ 0, 1 },
    [2]i32{ 1, -1 },
    [2]i32{ 1, 0 },
    [2]i32{ 1, 1 },
};

fn getChar(letters: [maxSize][maxSize]u8, size: usize, i: i32, j: i32) ?u8 {
    if (i < 0 or i >= size or j < 0 or j >= size) return null;
    return letters[@intCast(i)][@intCast(j)];
}

fn traversePartOne(letters: [maxSize][maxSize]u8, size: usize, i: usize, j: usize) u32 {
    if (letters[i][j] != 'X') return 0;

    var numOk: u32 = 0;
    for (directions) |dir| {
        var x: i32 = @intCast(i);
        var y: i32 = @intCast(j);
        numOk += for ("MAS") |c| {
            x += dir[0];
            y += dir[1];
            const gotC = getChar(letters, size, x, y);
            if (gotC == null or gotC.? != c) {
                break 0;
            }
        } else 1;
    }
    return numOk;
}

const diagonals = [4][2]i32{
    [2]i32{ -1, -1 },
    [2]i32{ -1, 1 },
    [2]i32{ 1, -1 },
    [2]i32{ 1, 1 },
};

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = std.process.argsAlloc(allocator) catch unreachable;
    defer {
        std.process.argsFree(allocator, args);
    }

    var letters: [maxSize][maxSize]u8 = .{.{'.'} ** maxSize} ** maxSize;
    const size = readLetters(args[1], &letters);

    // Part 1.
    {
        var numOk: u32 = 0;
        for (0..size) |i| {
            for (0..size) |j| {
                numOk += traversePartOne(letters, size, i, j);
            }
        }
        print("part 1: {d}\n", .{numOk});
    }

    // Part 2.
    {
        var numOk: u32 = 0;
        for (0..size) |i| {
            for (0..size) |j| {
                if (letters[i][j] != 'A') continue;

                var sumOfMx: i32 = 0;
                var sumOfMy: i32 = 0;
                var countM: u32 = 0;
                var countS: u32 = 0;
                for (diagonals) |d| {
                    const optC = getChar(letters, size, @as(i32, @intCast(i)) + d[0], @as(i32, @intCast(j)) + d[1]);
                    if (optC) |c| {
                        if (c == 'M') {
                            countM += 1;
                            sumOfMx += d[0];
                            sumOfMy += d[1];
                        }
                        if (c == 'S') countS += 1;
                    }
                }
                if (countM == 2 and countS == 2 and (sumOfMx != 0 or sumOfMy != 0)) numOk += 1;
            }
        }
        print("part 2: {d}\n", .{numOk});
    }
}
