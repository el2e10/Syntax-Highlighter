const std = @import("std");
// const writer = std.io.getStdOut().writer();

const my_lib = @import("my_lib");
const TokenType = my_lib.Tokenizer.ZigTokenizer.TokenType;
const Token = my_lib.Tokenizer.ZigTokenizer.Token;
const Program = my_lib.Tokenizer.ZigTokenizer.Program;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn compareTokenizerOutputs(got_buffer: std.ArrayList(Token), expected_buffer: std.ArrayList(Token)) !void {
    if (got_buffer.items.len != expected_buffer.items.len) {
        return error.WrongNumberOfTokens;
    }
    for (got_buffer.items, expected_buffer.items) |g_item, e_item| {
        if (g_item.token_type != e_item.token_type) {
            std.debug.print("Got {any}\n expected {any}\n\n", .{ g_item, e_item });
            return error.WrongTokenType;
        }
        if (!std.mem.eql(u8, g_item.value, e_item.value)) {
            std.debug.print("Got {any}\n expected {any}\n\n", .{ g_item, e_item });
            return error.WrongTokenValue;
        }
        if (g_item.start_index != e_item.start_index) {
            std.debug.print("Got {any}\n expected {any}\n\n", .{ g_item, e_item });
            return error.WrongTokenStartIndex;
        }
        if (g_item.end_index != e_item.end_index) {
            std.debug.print("Got {any}\n expected {any}\n\n", .{ g_item, e_item });
            return error.WrongTokenEndIndex;
        }
    }
}

test "one" {
    const input_text = "const program = Program.init(input_text);";
    const program = Program.init(input_text);

    var buffer = try std.ArrayList(Token).initCapacity(allocator, 100);
    var expected_buffer = try std.ArrayList(Token).initCapacity(allocator, 100);

    defer buffer.deinit();
    defer expected_buffer.deinit();

    try expected_buffer.append(Token{ .token_type = TokenType.KEYWORD, .value = "const", .start_index = 0, .end_index = 5 });
    try expected_buffer.append(Token{ .token_type = TokenType.IDENTIFIER, .value = "program", .start_index = 6, .end_index = 13 });
    try expected_buffer.append(Token{ .token_type = TokenType.SYMBOL, .value = "=", .start_index = 14, .end_index = 15 });
    try expected_buffer.append(Token{ .token_type = TokenType.FUNCTION, .value = "Program", .start_index = 16, .end_index = 23 });
    try expected_buffer.append(Token{ .token_type = TokenType.SYMBOL, .value = ".", .start_index = 23, .end_index = 24 });
    try expected_buffer.append(Token{ .token_type = TokenType.FUNCTION, .value = "init", .start_index = 24, .end_index = 28 });
    try expected_buffer.append(Token{ .token_type = TokenType.SYMBOL, .value = "(", .start_index = 28, .end_index = 29 });
    try expected_buffer.append(Token{ .token_type = TokenType.IDENTIFIER, .value = "input_text", .start_index = 29, .end_index = 39 });
    try expected_buffer.append(Token{ .token_type = TokenType.SYMBOL, .value = ")", .start_index = 39, .end_index = 40 });
    try expected_buffer.append(Token{ .token_type = TokenType.SYMBOL, .value = ";", .start_index = 40, .end_index = 41 });

    try program.parseProgram(&buffer);

    for (buffer.items) |item| {
        std.debug.print("The item is '{s}'\n", .{item.value});
    }

    compareTokenizerOutputs(buffer, expected_buffer) catch |err| {
        std.debug.print("[1/2] Test failed {any}\n\n", .{err});
        return;
    };
    std.debug.print("[1/2] passed\n\n", .{});
}

test "two" {
    const input_text = "pub fn main() {}";
    const program = Program.init(input_text);

    var buffer = try std.ArrayList(Token).initCapacity(allocator, 100);
    var expected_buffer = try std.ArrayList(Token).initCapacity(allocator, 100);

    defer buffer.deinit();
    defer expected_buffer.deinit();

    try expected_buffer.append(Token{ .token_type = TokenType.KEYWORD, .value = "pub", .start_index = 0, .end_index = 3 });
    try expected_buffer.append(Token{ .token_type = TokenType.KEYWORD, .value = "fn", .start_index = 4, .end_index = 6 });
    try expected_buffer.append(Token{ .token_type = TokenType.FUNCTION, .value = "main", .start_index = 7, .end_index = 11 });
    try expected_buffer.append(Token{ .token_type = TokenType.SYMBOL, .value = "(", .start_index = 11, .end_index = 12 });
    try expected_buffer.append(Token{ .token_type = TokenType.SYMBOL, .value = ")", .start_index = 12, .end_index = 13 });
    try expected_buffer.append(Token{ .token_type = TokenType.SYMBOL, .value = "{", .start_index = 14, .end_index = 15 });
    try expected_buffer.append(Token{ .token_type = TokenType.SYMBOL, .value = "}", .start_index = 15, .end_index = 16 });

    try program.parseProgram(&buffer);
    for (buffer.items) |item| {
        std.debug.print("The item is '{s}' {any}\n", .{ item.value, item.token_type });
    }

    compareTokenizerOutputs(buffer, expected_buffer) catch |err| {
        std.debug.print("[2/2] Test failed {any}\n\n", .{err});
        return;
    };

    std.debug.print("[2/2] Test passed\n\n", .{});
}
