const std = @import("std");
const core = @import("core");
const kernal = @import("kernal");

comptime {
    @import("zrt0").init();
}

const LedMode = enum(u32) {
    heartbeat,
    on,
    off,
};

const Command = union(enum) {
    help: void,
    tasks: void,
    uptime: void,
    led: LedMode,
};

const HEARTBEAT_PULSE_MS = 100;
const HEARTBEAT_PAUSE_MS = 700;
const LED_MODE_POLL_MS = 25;
const COMPUTE_WORK_ITERATIONS = 5_000_000;
const ERASE_PREVIOUS_CHARACTER = [_]u8{
    std.ascii.control_code.bs,
    ' ',
    std.ascii.control_code.bs,
};

var led_mode: u32 align(4) = @intFromEnum(LedMode.heartbeat);

fn currentLedMode() LedMode {
    const mode: *const volatile u32 = &led_mode;
    return @enumFromInt(mode.*);
}

fn setLedMode(mode: LedMode) void {
    const shared_mode: *volatile u32 = &led_mode;
    shared_mode.* = @intFromEnum(mode);
}

fn waitWhileMode(expected_mode: LedMode, duration_ms: u64) bool {
    const deadline = core.timer.milliseconds() + duration_ms;
    while (currentLedMode() == expected_mode and core.timer.milliseconds() < deadline) {
        asm volatile ("nop");
    }
    return currentLedMode() == expected_mode;
}

fn ledTask() noreturn {
    while (true) switch (currentLedMode()) {
        .on => {
            core.gpio.turnOnLED();
            _ = waitWhileMode(.on, LED_MODE_POLL_MS);
        },
        .off => {
            core.gpio.turnOffLED();
            _ = waitWhileMode(.off, LED_MODE_POLL_MS);
        },
        .heartbeat => {
            core.gpio.turnOnLED();
            if (!waitWhileMode(.heartbeat, HEARTBEAT_PULSE_MS)) continue;
            core.gpio.turnOffLED();
            if (!waitWhileMode(.heartbeat, HEARTBEAT_PULSE_MS)) continue;
            core.gpio.turnOnLED();
            if (!waitWhileMode(.heartbeat, HEARTBEAT_PULSE_MS)) continue;
            core.gpio.turnOffLED();
            _ = waitWhileMode(.heartbeat, HEARTBEAT_PAUSE_MS);
        },
    };
}

fn write(text: []const u8) void {
    core.uart.w_interface.writeAll(text) catch unreachable;
}

fn writePrompt() void {
    write("$ ");
}

fn printBanner() void {
    write(
        "\r\n" ++
            "zig-rp2040-lab\r\n" ++
            "Bare-metal RP2040 scheduler, written in Zig.\r\n" ++
            "Type 'help' to explore the lab.\r\n\r\n",
    );
    writePrompt();
}

fn printHelp() void {
    write(
        "Commands:\r\n" ++
            "  help           Show this command list\r\n" ++
            "  tasks          Describe the running workloads\r\n" ++
            "  uptime         Show milliseconds since boot\r\n" ++
            "  led on         Hold the onboard LED on\r\n" ++
            "  led off        Hold the onboard LED off\r\n" ++
            "  led heartbeat  Restore the double-blink heartbeat\r\n",
    );
}

fn printTasks() void {
    write(
        "led      Visual heartbeat and interactive LED control\r\n" ++
            "uart     Blocking command console (I/O-bound)\r\n" ++
            "compute  Synthetic busy work (CPU-bound)\r\n",
    );
}

fn parseCommand(input: []u8) ?Command {
    const normalized_input = std.ascii.lowerString(input, input);
    var tokens = std.mem.tokenizeAny(u8, normalized_input, " \t");
    const command_name = tokens.next() orelse return null;
    const command = std.meta.stringToEnum(std.meta.Tag(Command), command_name) orelse return null;
    const argument = tokens.next();
    if (tokens.next() != null) return null;

    return switch (command) {
        .help => .{ .help = {} },
        .tasks => .{ .tasks = {} },
        .uptime => .{ .uptime = {} },
        .led => .{ .led = std.meta.stringToEnum(LedMode, argument orelse return null) orelse return null },
    };
}

fn runCommand(input: []u8) void {
    if (std.mem.trim(u8, input, " \t").len == 0) return;
    const command = parseCommand(input) orelse {
        write("Unknown command. Type 'help'.\r\n");
        return;
    };

    switch (command) {
        .help => printHelp(),
        .tasks => printTasks(),
        .uptime => core.uart.w_interface.print("Uptime: {d} ms\r\n", .{core.timer.milliseconds()}) catch unreachable,
        .led => |mode| {
            setLedMode(mode);
            core.uart.w_interface.print("LED mode: {s}\r\n", .{@tagName(mode)}) catch unreachable;
        },
    }
}

fn uartTask() noreturn {
    var receive_buffer: [16]u8 = undefined;
    var line_buffer: [64]u8 = undefined;
    var line_length: usize = 0;
    var line_overflowed = false;
    var previous_was_cr = false;

    printBanner();

    while (true) {
        const count = kernal.uart.read(&receive_buffer);
        for (receive_buffer[0..count]) |byte| {
            if (byte == '\n' and previous_was_cr) {
                previous_was_cr = false;
                continue;
            }

            if (byte == '\r' or byte == '\n') {
                write("\r\n");
                if (line_overflowed) {
                    write("Input too long. Type 'help'.\r\n");
                } else {
                    runCommand(line_buffer[0..line_length]);
                }
                line_length = 0;
                line_overflowed = false;
                previous_was_cr = byte == '\r';
                writePrompt();
                continue;
            }

            previous_was_cr = false;

            if (byte == std.ascii.control_code.bs or byte == std.ascii.control_code.del) {
                if (!line_overflowed and line_length > 0) {
                    line_length -= 1;
                    write(&ERASE_PREVIOUS_CHARACTER);
                }
                continue;
            }

            if (!std.ascii.isPrint(byte)) continue;
            if (line_length == line_buffer.len) {
                line_overflowed = true;
                continue;
            }

            if (!line_overflowed) {
                line_buffer[line_length] = byte;
                line_length += 1;
                core.uart.putChar(byte);
            }
        }
    }
}

fn computeTask() noreturn {
    while (true) {
        var iteration: u32 = 0;
        while (iteration < COMPUTE_WORK_ITERATIONS) : (iteration += 1) {
            asm volatile ("nop");
        }
    }
}

pub const SCHEDULER_ALGORITHM = kernal.SchedulingAlgorithms.multilevel_feedback_queue;
pub const SCHEDULER_MODE = kernal.SchedulerMode.multi_core;
pub const MLFQ_LEVEL_COUNT = 5;

pub fn registerTasks() kernal.task.TaskGroup {
    return .{
        .task_entries = &.{
            .{ .name = "led", .entry = ledTask },
            .{ .name = "uart", .entry = uartTask },
            .{ .name = "compute", .entry = computeTask },
        },
    };
}
