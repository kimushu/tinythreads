MEMORY {
    ram : ORIGIN = 0x80000000, LENGTH = 128M
}

OUTPUT_FORMAT("elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(reset)

SECTIONS {
    .text : {
        KEEP(*(.reset))

        . = ALIGN(4);
        *(.text .text.*)
    } > ram
}
