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
    captured: std.ArrayList(Piece),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Chess {
        var chess = Chess{ .board = undefined, .isWhitesMove = true, .moveCount = 1, .captured = std.ArrayList(Piece).init(allocator), .allocator = allocator };

        chess.initBoard();
        return chess;
    }

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

    fn capture(self: *Chess, piece: Piece) !void {
        try self.captured.append(piece);
    }

    pub fn playTurn(self: *Chess, move: []u8) !void {
        if (move[0] == 'x' and move[1] == 'x') {
            self.swapTurn();
            return;
        }

        const fromFile: u8 = fileToInt(move[0]) catch {
            return illegalMove();
        };
        const fromRank: u8 = rankToInt(move[1]) catch {
            return illegalMove();
        };
        const from: Point = Point.from(fromFile, fromRank);

        const piece = self.pieceAt(from) orelse return illegalMove();

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

        if (piece.isPawn() and !self.isValidPawnMove(piece, to, from)) {
            return illegalMove();
        }

        if (piece.isKnight() and !self.isValidKnightMove(piece, to, from)) {
            return illegalMove();
        }

        if (self.pieceAt(to)) |target| {
            try self.capture(target);
        }

        self.setEmptyAt(from);
        self.setEmptyAt(to);

        self.putPieceAt(to, piece);

        self.moveCount += 1;
        self.swapTurn();
    }

    fn isValidKnightMove(self: *Chess, piece: Piece, to: Point, from: Point) bool {
        const dxs = [_]i8{ 1, 1, 2, 2, -1, -1, -2, -2 };
        const dys = [_]i8{ -2, 2, -1, 1, -2, 2, -1, 1 };

        const fromX: i8 = @intCast(from.x);
        const fromY: i8 = @intCast(from.y);
        const toX: i8 = @intCast(to.x);
        const toY: i8 = @intCast(to.y);

        for (dxs, dys) |dx, dy| {
            const nx = fromX + dx;
            const ny = fromY + dy;

            if (nx >= 0 and nx < 8 and ny >= 0 and ny < 8) {
                if (toX == nx and toY == ny) {
                    const target = self.pieceAt(to);
                    return target == null or target.?.color != piece.color;
                }
            }
        }

        return false;
    }

    fn isValidPawnMove(self: *Chess, piece: Piece, to: Point, from: Point) bool {
        const direction: i8 = if (piece.isWhite()) 1 else -1;

        const fromY: i8 = @intCast(from.y);
        const takeY: u8 = @intCast(fromY + direction);

        if (takeY >= 0 and takeY < 8) {
            const rightTakeMove = Point.from(from.x + 1, takeY);
            if (rightTakeMove.x == to.x and rightTakeMove.y == to.y) {
                return self.pieceAt(to) != null;
            }
        }

        if (from.x > 0) {
            const leftTakeMove = Point.from(from.x - 1, takeY);
            if (leftTakeMove.x == to.x and leftTakeMove.y == to.y) {
                return self.pieceAt(to) != null;
            }
        }

        if (to.x != from.x) return false;

        if (self.pieceAt(to)) |_| return false;

        const isFirstMove: bool = (!piece.isWhite() and from.y == 6) or
            (piece.isWhite() and from.y == 1);
        const maxForwardMove: u8 = if (isFirstMove) 2 else 1;

        if (to.y == from.y + 2) {
            const inFront = Point.from(to.x, to.y - 1);
            return self.pieceAt(to) == null and self.pieceAt(inFront) == null;
        }

        if (from.y > 1 and to.y == from.y - 2) {
            const inFront = Point.from(to.x, to.y + 1);
            return self.pieceAt(to) == null and self.pieceAt(inFront) == null;
        }

        if (piece.isWhite() and (from.y + maxForwardMove) < to.y) {
            return false;
        }
        if (!piece.isWhite() and (from.y - maxForwardMove) > to.y) {
            return false;
        }

        if (piece.isWhite() and to.y < from.y) {
            return false;
        }
        if (!piece.isWhite() and to.y > from.y) {
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
