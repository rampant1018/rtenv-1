QEMU_STM32 ?= ../qemu_stm32/arm-softmmu/qemu-system-arm
BUILD_TARGET = $(OUTDIR)/$(TARGET)

qemu: $(BUILD_TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 -kernel $(BUILD_TARGET).bin

qemudbg: $(BUILD_TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel $(BUILD_TARGET).bin


qemu_remote: $(BUILD_TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 -kernel $(BUILD_TARGET).bin -vnc :1

qemudbg_remote: $(BUILD_TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel $(BUILD_TARGET).bin \
		-vnc :1

qemu_remote_bg: $(BUILD_TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-kernel $(BUILD_TARGET).bin \
		-vnc :1 &

qemudbg_remote_bg: $(BUILD_TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel $(BUILD_TARGET).bin \
		-vnc :1 &

emu: $(BUILD_TARGET).bin
	bash $(TOOLDIR)/emulate.sh $(BUILD_TARGET).bin

qemuauto: $(BUILD_TARGET).bin $(TOOLDIR)/gdbscript
	bash $(TOOLDIR)/emulate.sh $(BUILD_TARGET).bin &
	sleep 1
	$(CROSS_COMPILE)gdb -x $(TOOLDIR)/gdbscript&
	sleep 5

qemuauto_remote: $(BUILD_TARGET).bin $(TOOLDIR)/gdbscript
	bash $(TOOLDIR)/emulate_remote.sh $(BUILD_TARGET).bin &
	sleep 1
	$(CROSS_COMPILE)gdb -x $(TOOLDIR)/gdbscript&
	sleep 5
