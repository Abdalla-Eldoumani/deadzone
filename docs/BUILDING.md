# Building

## Requirements

Linux, native or WSL. You need the AArch64 cross toolchain, QEMU user-mode, m4
and make.

```bash
# Ubuntu / Debian / WSL
sudo apt install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
                 qemu-user qemu-user-static m4 make

# Arch
sudo pacman -S aarch64-linux-gnu-gcc aarch64-linux-gnu-binutils \
               qemu-user qemu-user-static m4 make
```

`make verify` checks that all of it is on your PATH.

## Build and run

```bash
make        # m4 src/main.asm > src/main.s, then as, then gcc -static
make run    # qemu-aarch64 ./deadzone
```

`main.asm` carries eleven `include()` lines, so m4 pastes all twelve modules
into one assembly unit before GAS sees any of it. `constants.asm` has to come
first: `name = value` equates are positional in GAS.

The game needs a real terminal at 80x24 or larger. It puts the terminal in raw
mode with `ioctl(TCSETS)` and reads stdin non-blocking, so a pipe or a redirect
will not work.

Run it from the repository root: the save path `data/deadzone.sav` is relative
to the working directory.

## Targets

| Target | What it does |
|--------|--------------|
| `all` | Build `deadzone` (default) |
| `run` | Build, then run under QEMU |
| `debug` | Run under QEMU with a GDB server on port 1234 |
| `clean` | Remove `.s`, `.o` and the executable |
| `verify` | Check the toolchain |
| `show-asm` | Print the m4 output |
| `help` | List targets |

## Debugging

```bash
make debug
# in another terminal
gdb-multiarch ./deadzone
(gdb) target remote localhost:1234
(gdb) break main
(gdb) continue
```

Line numbers in the debugger refer to the generated `src/main.s`, not to the
`.asm` sources, because that is what the assembler saw.

## Troubleshooting

**`m4`, `aarch64-linux-gnu-as` or `qemu-aarch64` not found.** Install the
matching package from the list above; `make verify` says which one is missing.

**Nothing renders, or the layout falls apart.** The screen is a fixed 80x24.
Below 80 columns every row wraps.

**The terminal is left in raw mode.** The game restores it on every exit path,
but SIGKILL gives it no chance to. `reset` fixes the terminal.

**No high scores after a run.** The save is written when you die, not when you
quit from the menu, and it lands in `data/` relative to where you started the
program.
