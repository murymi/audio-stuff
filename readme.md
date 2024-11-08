### Editing audio with ffmpeg
```zig
    // change audio format
    try changeAudioFormat("song.mp3", "output.wav");

    // change audio bitrate
    try changeAudioBitrate("song.mp3", "output.mp3", "192k");

    // get audio from video
    try extractAudioFromVideo("goat.mp4", "output.mp3");

    // remove audio from video
    try removeAudioFromVideo("goat.mp4", "output1.mp4");

    // add audio to video
    try mergeAudioAndVideo("output1.mp4", "song.mp3", "output.mp4");

    // trim audio
    try cropAudio("song.mp3", "cropped.mp3", "0:0:0", "0:0:30");

    // create silent audio
    try createSilence("output.mp3", "30");

    // concat two audio files
    try concatAudio("output.mp3", "cropped.mp3", "conc.mp3");

    // get audio proprerties
    try getAudioMetadata("song.mp3");
    
    const d = try getAudioDuration("song.mp3");
    std.debug.print("Duration: {d}\n", .{d});

    // concat two audio files with smooth transitions
    try concatAudioWithFade("cropped.mp3", "cropped.mp3");
```