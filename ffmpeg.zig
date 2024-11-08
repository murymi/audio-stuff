const std = @import("std");
const os = std.os;
const process = std.process;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn run(args:  *std.ArrayList([]const u8)) !void {
    try args.insert(0, "ffmpeg");
    var child = process.Child.init(args.items, allocator);
    child.stderr_behavior = .Pipe;
    child.stdout_behavior = .Pipe;
    var stderr_output = std.ArrayList(u8).init(allocator);
    var stdout_output = std.ArrayList(u8).init(allocator);
    try child.spawn();
    try child.collectOutput(&stdout_output, &stderr_output, std.math.maxInt(u16));
    const term = try child.wait();
    if(term.Exited != 0) {
        std.debug.print("Program Exit (1): {s}\n", .{stderr_output.items});
    }
}

pub fn runProbe(args:  *std.ArrayList([]const u8)) !std.ArrayList(u8) {
    try args.insert(0, "ffprobe");
    var child = process.Child.init(args.items, allocator);
    child.stderr_behavior = .Pipe;
    child.stdout_behavior = .Pipe;
    var stderr_output = std.ArrayList(u8).init(allocator);
    var stdout_output = std.ArrayList(u8).init(allocator);
    try child.spawn();
    try child.collectOutput(&stdout_output, &stderr_output, std.math.maxInt(u16));
    const term = try child.wait();
    if(term.Exited != 0) {
        std.debug.panic("Program Exit (1): {s}\n", .{stderr_output.items});
    }
    return stdout_output;
}