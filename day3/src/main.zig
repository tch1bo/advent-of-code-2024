const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readFile(path: []const u8) []u8 {
    return std.fs.cwd().readFileAlloc(allocator, path, 100_000) catch unreachable;
}

fn scanNumberFollowedBySymbol(content: []const u8, i: *usize, expected_symbol: u8) ?u32 {
    var num: u32 = 0;
    while (i.* < content.len) : (i.* += 1) {
        const c = content[i.*];
        if (std.ascii.isDigit(c)) {
            num *= 10;
            num += c - '0';
        } else if (c == expected_symbol) {
            i.* += 1;
            return num;
        } else {
            return null;
        }
    }
    return null;
}

fn scanSymbol(content: []const u8, start_index: *usize, expected_symbol: u8) bool {
    if (start_index.* >= content.len) return false;
    defer start_index.* += 1;
    return content[start_index.*] == expected_symbol;
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const content = readFile("input.txt");
    defer allocator.free(content);

    // Part 1
    {
        var i: usize = 0;
        var sum: u32 = 0;
        while (std.mem.indexOfPos(u8, content, i, "mul(")) |match| {
            i = match + "mul(".len;
            var mult_result: u32 = 0;

            if (scanNumberFollowedBySymbol(content, &i, ',')) |num| {
                mult_result = num;
            } else continue;

            if (scanNumberFollowedBySymbol(content, &i, ')')) |num| {
                mult_result *= num;
            } else continue;
            sum += mult_result;
        }
        print("part 1: {d}\n", .{sum});
    }

    // Part 2
    {
        var i: usize = 0;
        var sum: u32 = 0;
        var dont_is_active = false;
        while (i < content.len) {
            print("{d} {d}\n", .{i, content.len});
            if (dont_is_active) {
                if (std.mem.indexOfPos(u8, content, i, "do()")) |match| {
                    dont_is_active = false;
                    i = match + "do()".len;
                } else {
                    break;
                }
            } else {
                const dont_index = std.mem.indexOfPos(u8, content, i, "don't()") orelse content.len;
                while (std.mem.indexOfPos(u8, content, i, "mul(")) |match| {
                    if (match >= dont_index) {
                        i = dont_index + "don't()".len;
                        dont_is_active = true;
                        break;
                    }
                    i = match + "mul(".len;
                    var mult_result: u32 = 0;

                    if (scanNumberFollowedBySymbol(content, &i, ',')) |num| {
                        mult_result = num;
                    } else continue;

                    if (scanNumberFollowedBySymbol(content, &i, ')')) |num| {
                        mult_result *= num;
                    } else continue;
                    sum += mult_result;
                } else {
                    break;
                }
            }
        }
        print("part 2: {d}\n", .{sum});
    }
}
