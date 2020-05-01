TTH_ROOT = ../../../
Q ?= @
GIT_TAG := $(shell git describe --tags)

.PHONY: dist
dist: dist/tinythreads-nios2-$(GIT_TAG).tar.gz

dist/tinythreads-$(GIT_TAG).tar.gz: dist/tinythreads
	@echo "## Making archive ..."
	$(Q)tar -czf $@ -C $(<D) $(<F)

.PHONY: dist/tinythreads
dist/tinythreads:
	@echo "## Packing ..."
	$(Q)mkdir -p $@/TINYTH/
	$(Q)rsync -crlp $(TTH_ROOT)/*.md $@/
	$(Q)rsync -crlp $(TTH_ROOT)/src/ $@/TINYTH/src/
	$(Q)rsync -crlp $(TTH_ROOT)/include/ $@/TINYTH/inc/
	$(Q)rsync -crlp ./*.md ./*.tcl $@/
	$(Q)rsync -crlp ./TINYTH $@/

.PHONY: clean
clean:
	@echo "## Cleaning ..."
	$(Q)rm -rf dist
