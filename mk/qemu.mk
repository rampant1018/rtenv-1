QEMU_STM32 ?= ../qemu_stm32/arm-softmmu/qemu-system-arm

qemu: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 -kernel $(OUTDIR)/$(TARGET).bin

qemudbg: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel $(OUTDIR)/$(TARGET).bin


qemu_remote: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 -kernel $(OUTDIR)/$(TARGET).bin -vnc :1

qemudbg_remote: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel $(OUTDIR)/$(TARGET).bin \
		-vnc :1

qemu_remote_bg: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-kernel $(OUTDIR)/$(TARGET).bin \
		-vnc :1 &

qemudbg_remote_bg: $(OUTDIR)/$(TARGET).bin $(QEMU_STM32)
	$(QEMU_STM32) -M stm32-p103 \
		-gdb tcp::3333 -S \
		-kernel $(OUTDIR)/$(TARGET).bin \
		-vnc :1 &

emu: $(OUTDIR)/$(TARGET).bin
	bash $(TOOLDIR)/emulate.sh $(OUTDIR)/$(TARGET).bin

qemuauto: $(OUTDIR)/$(TARGET).bin $(TOOLDIR)/gdbscript
	bash $(TOOLDIR)/emulate.sh $(OUTDIR)/$(TARGET).bin &
	sleep 1
	$(CROSS_COMPILE)gdb -x $(TOOLDIR)/gdbscript&
	sleep 5

qemuauto_remote: $(OUTDIR)/$(TARGET).bin $(TOOLDIR)/gdbscript
	bash $(TOOLDIR)/emulate_remote.sh $(OUTDIR)/$(TARGET).bin &
	sleep 1
	$(CROSS_COMPILE)gdb -x $(TOOLDIR)/gdbscript&
	sleep 5
