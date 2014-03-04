CROSS_COMPILE ?= arm-none-eabi-
CC := $(CROSS_COMPILE)gcc
QEMU_STM32 ?= ../qemu_stm32/arm-softmmu/qemu-system-arm

ARCH = CM3
VENDOR = ST
PLAT = STM32F10x

TESTDIR = ./test/

LIBDIR = .
CMSIS_LIB=$(LIBDIR)/libraries/CMSIS/$(ARCH)
STM32_LIB=$(LIBDIR)/libraries/STM32F10x_StdPeriph_Driver

CMSIS_PLAT_SRC = $(CMSIS_LIB)/DeviceSupport/$(VENDOR)/$(PLAT)

all: main.bin

main.bin: kernel.c kernel.h context_switch.s syscall.s syscall.h
	$(CROSS_COMPILE)gcc \
		-DUSER_NAME=\"$(USER)\" \
		-Wl,-Tmain.ld -nostartfiles \
		-I . \
		-I$(LIBDIR)/libraries/CMSIS/CM3/CoreSupport \
		-I$(LIBDIR)/libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x \
		-I$(CMSIS_LIB)/CM3/DeviceSupport/ST/STM32F10x \
		-I$(LIBDIR)/libraries/STM32F10x_StdPeriph_Driver/inc \
		-fno-common -ffreestanding -O0 \
		-gdwarf-2 -g3 \
		-mcpu=cortex-m3 -mthumb \
		-o main.elf \
		\
		$(CMSIS_LIB)/CoreSupport/core_cm3.c \
		$(CMSIS_PLAT_SRC)/system_stm32f10x.c \
		$(CMSIS_PLAT_SRC)/startup/gcc_ride7/startup_stm32f10x_md.s \
		$(STM32_LIB)/src/stm32f10x_rcc.c \
		$(STM32_LIB)/src/stm32f10x_gpio.c \
		$(STM32_LIB)/src/stm32f10x_usart.c \
		$(STM32_LIB)/src/stm32f10x_exti.c \
		$(STM32_LIB)/src/misc.c \
		\
		context_switch.s \
		syscall.s \
		stm32_p103.c \
		kernel.c \
		memcpy.s
	$(CROSS_COMPILE)objcopy -Obinary main.elf main.bin
	$(CROSS_COMPILE)objdump -S main.elf > main.list

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
