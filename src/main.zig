const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("librealsense2/rs.h");
    @cInclude("librealsense2/h/rs_pipeline.h");
    @cInclude("librealsense2/h/rs_option.h");
    @cInclude("librealsense2/h/rs_frame.h");
});
const std = @import("std");

fn check_error(err: ?*c.rs2_error) void {
    if (err) |e| {
        _ = c.printf("rs_error was raised when calling %s(%s):\n", c.rs2_get_failed_function(e), c.rs2_get_failed_args(e));
        _ = c.printf("%s \n", c.rs2_get_error_message(e));
    }
}
fn print_device_info(d: ?*c.rs2_device) void {
    var e: ?*c.rs2_error = null;
    _ = c.printf("\nUsing device 0, an %s\n", c.rs2_get_device_info(d, c.RS2_CAMERA_INFO_NAME, &e));
    check_error(e);
    _ = c.printf("Serial Number %s\n", c.rs2_get_device_info(d, c.RS2_CAMERA_INFO_SERIAL_NUMBER, &e));
    check_error(e);
    _ = c.printf("Firmware version %s\n\n", c.rs2_get_device_info(d, c.RS2_CAMERA_INFO_FIRMWARE_VERSION, &e));
    check_error(e);
}

pub fn main() !void {
    var rs_err: ?*c.rs2_error = null;
    var rs_ctx: ?*c.rs2_context = c.rs2_create_context(c.RS2_API_VERSION, &rs_err);
    _ = rs_ctx;
    std.debug.print("Realsense2 version {}\n", .{c.RS2_API_VERSION});
    // c.rs2_
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
