TTH_ROOT = ../../../
Q ?= @
VERSION := $(shell sed -ne "s/set_sw_property version //p" tinythreads_sw.tcl)
ARCHIVE = dist/tinythreads-nios2-v$(VERSION).tar.gz

.PHONY: dist
dist: $(ARCHIVE)

$(ARCHIVE): dist/tinythreads
	@echo "## Making archive ..."
	$(Q)tar -czf $@ -C $(<D) $(<F)

.PHONY: dist/tinythreads
dist/tinythreads:
	@echo "## Packing ..."
	$(Q)mkdir -p $@/TINYTH/
	$(Q)rsync -crlp $(TTH_ROOT)/*.md $(TTH_ROOT)/LICENSE $@/
	$(Q)rsync -crlp $(TTH_ROOT)/src/ $@/TINYTH/src/
	$(Q)rsync -crlp $(TTH_ROOT)/include/ $@/TINYTH/inc/
	$(Q)rsync -crlp ./*.md ./*.tcl $@/
	$(Q)rsync -crlp ./TINYTH $@/

.PHONY: clean
clean:
	@echo "## Cleaning ..."
	$(Q)rm -rf dist
