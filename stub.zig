const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn readMap(path: []const u8) !void{
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;
    defer file.close();

    const maxNumLines = 10000;

    while (try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', maxNumLines)) |line| {
        defer allocator.free(line);

        print("{s}\n", .{line});
    }
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    try readMap(args[1]);

}

