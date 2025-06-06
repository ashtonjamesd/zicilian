pub const PieceType = enum { Pawn, Knight, Bishop, Rook, Queen, King };

pub const PieceColor = enum { Black, White };

pub const Piece = struct {
    pieceType: PieceType,
    color: PieceColor,

    pub fn isWhite(self: Piece) bool {
        return self.color == PieceColor.White;
    }

    pub fn isPawn(self: Piece) bool {
        return self.pieceType == PieceType.Pawn;
    }
};
