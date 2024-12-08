const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readLines(path: []const u8) !struct { []u64, [][]u64 } {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxNumLines = 10000;

    var results = std.ArrayList(u64).init(allocator);
    var ops = std.ArrayList([]u64).init(allocator);

    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxNumLines)) |line| {
        defer allocator.free(line);

        const colon = std.mem.indexOf(u8, line, ":").?;
        const result = try std.fmt.parseUnsigned(u64, line[0..colon], 10);
        try results.append(result);

        var nums = std.ArrayList(u64).init(allocator);
        var it = std.mem.splitSequence(u8, line[colon + 1 ..], " ");
        while (it.next()) |chunk| {
            if (chunk.len == 0) continue;
            const num = try std.fmt.parseUnsigned(u64, chunk, 10);
            try nums.append(num);
        }
        try ops.append(try nums.toOwnedSlice());
    }
    return .{ try results.toOwnedSlice(), try ops.toOwnedSlice() };
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const rl = readLines(args[1]) catch unreachable;
    const results = rl[0];
    const ops = rl[1];
    defer {
        allocator.free(results);
        for (ops) |o| allocator.free(o);
        defer allocator.free(ops);
    }

    // Part 1.
    {
        var sum: u64 = 0;
        for (results, ops) |r, nums| {
            const num_combinations: u64 = @as(u64, 1) << @intCast(nums.len - 1);
            for (0..num_combinations) |combination| {
                var got: u64 = nums[0];
                for (1..nums.len) |i| {
                    const mask = @as(u64, 1) << @intCast(i - 1);
                    if (combination & mask != 0) {
                        got *= nums[i];
                    } else {
                        got += nums[i];
                    }
                }
                if (r == got) {
                    sum += r;
                    break;
                }
            }
        }
        print("part 1: {d}\n", .{sum});
    }

    // Part 2.
    {
        var sum: u64 = 0;
        for (results, ops) |r, nums| {
            const num_combinations: u64 = std.math.pow(u64, 3, @as(u64, nums.len - 1));
            for (0..num_combinations) |c| {
                var got: u64 = nums[0];
                var combination = c;
                for (1..nums.len) |i| {
                    const div = combination % 3;
                    combination /= 3;
                    switch (div) {
                        0 => got += nums[i],
                        1 => got *= nums[i],
                        2 => got = got * std.math.pow(u64, 10, std.math.log10(nums[i]) + 1) + nums[i],
                        else => unreachable,
                    }
                }
                if (r == got) {
                    sum += r;
                    break;
                }
            }
        }
        print("part 2: {d}\n", .{sum});
    }
}
