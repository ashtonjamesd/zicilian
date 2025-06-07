const std = @import("std");
const Chess = @import("chess.zig").Chess;

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var chess = Chess.init(allocator);

    const reader = std.io.getStdIn().reader();

    while (true) {
        chess.print();
        std.debug.print("{s} to move: ", .{if (chess.isWhitesMove) "white" else "black"});

        const line = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024);
        defer if (line) |l| allocator.free(l);

        if (line) |l| {
            chess.playTurn(l) catch {};
        } else {
            break;
        }
    }
}
