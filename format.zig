const std = @import("std");
const os = std.os;
const process = std.process;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const ffmpeg = @import("ffmpeg.zig");

fn mergeAudioAndVideo(input_video: []const u8, input_audio: []const u8, output_video: []const u8) !void {
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    try args.append("-i");
    try args.append(input_video);
    try args.append("-i");
    try args.append(input_audio);
    try args.append("-c:v");
    try args.append("copy");
    try args.append("-c:a");
    try args.append("aac");
    try args.append("-b:a");
    try args.append("192k");
    try args.append("-shortest");
    try args.append(output_video);
    try args.append("-y");


    try ffmpeg.run(&args);
}

fn removeAudioFromVideo(input_video: []const u8, output: []const u8) !void {
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    try args.append("-i");
    try args.append(input_video);
    try args.append("-an");
    try args.append("-c:v");
    try args.append("copy");
    try args.append(output);
    try args.append("-y");


    try ffmpeg.run(&args);
}

fn extractAudioFromVideo(input_video: []const u8, output: []const u8) !void {
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    try args.append("-i");
    try args.append(input_video);
    try args.append("-vn");
    try args.append("-q:a");
    try args.append("0");
    try args.append("-map");
    try args.append("a");
    try args.append(output);
    try args.append("-y");


    try ffmpeg.run(&args);
}

fn changeAudioBitrate(input: []const u8, output:[]const u8, bitrate:[]const u8) !void {
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    try args.append("-i");
    try args.append(input);
    try args.append("-b:a");
    try args.append(bitrate);
    try args.append(output);
    try args.append("-y");


    try ffmpeg.run(&args);

}

fn changeAudioFormat(old: []const u8,new: []const u8) !void {
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();
    try args.append("-i");
    try args.append(old);
    try args.append(new);
    try args.append("-y");
    try ffmpeg.run(&args);
}

fn cropAudio(input_audio: []const u8, output_audio: []const u8, start: []const u8, stop: []const u8) !void{
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();
    try args.append("-i");
    try args.append(input_audio);
    try args.append("-ss");
    try args.append(start);
    try args.append("-to");
    try args.append(stop);
    try args.append("-c");
    try args.append("copy");
    try args.append(output_audio);
    try args.append("-y");
    try ffmpeg.run(&args);
}

fn createSilence(output: []const u8, duration: []const u8) !void {
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();
    try args.append("-f");
    try args.append("lavfi");
    try args.append("-i");

    try args.append("anullsrc");
    try args.append("-t");
    try args.append(duration);
    try args.append(output);

    try args.append("-y");
    try ffmpeg.run(&args);
}

fn concatAudio(input1: []const u8, input2:[]const u8, output_audio: []const u8) !void {
   // _ = input1;
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    var filter_command = [_]u8{0} ** 1024;
    const res = try std.fmt.bufPrintZ(&filter_command, "concat:{s}|{s}", .{input1, input2});
    try args.append("-i");
    try args.append(res);
    try args.append("-c");
    try args.append("copy");
    try args.append(output_audio);
    try args.append("-y");
    try ffmpeg.run(&args);
}

//fn concatWithFade(input_audio: []const u8, output_audio: []const u8) !void {
//    
//}

fn getAudioMetadata(input: []const u8) !std.StringHashMap([]const u8) {
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    try args.append(input);
    try args.append("-show_entries");
    try args.append("format=bit_rate,duration");
    try args.append("-v");
    try args.append("quiet");
    try args.append("-of");
    try args.append(
        \\csv
    );

    const res =  try ffmpeg.runProbe(&args);
    //std.debug.print("Meta: {s}\n", .{res.items});
    var metadata = std.StringHashMap([]const u8).init(allocator);
    var iter = std.mem.tokenize(u8, res.items, ",");
    _ = iter.next();
    const a = iter.next().?;
    const b = iter.next().?;

    try metadata.put("duration", a);
    try metadata.put("bitrate", b);

    return metadata;
}

fn getAudioDuration(input: []const u8) !f64 {
    const meta = try getAudioMetadata(input);
    const dustr = meta.get("duration").?;
    return std.fmt.parseFloat(f64, dustr);
}

fn concatAudioWithFade(input1:[]const u8, input2:[]const u8) !void {
    const duration1 = try getAudioDuration(input1);
    const duration2 = try getAudioDuration(input2);

    std.debug.assert(duration1 > 15);
    std.debug.assert(duration2 > 15);

    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    try args.append("-i");
    try args.append(input1);

    try args.append("-i");
    try args.append(input2);

    try args.append("-filter_complex");

    //std.debug.print("a: {}, b: {}\n", .{@as(i64, @intFromFloat(duration1 - 15)), @as(i64, @intFromFloat(duration2))});

    var filterbuff = [_]u8{0} ** 512;
    const res = try allocator.dupeZ(u8, 
        try std.fmt.bufPrint(&filterbuff, 
        \\ [0]afade=t=out:st={}:d={}[a1];
        \\[1]afade=t=in:st={}:d={}[a2];
        \\[a1][a2]concat=n=2:v=0:a=1[out]
        , .{@as(i64, @intFromFloat(duration1 - 15)), 15, 0, 15})
    );
    try args.append(res);

    try args.append("-map");
    try args.append("[out]");
    try args.append("doto.mp3");
    try args.append("-y");

    try ffmpeg.run(&args);
}

pub fn main() !void {
    //try changeAudioFormat("song.mp3", "output.wav");
    //try changeAudioBitrate("song.mp3", "output.mp3", "192k");
    //try extractAudioFromVideo("goat.mp4", "output.mp3");
    //try removeAudioFromVideo("goat.mp4", "output1.mp4");
    //try mergeAudioAndVideo("output1.mp4", "song.mp3", "output.mp4");
    try cropAudio("song.mp3", "cropped.mp3", "0:0:0", "0:0:30");
    //try createSilence("output.mp3", "30");
    //try concatAudio("output.mp3", "cropped.mp3", "conc.mp3");
    //try getAudioMetadata("song.mp3");
    //const d = try getAudioDuration("song.mp3");
    //std.debug.print("Duration: {d}\n", .{d});

    try concatAudioWithFade("cropped.mp3", "cropped.mp3");
}