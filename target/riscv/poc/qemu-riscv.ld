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

    .rodata : {
        . = ALIGN(4);
        *(.rodata .rodata.*)
    } > ram

    .data : {
        . = ALIGN(4);
        PROVIDE(__data_start = ABSOLUTE(.));
        *(.data .data.*)
        PROVIDE(__data_end = ABSOLUTE(.));
    } > ram

    .bss : {
        . = ALIGN(4);
        PROVIDE(__bss_start = ABSOLUTE(.));
        *(.bss .bss.*)
        PROVIDE(__bss_end = ABSOLUTE(.));
    } > ram
}

PROVIDE(__stack_start = __bss_end);
PROVIDE(__stack_end = ORIGIN(ram) + LENGTH(ram));
