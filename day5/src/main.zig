const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readFile(path: []const u8) struct { std.ArrayList([2]u32), std.ArrayList(std.ArrayList(u32)) } {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxNumLines = 10000;
    var order = std.ArrayList([2]u32).init(allocator);
    var pages = std.ArrayList(std.ArrayList(u32)).init(allocator);

    while (file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxNumLines) catch {
        unreachable;
    }) |line| {
        defer allocator.free(line);
        if (std.mem.indexOf(u8, line, "|") != null) {
            var it = std.mem.splitAny(u8, line, "|");
            var j: usize = 0;
            order.append(.{ 0, 0 }) catch unreachable;
            while (it.next()) |chunk| : (j += 1) {
                order.items[order.items.len - 1][j] = std.fmt.parseUnsigned(u32, chunk, 10) catch |err| {
                    print("{s} {}\n", .{ chunk, err });
                    unreachable;
                };
            }
        }

        if (std.mem.indexOf(u8, line, ",") != null) {
            var it = std.mem.splitAny(u8, line, ",");
            pages.append(std.ArrayList(u32).init(allocator)) catch unreachable;
            while (it.next()) |chunk| {
                pages.items[pages.items.len - 1].append(std.fmt.parseUnsigned(u32, chunk, 10) catch |err| {
                    print("{s} {}\n", .{ chunk, err });
                    unreachable;
                }) catch unreachable;
            }
        }
    }
    return .{ order, pages };
}

fn lessThan(_: void, a: [2]u32, b: [2]u32) bool {
    if (a[0] != b[0]) return a[0] < b[0];
    return a[1] < b[1];
}

fn comparePair(a: [2]u32, b: [2]u32) std.math.Order {
    if (a[0] != b[0]) return std.math.order(a[0], b[0]);
    return std.math.order(a[1], b[1]);
}

fn pairIsInOrder(order: [][2]u32, a: u32, b: u32) bool {
    return std.sort.binarySearch([2]u32, order, [2]u32{ b, a }, comparePair) == null;
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = std.process.argsAlloc(allocator) catch unreachable;
    defer {
        std.process.argsFree(allocator, args);
    }

    const r = readFile(args[1]);
    const order = &r[0];
    const pages = &r[1];
    defer {
        order.deinit();

        for (pages.items) |p| p.deinit();
        pages.deinit();
    }
    std.sort.pdq([2]u32, order.items, {}, lessThan);

    var part1: u32 = 0;
    var part2: u32 = 0;

    for (pages.items) |p| {
        // numAfter[i] is the number of pages that should come after page[i].
        var numAfter = allocator.alloc(u32, p.items.len) catch unreachable;
        defer allocator.free(numAfter);
        @memset(numAfter, 0);
        for (p.items, 0..) |page, i| {
            for (p.items[i + 1 ..], i + 1..) |other_page, j| {
                if (pairIsInOrder(order.items, page, other_page)) {
                    numAfter[i] += 1;
                } else {
                    numAfter[j] += 1;
                }
            }
        }

        const mid = p.items.len / 2;
        if (std.sort.isSorted(u32, numAfter, {}, std.sort.desc(u32))) {
            part1 += p.items[mid];
        } else {
            for (numAfter, 0..) |n, i| {
                if (n == mid) {
                    part2 += p.items[i];
                }
            }
        }
    }

    print("part 1: {d}\n", .{part1});
    print("part 2: {d}\n", .{part2});
}
