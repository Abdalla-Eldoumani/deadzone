# Building

Instructions for building DEADZONE from source.

## Requirements

- Linux environment (native or WSL on Windows)
- ARM64 cross-compilation toolchain
- QEMU for ARM64 user-mode emulation
- m4 macro preprocessor
- GNU Make

## Installing Dependencies

### Ubuntu/Debian/WSL

```bash
sudo apt update
sudo apt install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
sudo apt install qemu-user qemu-user-static
sudo apt install m4 make
```

### Arch Linux

```bash
sudo pacman -S aarch64-linux-gnu-gcc aarch64-linux-gnu-binutils
sudo pacman -S qemu-user qemu-user-static
sudo pacman -S m4 make
```

## Verifying Toolchain

```bash
make verify
```

This checks that all required tools are installed and accessible.

## Building

```bash
make
```

This runs the full build pipeline:
1. Preprocesses `main.asm` with m4 (includes all modules)
2. Assembles to object file with `aarch64-linux-gnu-as`
3. Links with `aarch64-linux-gnu-gcc` (static linking)

Output: `deadzone` executable (ARM64 ELF binary)

## Running

```bash
make run
```

Runs the game using QEMU user-mode emulation. QEMU translates ARM64 instructions to your host architecture.

## Cleaning

```bash
make clean
```

Removes all build artifacts (`.s`, `.o` files and the executable).

## Debugging

```bash
make debug
```

Starts QEMU with GDB server on port 1234. In another terminal:

```bash
gdb-multiarch ./deadzone
(gdb) target remote localhost:1234
(gdb) break main
(gdb) continue
```

## Build Targets

| Target | Description |
|--------|-------------|
| `all` | Build the game (default) |
| `run` | Build and run with QEMU |
| `debug` | Run with GDB debugging |
| `clean` | Remove build artifacts |
| `verify` | Check toolchain installation |
| `show-asm` | Display preprocessed assembly |
| `help` | Show available targets |

## Troubleshooting

### "m4: command not found"
Install m4: `sudo apt install m4`

### "aarch64-linux-gnu-as: command not found"
Install cross-compiler: `sudo apt install gcc-aarch64-linux-gnu`

### "qemu-aarch64: command not found"
Install QEMU: `sudo apt install qemu-user`

### Game runs but no display
QEMU requires a terminal with proper TTY support. Run from a real terminal, not a pipe or redirect.

### Linker errors about libc
The build uses static linking (`-static`). Ensure `libc6-dev-arm64-cross` is installed if you get missing library errors.