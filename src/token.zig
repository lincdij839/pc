// PC Language Lexer - Token 定義
const std = @import("std");

pub const TokenKind = enum {
    // 關鍵字
    Def,
    Class,
    Struct,
    If,
    Elif,
    Else,
    While,
    For,
    In,
    Return,
    Break,
    Continue,
    Match,
    Case,
    Try,
    Except,
    Finally,
    Import,
    From,
    As,
    Pass,
    True,
    False,
    None,
    And,
    Or,
    Not,
    Unsafe,
    Mut,
    Const,
    Enum,
    Trait,
    Impl,

    // 類型關鍵字
    I8,
    I16,
    I32,
    I64,
    I128,
    U8,
    U16,
    U32,
    U64,
    U128,
    F32,
    F64,
    Bool,
    Char,
    Str,
    Bytes,

    // 字面量
    Integer,
    Float,
    String,
    Identifier,

    // 運算符
    Plus, // +
    Minus, // -
    Star, // *
    Slash, // /
    Percent, // %
    Power, // **
    Equal, // =
    EqualEqual, // ==
    NotEqual, // !=
    Less, // <
    LessEqual, // <=
    Greater, // >
    GreaterEqual, // >=
    Ampersand, // &
    Pipe, // |
    Caret, // ^
    Tilde, // ~
    LeftShift, // <<
    RightShift, // >>

    // 分隔符
    LeftParen, // (
    RightParen, // )
    LeftBracket, // [
    RightBracket, // ]
    LeftBrace, // {
    RightBrace, // }
    Comma, // ,
    Colon, // :
    Semicolon, // ;
    Dot, // .
    Arrow, // ->
    FatArrow, // =>
    At, // @

    // 特殊
    Newline,
    Indent,
    Dedent,
    Eof,
};

pub const Token = struct {
    kind: TokenKind,
    lexeme: []const u8,
    line: usize,
    column: usize,

    pub fn format(
        self: Token,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{s} '{s}' at {}:{}", .{
            @tagName(self.kind),
            self.lexeme,
            self.line,
            self.column,
        });
    }
};

pub fn keywordOrIdentifier(lexeme: []const u8) TokenKind {
    const map = std.StaticStringMap(TokenKind).initComptime(.{
        .{ "def", .Def },
        .{ "class", .Class },
        .{ "struct", .Struct },
        .{ "if", .If },
        .{ "elif", .Elif },
        .{ "else", .Else },
        .{ "while", .While },
        .{ "for", .For },
        .{ "in", .In },
        .{ "return", .Return },
        .{ "break", .Break },
        .{ "continue", .Continue },
        .{ "match", .Match },
        .{ "case", .Case },
        .{ "try", .Try },
        .{ "except", .Except },
        .{ "finally", .Finally },
        .{ "import", .Import },
        .{ "from", .From },
        .{ "as", .As },
        .{ "pass", .Pass },
        .{ "true", .True },
        .{ "false", .False },
        .{ "none", .None },
        .{ "null", .None },
        .{ "and", .And },
        .{ "or", .Or },
        .{ "not", .Not },
        .{ "unsafe", .Unsafe },
        .{ "mut", .Mut },
        .{ "const", .Const },
        .{ "enum", .Enum },
        .{ "trait", .Trait },
        .{ "impl", .Impl },
        // 類型
        .{ "i8", .I8 },
        .{ "i16", .I16 },
        .{ "i32", .I32 },
        .{ "i64", .I64 },
        .{ "i128", .I128 },
        .{ "u8", .U8 },
        .{ "u16", .U16 },
        .{ "u32", .U32 },
        .{ "u64", .U64 },
        .{ "u128", .U128 },
        .{ "f32", .F32 },
        .{ "f64", .F64 },
        .{ "bool", .Bool },
        .{ "char", .Char },
        .{ "str", .Str },
        .{ "bytes", .Bytes },
    });

    return map.get(lexeme) orelse .Identifier;
}
