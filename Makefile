# DEADZONE Makefile - ARMv8 AArch64 Cross-Compilation
# Target: ARM64 Linux
# Host: x86_64 Linux (WSL)

# Toolchain
AS = aarch64-linux-gnu-as
CC = aarch64-linux-gnu-gcc
LD = aarch64-linux-gnu-gcc
M4 = m4
QEMU = qemu-aarch64

# Flags
ASFLAGS = -g
LDFLAGS = -static

# Directories
SRC_DIR = src

# Main source file (includes other modules via m4)
MAIN_SRC = $(SRC_DIR)/main.asm
MAIN_S = $(SRC_DIR)/main.s
MAIN_O = $(SRC_DIR)/main.o

# Main target
TARGET = deadzone

# Source modules (for dependency tracking)
MODULES = $(SRC_DIR)/constants.asm \
          $(SRC_DIR)/terminal.asm \
          $(SRC_DIR)/input.asm \
          $(SRC_DIR)/player.asm \
          $(SRC_DIR)/enemies.asm \
          $(SRC_DIR)/projectiles.asm \
          $(SRC_DIR)/upgrades.asm \
          $(SRC_DIR)/file_io.asm \
          $(SRC_DIR)/effects.asm \
          $(SRC_DIR)/boss.asm \
          $(SRC_DIR)/abilities.asm

# Default target
all: $(TARGET)

# Preprocess main.asm with m4 (includes all modules)
$(MAIN_S): $(MAIN_SRC) $(MODULES)
	$(M4) $(MAIN_SRC) > $(MAIN_S)

# Assemble main.s to main.o
$(MAIN_O): $(MAIN_S)
	$(AS) $(ASFLAGS) $(MAIN_S) -o $(MAIN_O)

# Link to create executable
$(TARGET): $(MAIN_O)
	$(LD) $(LDFLAGS) $(MAIN_O) -o $(TARGET)
	@echo ""
	@echo "Build complete: $(TARGET)"
	@echo "Run with: make run"

# Run with QEMU
run: $(TARGET)
	$(QEMU) ./$(TARGET)

# Debug with GDB
debug: $(TARGET)
	@echo "Starting QEMU in debug mode on port 1234..."
	@echo "In another terminal:"
	@echo "  gdb-multiarch ./$(TARGET)"
	@echo "  (gdb) target remote localhost:1234"
	@echo ""
	$(QEMU) -g 1234 ./$(TARGET)

# Clean build artifacts
clean:
	rm -f $(SRC_DIR)/*.s $(SRC_DIR)/*.o
	rm -f $(TARGET)
	@echo "Clean complete"

# Show preprocessed assembly
show-asm: $(MAIN_S)
	@cat $(MAIN_S)

# Verify toolchain
verify:
	@echo "Checking toolchain..."
	@which $(AS) && $(AS) --version | head -n1
	@which $(CC) && $(CC) --version | head -n1
	@which $(M4) && $(M4) --version | head -n1
	@which $(QEMU) && $(QEMU) --version | head -n1
	@echo "Toolchain OK"

# Help
help:
	@echo "DEADZONE Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build the game (default)"
	@echo "  run      - Build and run with QEMU"
	@echo "  debug    - Run with GDB debugging"
	@echo "  clean    - Remove build artifacts"
	@echo "  verify   - Check toolchain installation"
	@echo "  help     - Show this help"

.PHONY: all run debug clean show-asm verify help
