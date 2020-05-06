QEMU_VER = 4.2.0
TARGETS = nios2 arm riscv32
PATCHES = fix-nios2-gettimeofday
EXEC = $(foreach t,$(TARGETS),build/$(t)-softmmu/qemu-system-$(t))
V ?= 0
Q ?= $(V_$(V))
V_0 = @

.PHONY: all
all: $(EXEC)
	
qemu-$(QEMU_VER).tar.xz:
	@echo "#================================================================"
	@echo "# Downloading QEMU source"
	@echo "#"
	$(Q)wget https://download.qemu.org/$@

qemu-$(QEMU_VER)/configure: qemu-$(QEMU_VER).tar.xz
	@echo "#================================================================"
	@echo "# Unpacking files"
	@echo "#"
	$(Q)tar xf $<
	$(Q)touch -c $@

qemu-$(QEMU_VER)/patched-%: %.patch qemu-$(QEMU_VER)/configure
	$(Q)patch -d $(@D) -p1 -s < $<
	$(Q)touch $@

build/Makefile: qemu-$(QEMU_VER)/configure $(MAKEFILE_LIST) \
	$(addprefix qemu-$(QEMU_VER)/patched-,$(PATCHES))
	@echo "#================================================================"
	@echo "# Executing configure"
	@echo "#"
	$(Q)mkdir -p $(@D)
	$(Q)cd $(@D) && ../$< --target-list="$(addsuffix -softmmu,$(TARGETS))"
	$(Q)touch -c $@

$(EXEC): build/Makefile
	@echo "#================================================================"
	@echo "# Building QEMU"
	@echo "#"
	$(Q)$(MAKE) -C $(<D)

