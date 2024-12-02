const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readPairs(path: []const u8) std.ArrayList(std.ArrayList(i32)) {
    var r = std.ArrayList(std.ArrayList(i32)).init(allocator);
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    while (file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize)) catch {
        unreachable;
    }) |line| {
        defer allocator.free(line);
        var it = std.mem.splitSequence(u8, line, " ");

        r.append(std.ArrayList(i32).init(allocator)) catch unreachable;
        var nums = &r.items[r.items.len - 1];
        while (it.next()) |value| {
            if (std.mem.eql(u8, value, " ") or value.len == 0) continue;
            nums.append(std.fmt.parseUnsigned(i32, value, 10) catch unreachable) catch unreachable;
        }
    }

    return r;
}

fn numsAreOk(first: i32, second: i32, ascending: bool) bool {
    const in_order = if (ascending) first < second else first > second;
    const diff = @abs(first - second);
    return (in_order and diff >= 1 and diff <= 3);
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const lines = readPairs("input.txt");
    defer {
        for (lines.items) |line| {
            line.deinit();
        }
        lines.deinit();
    }

    // Part 1.
    {
        var num_safe: i32 = 0;
        for (lines.items) |line| {
            const nums = line.items;
            const ascending = for (1..nums.len) |i| {
                if (nums[i] != nums[i - 1]) {
                    break nums[i] > nums[i - 1];
                }
            } else false; // If all elements are equal, default to false.

            const is_safe = for (1..nums.len) |i| {
                if (!numsAreOk(nums[i - 1], nums[i], ascending)) break false;
            } else true;
            if (is_safe) num_safe += 1;
        }
        print("part1: {d}\n", .{num_safe});
    }

    // Part 2.
    {
        var num_safe: i32 = 0;
        for (lines.items) |line| {
            const nums = line.items;
            var num_descending: i32 = 0;
            var num_ascending: i32 = 0;
            for (1..nums.len) |i| {
                if (nums[i - 1] < nums[i]) num_ascending += 1;
                if (nums[i - 1] > nums[i]) num_descending += 1;
            }
            if (@min(num_ascending, num_descending) > 1) continue;
            const ascending = (num_ascending > num_descending);
            var index_to_remove: i32 = -1;
            var i: u32 = 1;
            const is_safe = while (i < nums.len) : (i += 1) {
                if (!numsAreOk(nums[i - 1], nums[i], ascending)) {
                    if (index_to_remove >= 0) break false;
                    if (i + 1 >= nums.len) {
                        // We reached the last level, without any bad previous levels.
                        break true;
                    }
                    // We have to remove either nums[i-1] or nums[i].
                    if (numsAreOk(nums[i - 1], nums[i + 1], ascending)) {
                        // Remove nums[i].
                        index_to_remove = @intCast(i);
                        i += 1;
                    } else if (i == @as(u32, 1) or numsAreOk(nums[i - 2], nums[i], ascending)) {
                        // Remove nums[i - 1].
                        index_to_remove = @intCast(i - 1);
                    } else {
                        break false;
                    }
                }
            } else true;
            if (is_safe) num_safe += 1;
        }
        print("part2: {d}\n", .{num_safe});
    }
}
