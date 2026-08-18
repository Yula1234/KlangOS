TARGET      := build/kernel.elf

KLANG       := klang
NASM        := nasm
LD          := ld
QEMU        := qemu-system-x86_64

SRC_DIR     := src
BUILD_DIR   := build
LINKER_LD   := linker.ld

CYAN        := \033[0;36m
GREEN       := \033[0;32m
RESET       := \033[0m

OBJS        := $(BUILD_DIR)/boot.o $(BUILD_DIR)/interrupts.o $(BUILD_DIR)/kernel.o

.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(OBJS) $(LINKER_LD)
	@mkdir -p $(BUILD_DIR)
	@printf "%b[LD]%b    $@\n" "$(CYAN)" "$(RESET)"
	@$(LD) -m elf_x86_64 -T $(LINKER_LD) -nostdlib $(OBJS) -o $@
	@printf "%b[OK]%b    Kernel built: $@\n" "$(GREEN)" "$(RESET)"

$(BUILD_DIR)/boot.o: $(SRC_DIR)/boot.asm
	@mkdir -p $(BUILD_DIR)
	@printf "%b[NASM]%b  $<\n" "$(GREEN)" "$(RESET)"
	@$(NASM) -f elf64 $< -o $@

$(BUILD_DIR)/interrupts.o: $(SRC_DIR)/interrupts.asm
	@mkdir -p $(BUILD_DIR)
	@printf "%b[NASM]%b  $<\n" "$(GREEN)" "$(RESET)"
	@$(NASM) -f elf64 $< -o $@

$(BUILD_DIR)/kernel.o: $(BUILD_DIR)/kernel.asm
	@printf "%b[NASM]%b  $<\n" "$(GREEN)" "$(RESET)"
	@$(NASM) -f elf64 $< -o $@

$(BUILD_DIR)/kernel.asm: $(SRC_DIR)/kernel.kl $(SRC_DIR)/vga.kl $(SRC_DIR)/multiboot.kl $(SRC_DIR)/gdt.kl $(SRC_DIR)/idt.kl $(SRC_DIR)/isr.kl $(SRC_DIR)/pmm.kl
	@mkdir -p $(BUILD_DIR)
	@printf "%b[KLANG]%b $<\n" "$(GREEN)" "$(RESET)"
	@$(KLANG) $< -o $@

run: all
	@printf "%b[QEMU]%b  Starting emulator...\n" "$(CYAN)" "$(RESET)"
	@$(QEMU) -kernel $(TARGET)

clean:
	@rm -rf $(BUILD_DIR)
	@printf "Cleaned build directory.\n"