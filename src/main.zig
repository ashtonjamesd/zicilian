const std = @import("std");
const Chess = @import("chess.zig").Chess;

pub fn main() !void {
    var chess = Chess{ .board = undefined };
    chess.initBoard();

    var allocator = std.heap.page_allocator;
    const reader = std.io.getStdIn().reader();

    while (true) {
        chess.print();
        chess.nextTurn();

        const line = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024);
        defer if (line) |l| allocator.free(l);

        if (line) |l| {
            chess.playTurn(l);
        } else {
            break;
        }
    }
}
