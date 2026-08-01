/* constants.asm - Shared Constants and Definitions
    @Author - Abdalla Eldoumani
    * Central repository for all constants, syscall numbers,
    * ANSI codes, and shared definitions used across modules
*/

// ============== REGISTER ALIASES (GLOBAL) ==============
fp              .req    x29                     // Frame pointer
lr              .req    x30                     // Link register

// ============== SCREEN DIMENSIONS ==============
SCREEN_WIDTH = 80                               // Terminal width in columns
SCREEN_HEIGHT = 24                              // Terminal height in rows
SCREEN_SIZE = SCREEN_WIDTH * SCREEN_HEIGHT      // Total screen characters

// ============== FILE DESCRIPTORS ==============
STDIN = 0                                       // Standard input
STDOUT = 1                                      // Standard output
STDERR = 2                                      // Standard error

// ============== LINUX SYSCALL NUMBERS (AArch64) ==============
SYS_FCNTL = 25                                  // fcntl(fd, cmd, arg)
SYS_IOCTL = 29                                  // ioctl(fd, request, arg)
SYS_OPENAT = 56                                 // openat(dirfd, path, flags, mode)
SYS_CLOSE = 57                                  // close(fd)
SYS_READ = 63                                   // read(fd, buf, count)
SYS_WRITE = 64                                  // write(fd, buf, count)
SYS_EXIT = 93                                   // exit(status)
SYS_NANOSLEEP = 101                             // nanosleep(req, rem)
SYS_CLOCK_GETTIME = 113                         // clock_gettime(clk_id, tp)

// ============== CLOCK IDS ==============
CLOCK_MONOTONIC = 1                             // Monotonic clock for timing

// ============== IOCTL REQUESTS (termios) ==============
TCGETS = 0x5401                                 // Get terminal attributes
TCSETS = 0x5402                                 // Set terminal attributes

// ============== TERMIOS STRUCTURE OFFSETS ==============
// struct termios size is 60 bytes on Linux ARM64
TERMIOS_SIZE = 60                               // Size of termios structure
TERMIOS_IFLAG = 0                               // Input flags offset (4 bytes)
TERMIOS_OFLAG = 4                               // Output flags offset (4 bytes)
TERMIOS_CFLAG = 8                               // Control flags offset (4 bytes)
TERMIOS_LFLAG = 12                              // Local flags offset (4 bytes)
TERMIOS_CC = 17                                 // Control characters offset
TERMIOS_CC_VMIN = 6                             // VMIN index in c_cc array
TERMIOS_CC_VTIME = 5                            // VTIME index in c_cc array

// ============== TERMIOS FLAG VALUES ==============
// Local flags (c_lflag)
ICANON = 0x0002                                 // Canonical mode
ECHO = 0x0008                                   // Echo input
ISIG = 0x0001                                   // Enable signals
IEXTEN = 0x8000                                 // Extended input processing

// Input flags (c_iflag)
ICRNL = 0x0100                                  // Map CR to NL
IXON = 0x0400                                   // Enable XON/XOFF flow control

// ============== FCNTL COMMANDS AND FILE STATUS FLAGS ==============
F_GETFL = 3                                     // Read the file status flags
F_SETFL = 4                                     // Write the file status flags
O_NONBLOCK = 0x800                              // Reads return instead of waiting

// ============== KEY CODES ==============
KEY_NONE = -1                                   // No key pressed
KEY_ESC = 27                                    // Escape key
KEY_SPACE = 32                                  // Space bar
KEY_ENTER = 10                                  // Enter/Return key (LF)
KEY_CR = 13                                     // Carriage return

// Movement keys
KEY_W = 119                                     // W key (up)
KEY_A = 97                                      // A key (left)
KEY_S = 115                                     // S key (down)
KEY_D = 100                                     // D key (right)
KEY_w = 119                                     // w key (same as W)
KEY_a = 97                                      // a key (same as A)
KEY_s = 115                                     // s key (same as S)
KEY_d = 100                                     // d key (same as D)

// Control keys
KEY_P = 112                                     // P key (pause)
KEY_p = 112                                     // p key (pause)
KEY_Q = 113                                     // Q key (quit)
KEY_q = 113                                     // q key (quit)

// Number keys (for upgrade selection)
KEY_1 = 49                                      // 1 key
KEY_2 = 50                                      // 2 key
KEY_3 = 51                                      // 3 key

// Arrow key escape sequences (after ESC [)
KEY_ARROW_UP = 65                               // Up arrow (ESC [ A)
KEY_ARROW_DOWN = 66                             // Down arrow (ESC [ B)
KEY_ARROW_RIGHT = 67                            // Right arrow (ESC [ C)
KEY_ARROW_LEFT = 68                             // Left arrow (ESC [ D)

// ============== ANSI COLOR CODES ==============
COLOR_RESET = 0                                 // Reset all attributes
COLOR_BLACK = 30                                // Black foreground
COLOR_RED = 31                                  // Red foreground
COLOR_GREEN = 32                                // Green foreground
COLOR_YELLOW = 33                               // Yellow foreground
COLOR_BLUE = 34                                 // Blue foreground
COLOR_MAGENTA = 35                              // Magenta foreground
COLOR_CYAN = 36                                 // Cyan foreground
COLOR_WHITE = 37                                // White foreground

// Bright colors
COLOR_BRIGHT_BLACK = 90                         // Bright black (gray)
COLOR_BRIGHT_RED = 91                           // Bright red
COLOR_BRIGHT_GREEN = 92                         // Bright green
COLOR_BRIGHT_YELLOW = 93                        // Bright yellow
COLOR_BRIGHT_BLUE = 94                          // Bright blue
COLOR_BRIGHT_MAGENTA = 95                       // Bright magenta
COLOR_BRIGHT_CYAN = 96                          // Bright cyan
COLOR_BRIGHT_WHITE = 97                         // Bright white

// Background colors (add 10 to foreground)
BG_BLACK = 40                                   // Black background
BG_RED = 41                                     // Red background
BG_GREEN = 42                                   // Green background
BG_YELLOW = 43                                  // Yellow background
BG_BLUE = 44                                    // Blue background
BG_MAGENTA = 45                                 // Magenta background
BG_CYAN = 46                                    // Cyan background
BG_WHITE = 47                                   // White background

// ============== GAME TIMING ==============
TARGET_FPS = 30                                 // Target frames per second
FRAME_TIME_NS = 33333333                        // Nanoseconds per frame (1/30 sec)
FRAME_TIME_SEC = 0                              // Seconds component of frame time

// ============== GAME STATES ==============
STATE_INTRO = 0                                 // Intro/title animation
STATE_MENU = 1                                  // Main menu
STATE_PLAYING = 2                               // Game in progress
STATE_PAUSED = 3                                // Game paused
STATE_GAMEOVER = 4                              // Game over screen
STATE_QUIT = 5                                  // Exit game
STATE_LEVELUP = 6                               // Level up selection screen

// ============== ENTITY LIMITS ==============
MAX_ENEMIES = 100                               // Maximum enemy count
MAX_PROJECTILES = 50                            // Maximum projectile count
MAX_PICKUPS = 30                                // Maximum pickup count

// ============== PLAYER DEFAULTS ==============
PLAYER_START_X = SCREEN_WIDTH / 2               // Starting X position
PLAYER_START_Y = SCREEN_HEIGHT / 2              // Starting Y position
PLAYER_START_HP = 100                           // Starting health
PLAYER_START_SPEED = 1                          // Starting movement speed

// ============== TIMESPEC STRUCTURE ==============
TIMESPEC_SIZE = 16                              // Size of timespec (8 + 8 bytes)
TIMESPEC_SEC = 0                                // Offset to tv_sec
TIMESPEC_NSEC = 8                               // Offset to tv_nsec

// ============== BOOLEAN VALUES ==============
FALSE = 0                                       // Boolean false
TRUE = 1                                        // Boolean true
