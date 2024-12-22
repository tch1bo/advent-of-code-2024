const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readTask(path: []const u8) !struct { [][]const u8, [][]const u8, [][]const u8 } {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLen = 10000;

    var towels = std.ArrayList([]const u8).init(allocator);
    var patterns = std.ArrayList([]const u8).init(allocator);
    var lines = std.ArrayList([]const u8).init(allocator);
    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLen)) |line| {
        try lines.append(line);
        if (line.len == 0) continue;
        if (towels.items.len == 0) {
            var it = std.mem.splitSequence(u8, line, ", ");
            while (it.next()) |towel| try towels.append(towel);
        } else {
            try patterns.append(line);
        }
    }
    return .{ try towels.toOwnedSlice(), try patterns.toOwnedSlice(), try lines.toOwnedSlice() };
}

fn solve(pattern: []const u8, towels: [][]const u8) !u64 {
    // print("----------------------------------------------------\n", .{});
    // print("{s}\n", .{pattern});
    var stack = std.ArrayList(usize).init(allocator);
    defer stack.deinit();
    var visited = try allocator.alloc(bool, pattern.len);
    defer allocator.free(visited);
    for (visited) |*v| v.* = false;
    var parents = std.AutoHashMap(usize, std.AutoHashMap(usize, void)).init(allocator);
    defer {
        var it = parents.valueIterator();
        while (it.next()) |c| c.*.deinit();
        parents.deinit();
    }

    try stack.append(0);
    while (stack.items.len > 0) {
        const cur = stack.pop();
        // print("{d}\n", .{cur});
        if (cur == pattern.len or visited[cur]) continue;
        visited[cur] = true;

        for (towels) |t| {
            const new_start = cur + t.len;
            if (new_start <= pattern.len and std.mem.startsWith(u8, pattern[cur..], t)) {
                try stack.append(new_start);
                const it = try parents.getOrPut(new_start);
                if (!it.found_existing) it.value_ptr.* = std.AutoHashMap(usize, void).init(allocator);
                try it.value_ptr.*.put(cur, {});
            }
        }
    }
    if (parents.get(pattern.len) == null) return 0;

    var counts = try allocator.alloc(u64, pattern.len + 1);
    defer allocator.free(counts);
    for (counts) |*c| c.* = 0;
    counts[pattern.len] = 1;
    var i: usize = pattern.len;
    while (i > 0) {
        if (parents.getPtr(i)) |ps| {
            var it = ps.*.keyIterator();
            while (it.next()) |p| counts[p.*] += counts[i];
        }
        i -= 1;
    }

    return counts[0];
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const towels, const patterns, const lines = try readTask(args[1]);
    defer {
        for (lines) |l| allocator.free(l);
        allocator.free(lines);
        allocator.free(patterns);
        allocator.free(towels);
    }
    var part1_sum: u64 = 0;
    var part2_sum: u64 = 0;
    for (patterns) |p| {
        const r = try solve(p, towels);
        if (r > 0) part1_sum += 1;
        part2_sum += r;
    }
    print("part 1: {d}\n", .{part1_sum});
    print("part 2: {d}\n", .{part2_sum});
}
