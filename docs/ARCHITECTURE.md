# Architecture

Technical overview of the DEADZONE codebase.

## Build System

The project uses m4 preprocessor to combine multiple assembly files into a single compilation unit. `main.asm` includes all other modules via `include()` directives. The Makefile handles preprocessing, assembly, and linking.

```
main.asm --[m4]--> main.s --[as]--> main.o --[gcc]--> deadzone
```

## Source Modules

| File | Purpose |
|------|---------|
| `main.asm` | Entry point, game loop, state machine, screen drawing |
| `constants.asm` | Shared constants (screen size, colors, syscalls) |
| `terminal.asm` | Terminal raw mode, ANSI escape sequences, cursor control |
| `input.asm` | Non-blocking keyboard input via termios |
| `player.asm` | Player state, movement, damage, XP |
| `enemies.asm` | Enemy pool, spawning, AI movement |
| `projectiles.asm` | Auto-fire system, collision detection |
| `upgrades.asm` | Level-up choices, stat upgrades |
| `effects.asm` | Particle explosions, screen shake, damage numbers |
| `boss.asm` | Boss entity, multi-phase AI, ASCII sprite |
| `abilities.asm` | Special abilities (bomb, freeze) with cooldowns |
| `file_io.asm` | Save/load system, high score persistence |

## Game States

```
STATE_INTRO    -> Animated title screen
STATE_MENU     -> Main menu (Start, High Scores, Quit)
STATE_PLAYING  -> Active gameplay
STATE_PAUSED   -> Game paused
STATE_LEVELUP  -> Upgrade selection
STATE_GAMEOVER -> Death screen with stats
STATE_QUIT     -> Exit
```

## Entity Systems

### Enemy Pool
Fixed-size array of 100 enemy slots. Each enemy is 16 bytes:
- Position (X, Y)
- Health
- Type (Zombie, Runner, Tank)
- Speed
- XP value

### Projectile Pool
50 projectile slots. Auto-fire targets nearest enemy. Projectiles travel in 8 directions.

### Particle Pool
128 particles for death explosions. Each particle has position, velocity, lifetime, and character.

## Screen Layout

```
Row 0:     Title bar
Row 1:     Top border
Rows 2-17: Play area (16 rows)
Row 18:    Bottom border
Row 19-20: Cleared
Row 21:    Empty
Row 22:    Status bar (Wave, HP, Level, Enemies, Kills)
Row 23:    Abilities HUD ([SPACE] bomb, [F] freeze)
```

Screen is 80x24 characters. Play area bounds are defined in `player.asm`:
- `PLAY_LEFT = 1`
- `PLAY_RIGHT = 78`
- `PLAY_TOP = 2`
- `PLAY_BOTTOM = 17`

## Rendering

No double buffering. Each frame:
1. Move cursor home (ESC[H)
2. Redraw entire screen sequentially
3. Draw entities via cursor_move to absolute positions
4. Draw HUD elements

This minimizes flicker compared to full screen clear.

## Save System

Binary format stored in `data/deadzone.sav`:
- Magic number (0xDEAD)
- Version byte
- 5 high score entries (score, wave, kills, level)
- Achievement flags

## Conventions

### Registers
- `x29` (fp): Frame pointer
- `x30` (lr): Link register
- `x19-x28`: Callee-saved, used for persistent data across calls
- `x0-x18`: Caller-saved, used for temporaries and arguments

### Stack Frames
16-byte aligned. Standard prologue/epilogue:
```asm
stp  fp, lr, [sp, -N]!
mov  fp, sp
...
ldp  fp, lr, [sp], N
ret
```

### Syscalls
Linux AArch64 syscalls via `svc 0`. Syscall number in `x8`, arguments in `x0-x5`.