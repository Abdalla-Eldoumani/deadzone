# DEADZONE

A terminal-based survival game written in ARMv8 AArch64 assembly.

## About

DEADZONE is a Vampire Survivors-style horde game rendered entirely in the terminal using ANSI escape codes. Survive waves of zombies, collect XP, level up, and see how far you can get.

Written in pure ARM64 assembly as a demonstration of low-level programming.

## Quick Start

```bash
# Install dependencies (Ubuntu/Debian/WSL)
sudo apt install gcc-aarch64-linux-gnu qemu-user m4 make

# Build
make

# Play
make run
```

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrows | Move |
| SPACE | Bomb (kills all enemies) |
| F | Freeze (stops enemies) |
| ESC | Quit |

Weapons fire automatically. Focus on dodging.

## Project Structure

```
deadzone/
├── Makefile        # Build system
├── README.md       # This file
├── src/            # Assembly source files
│   ├── main.asm    # Entry point, game loop
│   ├── player.asm  # Player logic
│   ├── enemies.asm # Enemy system
│   ├── effects.asm # Particles, screen shake
│   ├── boss.asm    # Boss fights
│   └── ...         # Other modules
├── docs/           # Documentation
│   ├── ARCHITECTURE.md
│   ├── BUILDING.md
│   └── GAMEPLAY.md
└── data/           # Save files
```

## Documentation

- [Building](docs/BUILDING.md) - Build instructions and dependencies
- [Gameplay](docs/GAMEPLAY.md) - How to play, controls, mechanics
- [Architecture](docs/ARCHITECTURE.md) - Technical overview for developers

## Requirements

- Linux (native or WSL)
- ARM64 cross-compiler (`aarch64-linux-gnu-gcc`)
- QEMU user-mode (`qemu-aarch64`)
- m4, make

## Author

Abdalla Eldoumani

## License

MIT