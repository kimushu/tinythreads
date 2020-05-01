QEMU_DIR = ../../../test/qemu
QEMU_BIN = $(QEMU_DIR)/build/nios2-softmmu/qemu-system-nios2
QEMU_OPT = -M 10m50-ghrd -cpu host,mmu_present=off -nographic \
	-serial null -monitor $(QEMU_MON) -semihosting
QEMU_MON ?= null
CROSS_COMPILE = nios2-elf-
TARGETS = nios2_no_shadow
Q ?= @

.PHONY: run
run: $(addsuffix .validate,$(TARGETS))

.PHONY: %.out
%.out: %.elf %.lst qemu
	@echo "## Running simulation for $< ..."
	$(Q)$(QEMU_BIN) $(QEMU_OPT) -device loader,file=$< \
		-device loader,addr=0xc8000000,cpu-num=0 2> $@

.PHONY: %.validate
%.validate: %.out
	@echo "=> Validating: initialization sequence"
	$(Q)test "$$(sed -ne "s/^== //p" $< | tr '\n' ' ')" = \
		"start os_init main exit_thread trap_0 "
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

nios2_%.elf: nios2_%.c qemu-nios2.ld
	@echo "## Compiling $< ..."
	$(Q)$(CROSS_COMPILE)gcc -o $@ -Wall -Wl,-T,$(filter %.ld,$^) \
		-nostartfiles -fno-toplevel-reorder -e reset -O1 $<

.PHONY: clean
clean:
	@echo "## Cleaning ..."
	$(Q)rm -f $(foreach t,$(TARGETS),$(t).elf $(t).lst $(t).out)
