QEMU_DIR = ../../../test/qemu
QEMU_BIN = $(QEMU_DIR)/build/arm-softmmu/qemu-system-arm
QEMU_OPT = -nographic -serial null -monitor $(QEMU_MON) -semihosting
QEMU_MON ?= null
CROSS_COMPILE = arm-none-eabi-
TARGETS = arm_v7a_no_vfp arm_v7m_no_vfp
Q ?= @

.PHONY: run
run: $(addsuffix .validate,$(TARGETS))

arm_v7a_%.out: QEMU_OPT += -M xilinx-zynq-a9 -cpu cortex-a9 \
							-device loader,addr=0x100000,cpu-num=0
arm_v7m_%.out: QEMU_OPT += -M netduino2 -cpu cortex-m3

.PHONY: %.out
%.out: %.elf %.lst qemu
	@echo "## Running simulation for $< ..."
	$(Q)$(QEMU_BIN) $(QEMU_OPT) -device loader,file=$< \
		3>&1 1>&2 2>&3 3>&- | tr -d '\0' | tee $@

.PHONY: %.validate
%.validate: %.out
	@echo "=> Validating: initialization sequence"
	$(Q)test "$$(sed -ne "s/^== //p" $< | tr '\n' ' ')" = \
		"start os_init main exit_thread "
	@echo "=> Validating: thread1 count"
	$(Q)test "$$(sed -ne "/^-- thread1/p" $< | wc -l)" -eq 10
	@echo "=> Validating: thread2 count"
	$(Q)test "$$(sed -ne "/^-- thread2/p" $< | wc -l)" -eq 10
	@echo "=> Validating: switch count"
	$(Q)test "$$(sed -ne "/^-- thread/p" $< | uniq | wc -l)" -gt 10

.PHONY: debug
debug: $(firstword $(TARGET) $(TARGETS)).out
debug: QEMU_OPT += -S -s
debug: QEMU_MON = stdio

.PHONY: qemu
qemu:
	@echo "## Building QEMU ..."
	$(Q)$(MAKE) -C $(QEMU_DIR) --no-print-directory

.PHONY: gdb
gdb: $(firstword $(TARGET) $(TARGETS)).elf
	$(Q)$(CROSS_COMPILE)gdb $(GDB_OPT) -iex "target remote :1234" $<

.PRECIOUS: $(addsuffix .elf,$(TARGETS))
.PRECIOUS: $(addsuffix .lst,$(TARGETS))

%.lst: %.elf
	@echo "## Generating list of $< ..."
	$(Q)$(CROSS_COMPILE)objdump -dtr $< > $@ || (rm -f $@; false)

arm_v7a_%.elf: arm_v7a_%.c qemu-arm-v7a.ld
	@echo "## Compiling $< ..."
	$(Q)$(CROSS_COMPILE)gcc -o $@ -Wall -Wl,-T,$(filter %.ld,$^) \
		-mcpu=cortex-a9 \
		-nostartfiles -fno-toplevel-reorder -O1 $<

arm_v7m_%.elf: arm_v7m_%.c qemu-arm-v7m.ld
	@echo "## Compiling $< ..."
	$(Q)$(CROSS_COMPILE)gcc -o $@ -Wall -Wl,-T,$(filter %.ld,$^) \
		-mcpu=cortex-m3 -mthumb \
		-nostartfiles -fno-toplevel-reorder -O1 $<

.PHONY: clean
clean:
	@echo "## Cleaning ..."
	$(Q)rm -f $(foreach t,$(TARGETS),$(t).elf $(t).lst $(t).out)
