const std = @import("std");

const PieceType = enum { Pawn, Knight, Bishop, Rook, Queen, King };
const PieceColor = enum { Black, White };

const Piece = struct { piece: PieceType, color: PieceColor };

pub const ansi = struct {
    pub const reset = "\x1b[0m";
    pub const black = "\x1b[30m";
    pub const gray = "\x1b[90m";
};

pub const Chess = struct {
    board: [8][8]?Piece,
    whitesMove: bool = true,
    moveCount: i16 = 0,

    fn fileToInt(file: u8) u8 {
        return file - 'a';
    }

    fn rankToInt(rank: u8) u8 {
        return rank - '0' - 1; // 8 - (rank - '0');
    }

    pub fn playTurn(self: *Chess, move: []u8) void {
        std.debug.print("move: {s}\n", .{move});
        self.moveCount += 1;

        // skip move
        if (move[0] == 'x' and move[1] == 'x') {
            return;
        }

        const fromX: u8 = fileToInt(move[0]);
        const fromY: u8 = rankToInt(move[1]);

        const toX: u8 = fileToInt(move[2]);
        const toY: u8 = rankToInt(move[3]);

        const piece = self.board[fromY][fromX].?;
        self.board[fromY][fromX] = null;

        self.board[toY][toX] = piece;
    }

    pub fn nextTurn(self: *Chess) void {
        std.debug.print("{s} to move: ", .{if (self.whitesMove) "white" else "black"});
        self.whitesMove = !self.whitesMove;
    }

    pub fn initBoard(self: *Chess) void {
        for (0..8) |row| {
            for (0..8) |col| {
                self.board[row][col] = null;
            }
        }

        const white: PieceColor = PieceColor.White;
        const black: PieceColor = PieceColor.Black;

        for (0..8) |i| {
            self.board[1][i] = Piece{ .color = white, .piece = PieceType.Pawn };
            self.board[6][i] = Piece{ .color = black, .piece = PieceType.Pawn };
        }

        const back_rank = [_]PieceType{ .Rook, .Knight, .Bishop, .Queen, .King, .Bishop, .Knight, .Rook };

        for (0..8) |i| {
            self.board[0][i] = Piece{ .color = white, .piece = back_rank[i] };
            self.board[7][i] = Piece{ .color = black, .piece = back_rank[i] };
        }
    }

    fn pieceChar(piece: Piece) u8 {
        return switch (piece.piece) {
            .Pawn => 'P',
            .Knight => 'N',
            .Bishop => 'B',
            .Rook => 'R',
            .Queen => 'Q',
            .King => 'K',
        };
    }

    pub fn print(self: *Chess) void {
        std.debug.print("\n", .{});

        var i: u8 = 0;
        std.debug.print("{s}     ", .{ansi.black});
        while (i < 8) : (i += 1) {
            std.debug.print(" {c}", .{i + 'a'});
        }
        std.debug.print("{s}\n\n", .{ansi.reset});

        for (0..8) |r| {
            const row = self.board[7 - r];

            std.debug.print(" {s} {}   ", .{ ansi.black, 7 - r + 1 });

            for (0..8) |c| {
                const cell = row[c];

                if (cell) |piece| {
                    const color = switch (piece.color) {
                        .White => ansi.gray,
                        .Black => ansi.black,
                    };
                    std.debug.print("{s}{c}{s} ", .{ color, pieceChar(piece), ansi.reset });
                } else {
                    std.debug.print("{s}. ", .{ansi.gray});
                }
            }

            std.debug.print("{s}  {} {s}\n", .{ ansi.black, 7 - r + 1, ansi.reset });
        }

        i = 0;
        std.debug.print("\n{s}     ", .{ansi.black});
        while (i < 8) : (i += 1) {
            std.debug.print(" {c}", .{i + 'a'});
        }
        std.debug.print("{s}\n\n", .{ansi.reset});
    }
};
