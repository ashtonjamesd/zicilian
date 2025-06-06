const std = @import("std");

const Piece = @import("piece.zig").Piece;
const PieceColor = @import("piece.zig").PieceColor;
const PieceType = @import("piece.zig").PieceType;

const ChessError = error{ InvalidFile, InvalidRank, IllegalMove, NotYourTurn };

pub const ansi = struct {
    pub const reset = "\x1b[0m";
    pub const black = "\x1b[30m";
    pub const gray = "\x1b[90m";
};

pub const Point = struct {
    x: u8,
    y: u8,

    pub fn from(x: u8, y: u8) Point {
        return Point{ .x = x, .y = y };
    }
};

pub const Chess = struct {
    board: [8][8]?Piece,
    isWhitesMove: bool = true,
    moveCount: i16 = 0,

    fn fileToInt(file: u8) !u8 {
        if (file < 'a' or file > 'h') {
            return ChessError.InvalidFile;
        }

        return file - 'a';
    }

    fn rankToInt(rank: u8) !u8 {
        if (rank < '1' or rank > '8') {
            return ChessError.InvalidRank;
        }

        return rank - '0' - 1;
    }

    fn pieceAt(self: *Chess, point: Point) ?Piece {
        return self.board[point.y][point.x];
    }

    fn setEmptyAt(self: *Chess, point: Point) void {
        self.board[point.y][point.x] = null;
    }

    fn putPieceAt(self: *Chess, point: Point, piece: Piece) void {
        self.board[point.y][point.x] = piece;
    }

    fn swapTurn(self: *Chess) void {
        self.isWhitesMove = !self.isWhitesMove;
    }

    fn illegalMove() ChessError {
        std.debug.print("Illegal move\n", .{});
        return ChessError.IllegalMove;
    }

    fn otherPlayersTurn() ChessError {
        std.debug.print("It is not your turn\n", .{});
        return ChessError.NotYourTurn;
    }

    pub fn playTurn(self: *Chess, move: []u8) !void {
        // skip move
        if (move[0] == 'x' and move[1] == 'x') {
            return;
        }

        const fromFile: u8 = fileToInt(move[0]) catch {
            return illegalMove();
        };
        const fromRank: u8 = rankToInt(move[1]) catch {
            return illegalMove();
        };
        const from: Point = Point.from(fromFile, fromRank);

        const piece = self.pieceAt(from).?;

        if (piece.isWhite() != self.isWhitesMove) {
            return otherPlayersTurn();
        }

        const toFile: u8 = fileToInt(move[2]) catch {
            return illegalMove();
        };
        const toRank: u8 = rankToInt(move[3]) catch {
            return illegalMove();
        };
        const to: Point = Point.from(toFile, toRank);

        if (piece.isPawn() and !isValidPawnMove(piece, to, from)) {
            return illegalMove();
        }

        self.setEmptyAt(from);
        self.putPieceAt(to, piece);

        self.moveCount += 1;
        self.swapTurn();
    }

    fn isValidPawnMove(piece: Piece, to: Point, from: Point) bool {
        if (to.x != from.x) return false;

        const isFirstMove: bool = (!piece.isWhite() and from.y == 6) or
            (piece.isWhite() and from.y == 1);

        const maxForwardMove: u8 = if (isFirstMove) 2 else 1;

        if (piece.isWhite() and (from.y + maxForwardMove) < to.y) {
            return false;
        }
        if (!piece.isWhite() and (from.y - maxForwardMove) > to.y) {
            return false;
        }

        return true;
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
            self.board[1][i] = Piece{ .color = white, .pieceType = PieceType.Pawn };
            self.board[6][i] = Piece{ .color = black, .pieceType = PieceType.Pawn };
        }

        const back_rank = [_]PieceType{ .Rook, .Knight, .Bishop, .Queen, .King, .Bishop, .Knight, .Rook };

        for (0..8) |i| {
            self.board[0][i] = Piece{ .color = white, .pieceType = back_rank[i] };
            self.board[7][i] = Piece{ .color = black, .pieceType = back_rank[i] };
        }
    }

    fn pieceChar(piece: Piece) u8 {
        return switch (piece.pieceType) {
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
