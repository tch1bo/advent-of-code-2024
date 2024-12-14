const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readNums(path: []const u8) ![]u64 {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLen = 10000;

    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLen)) |line| {
        defer allocator.free(line);

        var it = std.mem.splitSequence(u8, line, " ");
        var nums = std.ArrayList(u64).init(allocator);
        while (it.next()) |chunk| try nums.append(try std.fmt.parseInt(u64, chunk, 10));
        return nums.toOwnedSlice();
    }

    unreachable;
}

fn splitDigits(num: u64) ?[2]u64 {
    const numDigits = std.math.log10(num) + 1;
    if (@mod(numDigits, 2) == 1) return null;

    const div = std.math.pow(u64, 10, @divExact(numDigits, 2));
    const right = @mod(num, div);
    const left = @divFloor(num, div);
    return .{ left, right };
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const stones = try readNums(args[1]);
    defer allocator.free(stones);

    var counts = std.AutoHashMap(u64, u64).init(allocator);
    defer counts.deinit();

    for (stones) |stone| (try counts.getOrPutValue(stone, 0)).value_ptr.* += 1;

    // const N = 25;
    const N = 75;
    for (0..N) |_| {
        var new_counts = std.AutoHashMap(u64, u64).init(allocator);
        var it = counts.iterator();
        while (it.next()) |p| {
            const stone = p.key_ptr.*;
            const count = p.value_ptr.*;
            if (stone == 0) {
                (try new_counts.getOrPutValue(1, 0)).value_ptr.* += count;
            } else if (splitDigits(stone)) |split| {
                (try new_counts.getOrPutValue(split[0], 0)).value_ptr.* += count;
                (try new_counts.getOrPutValue(split[1], 0)).value_ptr.* += count;
            } else {
                (try new_counts.getOrPutValue(stone * 2024, 0)).value_ptr.* += count;
            }
        }
        counts.deinit();
        counts = new_counts.move();
    }

    var sum: u64 = 0;
    var it = counts.valueIterator();
    while (it.next()) |v| sum += v.*;
    print("{d}\n", .{sum});
}
