# Architecture

## Build

Twelve `.asm` modules become one compilation unit. `main.asm` carries eleven
`include()` lines and m4 pastes the modules in ahead of its own code, so there
is a single assembler pass and no linker step between modules.

```
main.asm --[m4]--> main.s --[as]--> main.o --[gcc -static]--> deadzone
```

`constants.asm` is included first because `name = value` equates are
positional in GAS: a use above the definition does not resolve.

## Modules

| File | Purpose |
|------|---------|
| `constants.asm` | Every shared equate: geometry, syscalls, termios, keys, colours, timing, states, pool sizes |
| `terminal.asm` | Raw mode, the frame buffer, and the flush that writes it |
| `input.asm` | One non-blocking byte a frame, plus arrow-key escape decoding |
| `player.asm` | Player struct, bounded movement, damage and invincibility, XP |
| `enemies.asm` | Enemy pool, edge spawning, chase AI, waves, and the RNG |
| `projectiles.asm` | Auto-fire, projectile movement, collision, `enemy_damage` |
| `upgrades.asm` | Upgrade levels, the three-way choice, the level-up menu |
| `file_io.asm` | The save file and the whole achievement system |
| `effects.asm` | Particles, damage numbers, screen shake |
| `boss.asm` | The Titan: AI, phases, sprite, health bar, minions |
| `abilities.asm` | Bomb and freeze, their cooldowns and their HUD row |
| `main.asm` | Entry point, state machine, input handling, all screen drawing |

There are no module-private sections. Pools are plain `.data` labels and
modules reach into each other by symbol, so there is no accessor boundary to
preserve.

## State machine

```
STATE_INTRO = 0     title animation, any key after frame 120 leaves it
STATE_MENU = 1      Start / High Scores / Quit
STATE_PLAYING = 2   the game
STATE_PAUSED = 3    frozen, p resumes
STATE_GAMEOVER = 4  final stats and the high score table
STATE_QUIT = 5      leaves the loop
STATE_LEVELUP = 6   upgrade choice drawn over the field
```

The state lives in `w19` for the whole run. `player_died` deliberately does
**not** restore `x19` on its way out of `check_player_enemy_collision`: leaving
the register set is how the game-over state survives the return. Both collision
checks spill their death flag to the stack instead of using `w19`. Anything
that rebinds `w19` changes the game.

`STATE_PAUSED` freezes everything: the paused branch repaints the field and the
overlay and does nothing else, so no timer, cooldown, spawn or frame counter
advances.

## Rendering

Drawing never touches the terminal directly. `terminal.asm` keeps four
`SCREEN_WIDTH * SCREEN_HEIGHT` byte planes in `.bss`:

```
fb_char, fb_attr   the frame being staged
pv_char, pv_attr   what the terminal is currently showing
```

`cursor_move`, `set_color`, `write_char`, `write_str` and `write_num` all write
into `fb_*`. Once a frame is staged, `screen_flush` compares the planes eight
cells at a time, and only descends to individual cells inside a group that
differs. Changed cells are emitted as runs: one cursor address, one colour
change, then the glyphs, into a 4 KiB buffer that goes out as a single `write`.
A frame in which nothing moved emits nothing at all.

`screen_invalidate` zeroes `pv_*` so the next flush repaints every cell. State
changes call it: entering and leaving play, the pause overlay, the level-up
menu, and the boss arriving.

Two consequences worth knowing:

- Whole rows are laid down by `fb_fill_row`, which fills eight cells per store.
  The borders and the empty field cost a few hundred steps a frame instead of
  the twelve hundred single-character writes the old path used.
- The bell and the messages printed after the game gives the terminal back
  bypass the buffer through `term_write_raw` / `write_str_raw`, because they
  are not cells.

The screen is a fixed 80x24: row 0 title, row 1 top rule, rows 2-17 the play
field, row 18 bottom rule, rows 20 and 21 cleared each frame, row 22 the status
bar, row 23 the abilities HUD.

## Entities

Every pool is a fixed array of fixed-size structs with an active flag in byte 0.

| Pool | Slots | Bytes each |
|------|-------|------------|
| Enemies | 100 | 16 |
| Projectiles | 50 | 16 |
| Particles | 128 | 8 |
| Damage numbers | 20 | 8 |
| Boss | 1 | 24 |

`enemy_count` is kept in step with the active flags at every spawn, kill and
bomb. `enemies_check_collision` relies on that: it stops scanning once it has
seen that many live enemies, which is what keeps the per-projectile collision
pass cheap when the pool is sparse.

## Timing

There is no wall clock. `clock_gettime` is never called and every timer is a
frame count. `frame_delay` sleeps a fixed `FRAME_TIME_NS` (33,333,333 ns) with
`nanosleep`, so the loop runs at `TARGET_FPS` = 30 and does not compensate for
work already done in the frame.

Durations are therefore derived from `TARGET_FPS` rather than written as raw
frame counts, so the numbers the HUD prints and the numbers the code uses stay
in step: bomb cooldown `20 * TARGET_FPS`, freeze cooldown `15 * TARGET_FPS`,
freeze duration and the achievement banner `3 * TARGET_FPS`, and the Endurance
achievement `300 * TARGET_FPS`.

## Save file

`data/deadzone.sav`, opened with `openat(AT_FDCWD)` so it is relative to the
working directory. 120 bytes, written on death and read at startup.

```
+0    u32  magic 0x44414544 ("DEAD")
+4    u32  version 1
+8    5 x 16-byte score entries
        +0 u32 score, +4 u16 wave, +6 u32 kills, +10 u16 level, +12 pad
+88   32-byte stats block
        games, kills, time, best_wave, best_level, best_kills,
        achievements bitmask, pad
```

The achievement bitmask sits at offset 24 of the stats block, in what used to
be padding. `save_load` and `save_write` already copied the whole block byte
for byte, so nothing about the file size or the version changed and a version 1
file written before achievements were saved reads back as "nothing unlocked".

A missing file is not an error: `save_load` returns 0 and the game starts with
an empty table.

## Syscalls

`write`, `read`, `ioctl` (TCGETS/TCSETS), `fcntl`, `nanosleep`, `openat`,
`close`. No libc beyond two `printf` calls at startup; `main` returns rather
than calling `exit`.

Raw mode is set two ways on purpose. `ioctl(TCSETS)` clears `ICANON`, `ECHO`,
`ISIG` and `IEXTEN` and sets `VMIN` and `VTIME` to 0, and then
`fcntl(0, F_SETFL, O_NONBLOCK)` asks for the same thing at the descriptor. A
host that honours only the descriptor flags would otherwise block in `read`.
