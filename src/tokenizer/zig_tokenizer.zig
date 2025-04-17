const std = @import("std");
const writer = std.io.getStdOut().writer();

pub const TokenType = enum { KEYWORD, IDENTIFIER, LITERAL, SYMBOL, FUNCTION };
const keywords = [_][]const u8{ "fn", "pub", "const", "u8", "bool" };
const symbols = [_][]const u8{ "\"", "'", "(", ")", "{", "}", "=", ".", ";", ":" };

pub const Token = struct {
    token_type: TokenType,
    value: []const u8,
    start_index: u64,
    end_index: u64,

    pub fn init(text: []const u8, start: u64, end: u64) ?Token {
        if (start == end) {
            return null;
        }
        const token_text: []const u8 = text[start..end];
        const token_type = _getTokenType(token_text);
        return Token{ .token_type = token_type, .value = token_text, .start_index = start, .end_index = end };
    }

    fn _getTokenType(text: []const u8) TokenType {
        for (keywords) |keyword| {
            if (std.mem.eql(u8, keyword, text)) {
                return TokenType.KEYWORD;
            }
        }
        for (symbols) |symbol| {
            if (std.mem.eql(u8, symbol, text)) {
                return TokenType.SYMBOL;
            }
        }
        return TokenType.IDENTIFIER;
    }

    fn _createFnToken(text: []const u8, start: u64, end: u64) Token {
        const token_text: []const u8 = text[start..end];
        return Token{ .token_type = TokenType.FUNCTION, .value = token_text, .start_index = start, .end_index = end };
    }

    fn _createSymbolToken(text: []const u8, start: u64, end: u64) Token {
        const token_text: []const u8 = text[start..end];
        return Token{ .token_type = TokenType.SYMBOL, .value = token_text, .start_index = start, .end_index = end };
    }

    fn _createToken(text: []const u8, start: u64, end: u64, token_type: TokenType) Token {
        const token_text: []const u8 = text[start..end];
        return Token{ .token_type = token_type, .value = token_text, .start_index = start, .end_index = end };
    }
};

pub const Program = struct {
    text: []const u8,

    pub fn init(text: []const u8) Program {
        return Program{ .text = text };
    }

    fn _isSymbol(token: u8) bool {
        for (symbols) |symbol| {
            std.debug.print("'{d}' '{}' \n", .{ symbol[0], token });
            if (symbol[0] == token) {
                return true;
            }
        }
        return false;
    }

    fn _isDigit(token: u8) bool {
        switch (token) {
            '0'...'9' => return true,
            else => return false,
        }
    }

    fn _isNumericalTokenType(token: u8) bool {
        switch (token) {
            'u', 'i', 'f' => return true,
            else => return false,
        }
    }

    //"pub fn main() {}"
    //"const program = Program.init(input_text);"
    //fn _isSymbol(token: u8) bool {
    // const varabl = "Hello world";
    pub fn parseProgram(self: Program, buffer: *std.ArrayList(Token)) !void {
        var index: u64 = 0;
        var token_start_index: u64 = 0;
        var prev_token: ?Token = undefined;
        var prev_char: u8 = undefined;
        var current_char: u8 = undefined;
        var next_char: u8 = undefined;
        while (index < self.text.len) : (index += 1) {
            current_char = self.text[index];
            prev_char = if (index > 0) self.text[index - 1] else self.text[0];
            next_char = if (index < self.text.len - 1) self.text[index + 1] else self.text[index];
            prev_token = if (buffer.items.len > 1) buffer.getLast() else null;
            switch (current_char) {
                ' ' => {
                    if (prev_token) |token| {
                        if (token.token_type == TokenType.SYMBOL and token.value[0] == '"') {
                            continue;
                        }
                    }

                    if (' ' == self.text[token_start_index]) {
                        token_start_index += 1;
                        index += 1;
                    }
                    const token = Token.init(self.text, token_start_index, index) orelse continue;
                    try buffer.append(token);
                    token_start_index = index + 1;
                },
                '(', '.' => {
                    const fn_token = Token._createToken(self.text, token_start_index, index, TokenType.FUNCTION);
                    try buffer.append(fn_token);
                    const symbol_token = Token._createToken(self.text, index, index + 1, TokenType.SYMBOL);
                    try buffer.append(symbol_token);
                    token_start_index = index + 1;
                },
                ')', '}', '{' => {
                    const symbol_token = Token._createToken(self.text, index, index + 1, TokenType.SYMBOL);
                    if (token_start_index != index) {
                        const token = Token.init(self.text, token_start_index, index) orelse continue;
                        try buffer.append(token);
                    }
                    try buffer.append(symbol_token);
                    token_start_index = index + 1;
                },
                ';' => {
                    const symbol_token = Token._createToken(self.text, index, index + 1, TokenType.SYMBOL);
                    try buffer.append(symbol_token);
                },
                ':' => {
                    const token = Token.init(self.text, token_start_index, index) orelse continue;
                    try buffer.append(token);
                    const symbol_token = Token._createToken(self.text, index, index + 1, TokenType.SYMBOL);
                    try buffer.append(symbol_token);
                    token_start_index = index + 1;
                },
                '"' => {
                    if (token_start_index == index) {
                        token_start_index = index + 1;
                    } else {
                        const token = Token._createToken(self.text, token_start_index, index, TokenType.LITERAL);
                        try buffer.append(token);
                        token_start_index = index + 1;
                    }
                    const symbol_token = Token._createToken(self.text, index, index + 1, TokenType.SYMBOL);
                    try buffer.append(symbol_token);
                },
                '0'...'9' => {
                    if (!_isDigit(next_char) and !_isNumericalTokenType(prev_char)) {
                        const token = Token._createToken(self.text, token_start_index, index + 1, TokenType.LITERAL);
                        try buffer.append(token);
                        token_start_index = index + 1;
                    }
                },
                else => {},
            }
        }
    }
};
