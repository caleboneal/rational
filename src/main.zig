const std = @import("std");
const Io = std.Io;

const rational = @import("rational");

pub fn main(init: std.process.Init) !void {
    // const r64 = rational.CalkinWilfRational(.unsigned, 64);
    var args = init.minimal.args.iterate();
    std.debug.assert(!args.skip());
    const num_arg = args.next() orelse return error.NoArgProvided;
    std.log.info("Arg: {s}", .{num_arg});
    const num = try std.fmt.parseInt(usize, num_arg, 0);

    var answer: u64 = 0;

    const start = Io.Clock.real.now(init.io);
    for (0..num) |n| answer ^= rational.fusc(u64, n);
    const end = Io.Clock.real.now(init.io);
    std.log.info("Answer: {d}", .{answer});
    std.log.info("Duration (ms): {d}", .{end.toMilliseconds() - start.toMilliseconds()});
    const avg: u96 = @as(u96, @intCast(end.toNanoseconds() - start.toNanoseconds())) / num;
    std.log.info("Average (ns): {d}", .{avg});
}
