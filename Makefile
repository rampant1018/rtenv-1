TARGET = main

CROSS_COMPILE ?= arm-none-eabi-
CC := $(CROSS_COMPILE)gcc
CFLAGS = -DUSER_NAME=\"$(USER)\" \
	 -Wl,-Tmain.ld -nostartfiles \
	 -fno-common -ffreestanding -O0 \
	 -gdwarf-2 -g3 \
	 -mcpu=cortex-m3 -mthumb
QEMU_STM32 ?= ../qemu_stm32/arm-softmmu/qemu-system-arm

ARCH = CM3
VENDOR = ST
PLAT = STM32F10x

LIBDIR = .
CMSIS_LIB=$(LIBDIR)/libraries/CMSIS/$(ARCH)
STM32_LIB=$(LIBDIR)/libraries/STM32F10x_StdPeriph_Driver

CMSIS_PLAT_SRC = $(CMSIS_LIB)/DeviceSupport/$(VENDOR)/$(PLAT)

OUTDIR = build
SRCDIR = src \
	 $(CMSIS_LIB)/CoreSupport \
	 $(STM32_LIB)/src \
	 $(CMSIS_PLAT_SRC)
INCDIR = include \
	 $(CMSIS_LIB)/CoreSupport \
	 $(STM32_LIB)/inc \
	 $(CMSIS_PLAT_SRC)
INCLUDES = $(addprefix -I,$(INCDIR))

TESTDIR = ./test/

SRC = $(wildcard $(addsuffix /*.c,$(SRCDIR))) \
      $(wildcard $(addsuffix /*.s,$(SRCDIR))) \
      $(CMSIS_PLAT_SRC)/startup/gcc_ride7/startup_stm32f10x_md.s
OBJ := $(addprefix $(OUTDIR)/,$(patsubst %.s,%.o,$(SRC:.c=.o)))
DEP = $(OBJ:.o=.o.d)

all: $(OUTDIR)/$(TARGET).bin $(OUTDIR)/$(TARGET).list

$(OUTDIR)/$(TARGET).bin: $(OUTDIR)/$(TARGET).elf
	@echo "    OBJCOPY "$@
	@$(CROSS_COMPILE)objcopy -Obinary $< $@

$(OUTDIR)/$(TARGET).list: $(OUTDIR)/$(TARGET).elf
	@echo "    LIST    "$@
	@$(CROSS_COMPILE)objdump -S $< > $@

$(OUTDIR)/$(TARGET).elf: $(OBJ) $(DAT)
	@echo "    LD      "$@
	@echo "    MAP     "$(OUTDIR)/$(TARGET).map
	@$(CROSS_COMPILE)gcc $(CFLAGS) -Wl,-Map=$(OUTDIR)/$(TARGET).map -o $@ $^

$(OUTDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "    CC      "$@
	@$(CROSS_COMPILE)gcc $(CFLAGS) -MMD -MF $@.d -o $@ -c $(INCLUDES) $<

$(OUTDIR)/%.o: %.s
	@mkdir -p $(dir $@)
	@echo "    CC      "$@
	@$(CROSS_COMPILE)gcc $(CFLAGS) -MMD -MF $@.d -o $@ -c $(INCLUDES) $<

qemu: main.bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 -kernel main.bin

qemudbg: main.bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel main.bin


qemu_remote: main.bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 -kernel main.bin -vnc :1

qemudbg_remote: main.bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel main.bin \
		-vnc :1

qemu_remote_bg: main.bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-kernel main.bin \
		-vnc :1 &

qemudbg_remote_bg: main.bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel main.bin \
		-vnc :1 &

emu: main.bin
	bash emulate.sh main.bin

qemuauto: main.bin gdbscript
	bash emulate.sh main.bin &
	sleep 1
	$(CROSS_COMPILE)gdb -x gdbscript&
	sleep 5

qemuauto_remote: main.bin gdbscript
	bash emulate_remote.sh main.bin &
	sleep 1
	$(CROSS_COMPILE)gdb -x gdbscript&
	sleep 5

check: unit_test.c unit_test.h
	$(MAKE) main.bin DEBUG_FLAGS=-DDEBUG
	$(QEMU_STM32) -nographic -M stm32-p103 \
		-gdb tcp::3333 -S \
		-serial stdio \
		-kernel main.bin -monitor null >/dev/null &
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(TESTDIR)test-strlen.in
	@mv -f gdb.txt $(TESTDIR)test-strlen.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(TESTDIR)test-strcpy.in
	@mv -f gdb.txt $(TESTDIR)test-strcpy.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(TESTDIR)test-strcmp.in
	@mv -f gdb.txt $(TESTDIR)test-strcmp.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(TESTDIR)test-strncmp.in
	@mv -f gdb.txt $(TESTDIR)test-strncmp.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(TESTDIR)test-cmdtok.in
	@mv -f gdb.txt $(TESTDIR)test-cmdtok.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(TESTDIR)test-itoa.in
	@mv -f gdb.txt $(TESTDIR)test-itoa.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(TESTDIR)test-find_events.in
	@mv -f gdb.txt $(TESTDIR)test-find_events.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(TESTDIR)test-find_envvar.in
	@mv -f gdb.txt $(TESTDIR)test-find_envvar.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(TESTDIR)test-fill_arg.in
	@mv -f gdb.txt $(TESTDIR)test-fill_arg.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x $(TESTDIR)test-export_envvar.in
	@mv -f gdb.txt $(TESTDIR)test-export_envvar.txt
	@echo
	@pkill -9 $(notdir $(QEMU_STM32))

clean:
	rm -f *.elf *.bin *.list
