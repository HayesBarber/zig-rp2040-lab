pub export fn handler() callconv(.naked) void {
    asm volatile (
    // Save current task context
        \\mrs r0, psp

        // Reserve space for r4-r11
        \\subs r0, r0, #32

        // Save r4-r7
        \\stmia r0!, {r4-r7}

        // Save r8-r11 through low registers
        \\mov r4, r8
        \\mov r5, r9
        \\mov r6, r10
        \\mov r7, r11
        \\stmia r0!, {r4-r7}

        // r0 now points past saved context.
        // Move back to beginning of saved context.
        \\subs r0, r0, #32

        // Select next task
        // r0 = current task SP
        // r0 returned = next task SP
        \\bl schedulerSelectNext

        // Restore next task context
        // Restore r8-r11
        \\mov r1, r0
        \\adds r1, r1, #16
        \\ldmia r1!, {r4-r7}
        \\mov r8, r4
        \\mov r9, r5
        \\mov r10, r6
        \\mov r11, r7

        // Restore r4-r7
        \\ldmia r0!, {r4-r7}

        // PSP now points at hardware exception frame
        \\msr psp, r1

        // Return to Thread mode using PSP
        \\ldr r0, =0xFFFFFFFD
        \\mov lr, r0
        \\bx lr
    );
}
