
ifeq ($(QUARTUS_ROOTDIR),)
$(error You need to set QUARTUS_ROOTDIR)
endif
SOPC_KIT_NIOS2 ?= $(QUARTUS_ROOTDIR)/../nios2eds

QSYS_GEN = $(QUARTUS_ROOTDIR)/sopc_builder/bin/qsys-generate
BSP_GEN = $(SOPC_KIT_NIOS2)/sdk2/bin/nios2-bsp
APP_GEN = $(SOPC_KIT_NIOS2)/sdk2/bin/nios2-app-generate-makefile
TEST_ROOT = ../../../../test

QEMU_BIN = $(TEST_ROOT)/qemu/build/nios2-softmmu/qemu-system-nios2
QEMU_OPT = -M 10m50-ghrd -nographic -serial null \
	-monitor $(QEMU_MON) \
	-semihosting -device loader,addr=0xc8000000,cpu-num=0
QEMU_MON ?= null

TEST_SOURCES := \
	$(foreach d,$(TEST_ROOT) $(TEST_ROOT)/Unity/src,\
		$(wildcard $(d)/*.c $(d)/*.h)) \
	qemu_semi.c

TARGETS = qemu_10m50_ghrd
TARGET ?= $(firstword $(TARGETS))
DIST_TCL = ../dist/tinythreads/tinythreads_sw.tcl
Q ?= @

MAKEFLAGS += --no-builtin-rules

all: $(addsuffix .out,$(TARGETS))

.PRECIOUS: %.sopcinfo
%.sopcinfo: %.qsys
	@echo "## Generating sopcinfo ..."
	$(Q)$(QSYS_GEN) $< -tb > $*.log 2>&1

%.out: software/app_%/test.elf
	@echo "## Running simulator ..."
	$(Q)$(QEMU_BIN) $(QEMU_OPT) -device loader,file=$<

debug: QEMU_MON = stdio
debug: $(TARGET).debug
%.debug: software/app_%/test.elf
	@echo "## Running simulator with debug mode ..."
	$(Q)$(QEMU_BIN) $(QEMU_OPT) -device loader,file=$< -S -s

gdb: $(TARGET).gdb
%.gdb: software/app_%/test.elf
	@echo "## Starting GDB ..."
	$(Q)nios2-elf-gdb --nx -iex "target remote :1234" $<

.PRECIOUS: software/app_%/test.elf
software/app_%/test.elf: software/app_%/Makefile
	@echo "## Building test application ..."
	$(Q)$(MAKE) -C $(<D) > $(@D)/build.log

.PRECIOUS: software/app_%/Makefile
software/app_%/Makefile: software/bsp_%/Makefile $(TEST_SOURCES)
	@echo "## Generating test application ..."
	$(Q)mkdir -p $(@D)
	$(Q)cp $(filter-out %/Makefile,$^) $(@D)/
	$(Q)$(APP_GEN) --bsp-dir $(<D) --app-dir $(@D) --src-dir $(@D) \
		--elf-name test.elf > $(@D)/generate.log

.PRECIOUS: software/bsp_%/Makefile
software/bsp_%/Makefile: %.sopcinfo $(DIST_TCL)
	@echo "## Generating BSP ..."
	$(Q)mkdir -p $(@D)
	$(Q)$(BSP_GEN) tinyth $(@D) $< \
		--librarian-path "$(dir $(shell realpath $(filter %.tcl,$^))),$$" \
		--set hal.enable_reduced_device_drivers true \
		> $(@D)/generate.log

$(DIST_TCL):
	$(Q)$(MAKE) -C .. --no-print-directory dist

.PHONY: update
update:
	@echo "## Updating distribution package ..."
	@rm -f $(DIST_TCL)
	@$(MAKE) --no-print-directory \
		$(foreach t,$(TARGETS),software/app_$(t)/test.elf)

.PHONY: clean
clean:
	@echo "## Cleaning ..."
	$(Q)rm -f $(foreach t,$(TARGETS),$(t).sopcinfo $(t).log)
	$(Q)rm -rf $(foreach t,$(TARGETS),$(t)/ software/app_$(t)/ software/bsp_$(t)/)
