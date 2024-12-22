const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Registers = struct {
    a: u64,
    b: u64,
    c: u64,
};

fn parseInts(line: []const u8, prefix: []const u8) ![]u64 {
    const i = std.mem.indexOf(u8, line, prefix) orelse unreachable;
    const nums_chunk = line[i + prefix.len ..];
    var it = std.mem.splitSequence(u8, nums_chunk, ",");
    var r = std.ArrayList(u64).init(allocator);
    while (it.next()) |s| {
        try r.append(try std.fmt.parseInt(u64, s, 10));
    }
    return r.toOwnedSlice();
}

fn readProgram(path: []const u8) !struct { Registers, []usize } {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLen = 10000;

    var i: u64 = 0;
    var r = Registers{ .a = 0, .b = 0, .c = 0 };
    var opcodes: []usize = undefined;
    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLen)) |line| {
        defer allocator.free(line);
        if (line.len == 0) continue;

        const nums = try parseInts(line, ": ");

        switch (i) {
            0 => r.a = nums[0],
            1 => r.b = nums[0],
            2 => r.c = nums[0],
            3 => opcodes = nums,
            else => unreachable,
        }

        if (i < 3) allocator.free(nums);
        i += 1;
    }
    return .{ r, opcodes };
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var r, const opcodes = try readProgram(args[1]);
    defer allocator.free(opcodes);

    var out = std.ArrayList(u64).init(allocator);
    defer out.deinit();

    var i_ptr: usize = 0;
    while (i_ptr < opcodes.len) {
        const operation = opcodes[i_ptr];
        const operand = opcodes[i_ptr + 1];

        if (operation == 3) {
            if (r.a != 0) {
                i_ptr = operand;
            } else {
                i_ptr += 2;
            }
            continue;
        }
        const combo = switch (operand) {
            4 => r.a,
            5 => r.b,
            6 => r.c,
            else => operand,
        };
        switch (operation) {
            0 => r.a = @divFloor(r.a, @as(u64, 1) << @as(u6, @intCast(combo))),
            1 => r.b = r.b ^ operand,
            2 => r.b = @mod(combo, 8),
            4 => r.b = r.b ^ r.c,
            5 => try out.append(@mod(combo, 8)),
            6 => r.b = @divFloor(r.a, @as(u64, 1) << @as(u6, @intCast(combo))),
            7 => r.c = @divFloor(r.a, @as(u64, 1) << @as(u6, @intCast(combo))),
            else => unreachable,
        }
        i_ptr += 2;
    }
    print("{d}\n", .{out.items});
}
