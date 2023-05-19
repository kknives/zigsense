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
    defer c.rs2_delete_context(rs_ctx);
    check_error(rs_err);
    const rs_dev_list: ?*c.rs2_device_list = c.rs2_query_devices(rs_ctx, &rs_err);
    defer c.rs2_delete_device_list(rs_dev_list);
    check_error(rs_err);
    const rs_dev_count: ?c_int = c.rs2_get_device_count(rs_dev_list, &rs_err);
    std.debug.print("There are {?} connected Realsenses\n", .{rs_dev_count});
    std.debug.print("Realsense2 version {}\n", .{c.RS2_API_VERSION});

    const rs_dev: ?*c.rs2_device = c.rs2_create_device(rs_dev_list, 0, &rs_err);
    defer c.rs2_delete_device(rs_dev);
    check_error(rs_err);
    print_device_info(rs_dev);
    check_error(rs_err);

    const pipeline: ?*c.rs2_pipeline = c.rs2_create_pipeline(rs_ctx, &rs_err);
    defer c.rs2_delete_pipeline(pipeline);
    check_error(rs_err);

    const config: ?*c.rs2_config = c.rs2_create_config(&rs_err);
    defer c.rs2_delete_config(config);
    check_error(rs_err);
    const stream_params = .{ .stream = c.RS2_STREAM_DEPTH, .format = c.RS2_FORMAT_Z16, .width = 640, .height = 0, .fps = 30, .stream_index = 0 };
    c.rs2_config_enable_stream(config, stream_params.stream, stream_params.stream_index, stream_params.width, stream_params.height, stream_params.format, stream_params.fps, &rs_err);
    check_error(rs_err);

    _ = c.rs2_pipeline_start_with_config(pipeline, config, &rs_err);
    if (rs_err) |_| {
        std.debug.print("This device does not support depth streaming\n", .{});
        return;
    }
    while (true) {
        const frames: ?*c.rs2_frame = c.rs2_pipeline_wait_for_frames(pipeline, c.RS2_DEFAULT_TIMEOUT, &rs_err);
        defer c.rs2_release_frame(frames);
        check_error(rs_err);
        const frame_len: i32 = @as(i32, c.rs2_embedded_frames_count(frames, &rs_err));
        check_error(rs_err);
        var i: i32 = 0;
        inner: while (i < frame_len) : (i += 1) {
            const frame: ?*c.rs2_frame = c.rs2_extract_frame(frames, i, &rs_err);
            defer c.rs2_release_frame(frame);
            check_error(rs_err);
            if (frame == null) continue :inner;
            if (0 == c.rs2_is_frame_extendable_to(frame, c.RS2_EXTENSION_DEPTH_FRAME, &rs_err)) continue :inner;

            const width: c_int = c.rs2_get_frame_width(frame, &rs_err);
            check_error(rs_err);
            const height: c_int = c.rs2_get_frame_height(frame, &rs_err);
            check_error(rs_err);
            const dist_to_center: f32 = c.rs2_depth_frame_get_distance(frame, @divFloor(width, 2), @divFloor(height, 2), &rs_err);
            check_error(rs_err);
            std.debug.print("The camera is facing an object {d:.3} metres away.\n", .{dist_to_center});
        }
    }

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
