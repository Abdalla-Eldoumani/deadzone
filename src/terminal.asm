/* terminal.asm - Terminal Control and ANSI Rendering
    @Author - Abdalla Eldoumani
    * Handles terminal raw mode setup/restore using termios
    * Provides ANSI escape code functions for rendering
    * Functions: terminal_init, terminal_restore, screen_clear,
    *            cursor_move, cursor_hide, cursor_show, set_color,
    *            reset_color, write_char, write_str, write_num
    * NOTE: This file is included by main.asm via m4
*/

// ============== REGISTER ALIASES ==============
define(syscall_num, x8)                         // Syscall number
define(fd_reg, x0)                              // File descriptor
define(buf_reg, x1)                             // Buffer pointer
define(len_reg, x2)                             // Length/count
define(ret_val, x0)                             // Return value

// ============== DATA SECTION ==============
                .data

// Original termios storage (60 bytes aligned to 8)
                .balign 8
old_termios:    .skip   TERMIOS_SIZE            // Original terminal settings

// New termios storage
                .balign 8
new_termios:    .skip   TERMIOS_SIZE            // Modified terminal settings

// Terminal initialized flag
term_init:      .word   0                       // 0 = not initialized

// ============== BSS SECTION (writable, zero-initialized) ==============
                .bss
                .balign 8
ansi_buffer:    .skip   32                      // Buffer for ANSI sequences

// ============== TEXT SECTION ==============
                .text

// ANSI escape sequences
ansi_clear:     .string "\x1b[2J"               // Clear entire screen
ansi_clear_len = . - ansi_clear - 1

ansi_home:      .string "\x1b[H"                // Cursor to home (1,1)
ansi_home_len = . - ansi_home - 1

ansi_hide:      .string "\x1b[?25l"             // Hide cursor
ansi_hide_len = . - ansi_hide - 1

ansi_show:      .string "\x1b[?25h"             // Show cursor
ansi_show_len = . - ansi_show - 1

ansi_reset:     .string "\x1b[0m"               // Reset all attributes
ansi_reset_len = . - ansi_reset - 1

                .balign 4

// ============================================================================
// terminal_init - Initialize terminal in raw mode
// Saves current settings and configures for game input
// Returns: 0 on success, -1 on failure
// ============================================================================
                .global terminal_init
terminal_init:
                stp     fp, lr, [sp, -16]!      // Save frame pointer and link
                mov     fp, sp                  // Establish frame pointer

                // Get current terminal attributes
                mov     x0, STDIN               // File descriptor
                mov     x1, TCGETS              // TCGETS request
                adrp    x2, old_termios         // Pointer to termios struct
                add     x2, x2, :lo12:old_termios
                mov     x8, SYS_IOCTL           // ioctl syscall
                svc     0                       // Execute syscall
                cmp     x0, 0                   // Check for error
                b.lt    terminal_init_fail      // Branch if failed

                // Copy old_termios to new_termios
                adrp    x0, old_termios         // Source
                add     x0, x0, :lo12:old_termios
                adrp    x1, new_termios         // Destination
                add     x1, x1, :lo12:new_termios
                mov     x2, TERMIOS_SIZE        // Size to copy
                bl      memcpy_simple           // Copy the structure

                // Modify local flags: disable ICANON, ECHO, ISIG, IEXTEN
                adrp    x0, new_termios         // Get new_termios address
                add     x0, x0, :lo12:new_termios
                ldr     w1, [x0, TERMIOS_LFLAG] // Load current lflag
                mov     w2, ICANON              // Canonical mode flag
                orr     w2, w2, ECHO            // OR with echo flag
                orr     w2, w2, ISIG            // OR with signal flag
                orr     w2, w2, IEXTEN          // OR with extended flag
                bic     w1, w1, w2              // Clear these flags
                str     w1, [x0, TERMIOS_LFLAG] // Store modified lflag

                // Modify input flags: disable ICRNL, IXON
                ldr     w1, [x0, TERMIOS_IFLAG] // Load current iflag
                mov     w2, ICRNL               // CR to NL flag
                orr     w2, w2, IXON            // XON/XOFF flag
                bic     w1, w1, w2              // Clear these flags
                str     w1, [x0, TERMIOS_IFLAG] // Store modified iflag

                // Set VMIN = 0, VTIME = 0 for non-blocking reads
                add     x1, x0, TERMIOS_CC      // Point to c_cc array
                mov     w2, 0                   // Value 0
                strb    w2, [x1, TERMIOS_CC_VMIN]  // VMIN = 0
                strb    w2, [x1, TERMIOS_CC_VTIME] // VTIME = 0

                // Apply new terminal attributes
                mov     x0, STDIN               // File descriptor
                mov     x1, TCSETS              // TCSETS request
                adrp    x2, new_termios         // Pointer to new termios
                add     x2, x2, :lo12:new_termios
                mov     x8, SYS_IOCTL           // ioctl syscall
                svc     0                       // Execute syscall
                cmp     x0, 0                   // Check for error
                b.lt    terminal_init_fail      // Branch if failed

                // VMIN/VTIME above is a tty setting, so a host that honours
                // only the descriptor's own flags would still block in read().
                // Ask for non-blocking stdin both ways.
                mov     x0, STDIN               // File descriptor
                mov     x1, F_GETFL             // Read current status flags
                mov     x8, SYS_FCNTL           // fcntl syscall
                svc     0                       // Execute syscall

                orr     x2, x0, O_NONBLOCK      // Add the non-blocking bit
                mov     x0, STDIN               // File descriptor
                mov     x1, F_SETFL             // Write status flags back
                mov     x8, SYS_FCNTL           // fcntl syscall
                svc     0                       // Execute syscall

                // Set initialized flag
                adrp    x0, term_init           // Get flag address
                add     x0, x0, :lo12:term_init
                mov     w1, 1                   // Set to true
                str     w1, [x0]                // Store flag

                // Hide cursor and clear screen
                bl      cursor_hide             // Hide the cursor
                bl      screen_clear            // Clear the screen

                mov     x0, 0                   // Return success
                ldp     fp, lr, [sp], 16        // Restore and return
                ret

terminal_init_fail:
                mov     x0, -1                  // Return failure
                ldp     fp, lr, [sp], 16        // Restore and return
                ret

// ============================================================================
// terminal_restore - Restore original terminal settings
// Should be called before program exit
// Returns: 0 on success, -1 on failure
// ============================================================================
                .global terminal_restore
terminal_restore:
                stp     fp, lr, [sp, -16]!      // Save registers
                mov     fp, sp                  // Establish frame pointer

                // Check if terminal was initialized
                adrp    x0, term_init           // Get flag address
                add     x0, x0, :lo12:term_init
                ldr     w0, [x0]                // Load flag
                cbz     w0, restore_done        // Skip if not initialized

                // Show cursor first
                bl      cursor_show             // Show the cursor

                // Reset colors
                bl      reset_color             // Reset to default

                // Restore original terminal attributes
                mov     x0, STDIN               // File descriptor
                mov     x1, TCSETS              // TCSETS request
                adrp    x2, old_termios         // Pointer to old termios
                add     x2, x2, :lo12:old_termios
                mov     x8, SYS_IOCTL           // ioctl syscall
                svc     0                       // Execute syscall
                cmp     x0, 0                   // Check for error
                b.lt    restore_fail            // Branch if failed

                // Clear initialized flag
                adrp    x0, term_init           // Get flag address
                add     x0, x0, :lo12:term_init
                mov     w1, 0                   // Set to false
                str     w1, [x0]                // Store flag

restore_done:
                mov     x0, 0                   // Return success
                ldp     fp, lr, [sp], 16        // Restore and return
                ret

restore_fail:
                mov     x0, -1                  // Return failure
                ldp     fp, lr, [sp], 16        // Restore and return
                ret

// ============================================================================
// screen_clear - Clear the entire screen
// ============================================================================
                .global screen_clear
screen_clear:
                stp     fp, lr, [sp, -16]!      // Save registers
                mov     fp, sp                  // Establish frame pointer

                // Write clear sequence
                mov     x0, STDOUT              // File descriptor
                adrp    x1, ansi_clear          // Clear sequence
                add     x1, x1, :lo12:ansi_clear
                mov     x2, ansi_clear_len      // Length
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

                // Move cursor to home
                mov     x0, STDOUT              // File descriptor
                adrp    x1, ansi_home           // Home sequence
                add     x1, x1, :lo12:ansi_home
                mov     x2, ansi_home_len       // Length
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

                ldp     fp, lr, [sp], 16        // Restore and return
                ret

// ============================================================================
// cursor_home - Move cursor to top-left corner (1,1)
// ============================================================================
                .global cursor_home
cursor_home:
                stp     fp, lr, [sp, -16]!      // Save registers
                mov     fp, sp                  // Establish frame pointer

                mov     x0, STDOUT              // File descriptor
                adrp    x1, ansi_home           // Home sequence
                add     x1, x1, :lo12:ansi_home
                mov     x2, ansi_home_len       // Length
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

                ldp     fp, lr, [sp], 16        // Restore and return
                ret

// ============================================================================
// cursor_move - Move cursor to position (x, y)
// Parameters: w0 = x (column, 0-based), w1 = y (row, 0-based)
// ANSI uses 1-based coordinates, so we add 1
// ============================================================================
                .global cursor_move
cursor_move:
                stp     fp, lr, [sp, -32]!      // Save registers + locals
                mov     fp, sp                  // Establish frame pointer
                stp     x19, x20, [sp, 16]      // Save callee-saved regs

                add     w19, w0, 1              // x + 1 (1-based column)
                add     w20, w1, 1              // y + 1 (1-based row)

                // Build escape sequence: \x1b[{row};{col}H
                adrp    x0, ansi_buffer         // Buffer for sequence
                add     x0, x0, :lo12:ansi_buffer

                // Write ESC [
                mov     w1, 0x1b                // ESC character
                strb    w1, [x0], 1             // Store and advance
                mov     w1, '['                 // [ character
                strb    w1, [x0], 1             // Store and advance

                // Convert row (y) to ASCII
                mov     w1, w20                 // Row number
                bl      write_num_to_buf        // Write number, returns new ptr

                // Write semicolon (numeric: an assembler that treats ;
                // as a comment would cut the line at the character form)
                mov     w1, 59
                strb    w1, [x0], 1             // Store and advance

                // Convert column (x) to ASCII
                mov     w1, w19                 // Column number
                bl      write_num_to_buf        // Write number, returns new ptr

                // Write H terminator
                mov     w1, 'H'                 // H character
                strb    w1, [x0], 1             // Store and advance

                // Calculate length and write
                adrp    x1, ansi_buffer         // Buffer start
                add     x1, x1, :lo12:ansi_buffer
                sub     x2, x0, x1              // Calculate length
                mov     x0, STDOUT              // File descriptor
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

                ldp     x19, x20, [sp, 16]      // Restore callee-saved
                ldp     fp, lr, [sp], 32        // Restore and return
                ret

// ============================================================================
// cursor_hide - Hide the cursor
// ============================================================================
                .global cursor_hide
cursor_hide:
                stp     fp, lr, [sp, -16]!      // Save registers
                mov     fp, sp                  // Establish frame pointer

                mov     x0, STDOUT              // File descriptor
                adrp    x1, ansi_hide           // Hide sequence
                add     x1, x1, :lo12:ansi_hide
                mov     x2, ansi_hide_len       // Length
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

                ldp     fp, lr, [sp], 16        // Restore and return
                ret

// ============================================================================
// cursor_show - Show the cursor
// ============================================================================
                .global cursor_show
cursor_show:
                stp     fp, lr, [sp, -16]!      // Save registers
                mov     fp, sp                  // Establish frame pointer

                mov     x0, STDOUT              // File descriptor
                adrp    x1, ansi_show           // Show sequence
                add     x1, x1, :lo12:ansi_show
                mov     x2, ansi_show_len       // Length
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

                ldp     fp, lr, [sp], 16        // Restore and return
                ret

// ============================================================================
// set_color - Set foreground color
// Parameters: w0 = color code (30-37 or 90-97)
// ============================================================================
                .global set_color
set_color:
                stp     fp, lr, [sp, -32]!      // Save registers
                mov     fp, sp                  // Establish frame pointer
                str     x19, [sp, 16]           // Save callee-saved

                mov     w19, w0                 // Save color code

                // Build escape sequence: \x1b[{color}m
                adrp    x0, ansi_buffer         // Buffer for sequence
                add     x0, x0, :lo12:ansi_buffer

                // Write ESC [
                mov     w1, 0x1b                // ESC character
                strb    w1, [x0], 1             // Store and advance
                mov     w1, '['                 // [ character
                strb    w1, [x0], 1             // Store and advance

                // Write color code
                mov     w1, w19                 // Color code
                bl      write_num_to_buf        // Write number

                // Write m terminator
                mov     w1, 'm'                 // m character
                strb    w1, [x0], 1             // Store and advance

                // Calculate length and write
                adrp    x1, ansi_buffer         // Buffer start
                add     x1, x1, :lo12:ansi_buffer
                sub     x2, x0, x1              // Calculate length
                mov     x0, STDOUT              // File descriptor
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

                ldr     x19, [sp, 16]           // Restore callee-saved
                ldp     fp, lr, [sp], 32        // Restore and return
                ret

// ============================================================================
// reset_color - Reset to default colors
// ============================================================================
                .global reset_color
reset_color:
                stp     fp, lr, [sp, -16]!      // Save registers
                mov     fp, sp                  // Establish frame pointer

                mov     x0, STDOUT              // File descriptor
                adrp    x1, ansi_reset          // Reset sequence
                add     x1, x1, :lo12:ansi_reset
                mov     x2, ansi_reset_len      // Length
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

                ldp     fp, lr, [sp], 16        // Restore and return
                ret

// ============================================================================
// write_char - Write a single character to stdout
// Parameters: w0 = character to write
// ============================================================================
                .global write_char
write_char:
                stp     fp, lr, [sp, -32]!      // Save registers
                mov     fp, sp                  // Establish frame pointer

                // Store character on stack
                strb    w0, [sp, 16]            // Store char at sp+16

                mov     x0, STDOUT              // File descriptor
                add     x1, sp, 16              // Pointer to character
                mov     x2, 1                   // Length = 1
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

                ldp     fp, lr, [sp], 32        // Restore and return
                ret

// ============================================================================
// write_str - Write a null-terminated string to stdout
// Parameters: x0 = pointer to string
// Returns: number of characters written
// ============================================================================
                .global write_str
write_str:
                stp     fp, lr, [sp, -32]!      // Save registers
                mov     fp, sp                  // Establish frame pointer
                str     x19, [sp, 16]           // Save callee-saved

                mov     x19, x0                 // Save string pointer

                // Calculate string length
                mov     x1, x0                  // Copy pointer
strlen_loop:
                ldrb    w2, [x1], 1             // Load byte and advance
                cbnz    w2, strlen_loop         // Continue if not null
                sub     x2, x1, x0              // Length = end - start
                sub     x2, x2, 1               // Minus null terminator

                cbz     x2, write_str_done      // Skip if empty

                mov     x1, x19                 // String pointer
                mov     x0, STDOUT              // File descriptor
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

write_str_done:
                ldr     x19, [sp, 16]           // Restore callee-saved
                ldp     fp, lr, [sp], 32        // Restore and return
                ret

// ============================================================================
// write_num - Write an integer to stdout
// Parameters: w0 = number to write
// ============================================================================
                .global write_num
write_num:
                stp     fp, lr, [sp, -48]!      // Save registers + buffer
                mov     fp, sp                  // Establish frame pointer

                mov     w1, w0                  // Save number FIRST
                add     x0, sp, 32              // Point to buffer end
                mov     x2, x0                  // Save buffer end

                // Handle negative numbers
                cmp     w1, 0                   // Check if negative
                b.ge    write_num_positive      // Branch if positive

                neg     w1, w1                  // Make positive
                mov     w3, 1                   // Set negative flag
                b       write_num_convert

write_num_positive:
                mov     w3, 0                   // Clear negative flag

write_num_convert:
                // Convert number to digits (reverse order)
                mov     w4, 10                  // Divisor

write_num_loop:
                udiv    w5, w1, w4              // Quotient
                msub    w6, w5, w4, w1          // Remainder = num - quot*10
                add     w6, w6, '0'             // Convert to ASCII
                sub     x0, x0, 1               // Move buffer pointer back
                strb    w6, [x0]                // Store digit
                mov     w1, w5                  // num = quotient
                cbnz    w1, write_num_loop      // Continue if not zero

                // Add minus sign if negative
                cbz     w3, write_num_output    // Skip if positive
                sub     x0, x0, 1               // Move buffer pointer back
                mov     w6, '-'                 // Minus sign
                strb    w6, [x0]                // Store minus

write_num_output:
                // Write the number
                mov     x1, x0                  // Buffer pointer
                sub     x2, x2, x0              // Calculate length
                mov     x0, STDOUT              // File descriptor
                mov     x8, SYS_WRITE           // write syscall
                svc     0                       // Execute

                ldp     fp, lr, [sp], 48        // Restore and return
                ret

// ============================================================================
// write_num_to_buf - Write number to buffer (helper for cursor_move)
// Parameters: x0 = buffer pointer, w1 = number
// Returns: x0 = updated buffer pointer
// ============================================================================
write_num_to_buf:
                stp     fp, lr, [sp, -48]!      // Save registers
                mov     fp, sp                  // Establish frame pointer
                stp     x19, x20, [sp, 16]      // Save callee-saved
                str     x21, [sp, 32]           // Save another reg

                mov     x19, x0                 // Save buffer pointer
                mov     w20, w1                 // Number to convert

                // Convert to temp buffer on stack (max 5 digits)
                add     x21, sp, 40             // Temp buffer end
                mov     x0, x21                 // Start at end

                mov     w4, 10                  // Divisor
num_buf_loop:
                udiv    w5, w20, w4             // Quotient
                msub    w6, w5, w4, w20         // Remainder
                add     w6, w6, '0'             // Convert to ASCII
                sub     x0, x0, 1               // Move back
                strb    w6, [x0]                // Store digit
                mov     w20, w5                 // num = quotient
                cbnz    w20, num_buf_loop       // Continue if not zero

                // Copy to output buffer
                mov     x1, x0                  // Source (temp buffer)
num_copy_loop:
                ldrb    w2, [x1], 1             // Load digit
                strb    w2, [x19], 1            // Store and advance
                cmp     x1, x21                 // At end?
                b.lt    num_copy_loop           // Continue if not

                mov     x0, x19                 // Return updated pointer

                ldr     x21, [sp, 32]           // Restore reg
                ldp     x19, x20, [sp, 16]      // Restore callee-saved
                ldp     fp, lr, [sp], 48        // Restore and return
                ret

// ============================================================================
// memcpy_simple - Simple memory copy
// Parameters: x0 = source, x1 = dest, x2 = count
// ============================================================================
memcpy_simple:
                cbz     x2, memcpy_done         // Return if count is 0
memcpy_loop:
                ldrb    w3, [x0], 1             // Load byte from source
                strb    w3, [x1], 1             // Store to dest
                subs    x2, x2, 1               // Decrement count
                b.ne    memcpy_loop             // Continue if not done
memcpy_done:
                ret
