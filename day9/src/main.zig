const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readLine(path: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxLineLine = 1_000_000;

    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxLineLine)) |line| {
        return line;
    }

    unreachable;
}

// to_index is exclusive
fn calcSum(from_index: usize, to_index: usize, file_id: usize) usize {
    return @divExact((to_index - from_index) * file_id * (from_index + to_index - 1), 2);
}

const Block = struct {
    start: usize,
    len: usize,
    fn end(self: Block) usize {
        return self.start + self.len;
    }
};

fn getBlocks(line: []const u8) ![]Block {
    var r = try allocator.alloc(Block, line.len);

    r[0] = Block{ .start = 0, .len = line[0] - '0' };
    for (line[1..], 1..) |c, i| {
        r[i] = Block{ .start = r[i - 1].end(), .len = c - '0' };
    }
    return r;
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const line = try readLine(args[1]);
    defer allocator.free(line);

    // Part 1.
    {
        const blocks = try getBlocks(line);
        defer allocator.free(blocks);

        var free_block: usize = 1;
        var file_block: usize = line.len - @mod(line.len, 2);
        var sum: usize = 0;
        while (file_block > free_block) {
            const free_space = blocks[free_block].len;
            const needed_space = blocks[file_block].len;
            const file_id = @divExact(file_block, 2);

            const free_block_start = blocks[free_block].start;
            const new_block_start = free_block_start + @min(free_space, needed_space);
            sum += calcSum(free_block_start, new_block_start, file_id);

            blocks[file_block].len -= @min(free_space, needed_space);
            blocks[free_block].start = new_block_start;
            blocks[free_block].len -= @min(free_space, needed_space);

            if (free_space >= needed_space) {
                file_block -= 2;
            } else {
                const b = blocks[free_block + 1];
                const skipped_file_id = @divExact(free_block + 1, 2);
                sum += calcSum(b.start, b.end(), skipped_file_id);

                free_block += 2;
            }
        }

        print("part 1: {d}\n", .{sum});
    }

    // Part 2.
    {
        var sum: usize = 0;
        const blocks = try getBlocks(line);
        defer allocator.free(blocks);

        var file_block: usize = line.len - @mod(line.len, 2);
        while (file_block > 0) {
            const needed_space = blocks[file_block].len;
            const file_id = @divExact(file_block, 2);

            var free_block: usize = 1;
            while (free_block < file_block) {
                const b: *Block = &blocks[free_block];
                if (b.len >= needed_space) {
                    const new_start = b.start + needed_space;
                    sum += calcSum(b.start, new_start, file_id);
                    b.start = new_start;
                    b.len -= needed_space;
                    break;
                }
                free_block += 2;
            } else {
                const b = blocks[file_block];
                sum += calcSum(b.start, b.end(), file_id);
            }

            file_block -= 2;
        }
        print("part 2: {d}\n", .{sum});
    }
}
