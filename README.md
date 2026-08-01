# DEADZONE

A terminal survivor written in ARMv8 AArch64 assembly. Waves of enemies close
in from the edges, your gun fires itself, and you pick an upgrade every time
you level. Reach wave 10 and the Titan turns up.

Play it in the browser, no toolchain needed:
https://aarch64-playground.vercel.app/playground?example=deadzone

## Quick start

```bash
sudo apt install gcc-aarch64-linux-gnu qemu-user m4 make
make
make run
```

Needs an 80x24 terminal or larger.

## Controls

| Key | Action |
|-----|--------|
| `w` `a` `s` `d` or arrows | Move |
| space | Bomb: clears every enemy on screen, 20 s cooldown |
| `f` | Freeze: stops every enemy for 3 s, 15 s cooldown |
| `1` `2` `3` | Take an upgrade on level up |
| `p` | Pause |
| `r` / `m` | Restart / back to menu, on the game over screen |
| `q` or escape | Quit |

The gun aims itself at the nearest enemy. Your job is to not get touched.

## What is in it

- Three enemy types with their own health, speed and XP value, mixed in by wave
- Six upgrades over five levels each, offered three at a time
- Two abilities on cooldowns: a screen-clearing bomb and a freeze
- A wave 10 boss with two phases, minions, and a health bar across the top rule
- Particles, floating damage numbers and screen shake
- Eight achievements, top five high scores and lifetime statistics, all kept in
  a 120-byte binary save at `data/deadzone.sav`

## How it draws

Every frame is staged in a cell buffer and compared against what the terminal
is already showing; only the cells that changed go out, batched into a single
`write`. A frame where nothing moves costs no output at all.
`docs/ARCHITECTURE.md` has the detail.

## Project layout

```
Makefile          m4 -> as -> gcc -static, plus run and verify targets
src/              twelve modules; main.asm includes the other eleven via m4
docs/             BUILDING, GAMEPLAY, ARCHITECTURE
data/             where the save file lands
```

## Documentation

- [Building](docs/BUILDING.md) - toolchain, targets, troubleshooting
- [Gameplay](docs/GAMEPLAY.md) - controls, enemies, upgrades, achievements
- [Architecture](docs/ARCHITECTURE.md) - modules, state machine, renderer, save format

## Requirements

Linux (native or WSL), `aarch64-linux-gnu-gcc`, `qemu-aarch64`, m4, make.

## Author

Abdalla Eldoumani

## License

MIT
