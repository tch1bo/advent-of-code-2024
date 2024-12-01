const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readPairs(path: []const u8) [2]std.ArrayList(i32) {
    var left = std.ArrayList(i32).init(allocator);
    var right = std.ArrayList(i32).init(allocator);
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    while (file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize)) catch |err| {
        std.log.err("Failed to read line: {s}", .{@errorName(err)});
        unreachable;
    }) |line| {
        defer allocator.free(line);
        var it = std.mem.splitSequence(u8, line, " ");

        var nums = std.ArrayList(i32).init(allocator);
        defer nums.deinit();
        while (it.next()) |value| {
            if (std.mem.eql(u8, value, " ") or value.len == 0) continue;
            nums.append(std.fmt.parseUnsigned(i32, value, 10) catch unreachable) catch unreachable;
        }

        if (nums.items.len != 2) @panic("unexpected number of integers in line");

        left.append(nums.items[0]) catch unreachable;
        right.append(nums.items[1]) catch unreachable;
    }

    return .{ left, right };
}
pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const pairs = readPairs("input.txt");
    defer pairs[0].deinit();
    defer pairs[1].deinit();

    std.sort.pdq(i32, pairs[0].items, {}, std.sort.asc(i32));
    std.sort.pdq(i32, pairs[1].items, {}, std.sort.asc(i32));

    // Part 1.
    {
        var sum: i64 = 0;
        for (pairs[0].items, pairs[1].items) |l, r| sum += @abs(l - r);
        print("part 1: {d}\n", .{sum});
    }

    // Part 2.
    {
        var rightCounts = std.AutoHashMap(i32, i32).init(allocator);
        defer rightCounts.deinit();
        for (pairs[1].items) |v| {
            if (rightCounts.getPtr(v)) |ptr| {
                ptr.* += 1;
            } else {
                rightCounts.put(v, 1) catch unreachable;
            }
        }

        var sum: i32 = 0;
        for (pairs[0].items) |v| {
            if (rightCounts.get(v)) |count| {
                sum += v * count;
            }
        }

        print("part 2: {d}\n", .{sum});
    }
}
