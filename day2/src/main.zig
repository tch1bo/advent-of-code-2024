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

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const lines = readPairs("example.txt");
    for (lines.items) |line| {
        var ascending: bool = false;
        const nums = line.items;
        for (1..nums.len) |i| {
            if (nums[i] == nums[i-1]) continue;
            ascending = nums[i] > nums[i-1];
            break;
        }
        print("{d}", .{nums});
        print("{}", .{ascending});

    }




    for (lines.items) |line| {
        line.deinit();
    }
    lines.deinit();
}
