MEMORY {
    alias : ORIGIN = 0x00000000, LENGTH = 128k
    flash : ORIGIN = 0x08000000, LENGTH = 1M
    sram  : ORIGIN = 0x20000000, LENGTH = 128k
}

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(reset)

SECTIONS {
    .vectors : {
        KEEP(*(.vectors))
        . = ALIGN(4);
    } > flash AT > alias

    .text : {
        PROVIDE(__text_start = ABSOLUTE(.));
        *(.text .text.*)
        . = ALIGN(4);
        PROVIDE(__text_end = ABSOLUTE(.));
    } > flash

    .rodata : {
        PROVIDE(__rodata_start = ABSOLUTE(.));
        *(.rodata .rodata.*)
        . = ALIGN(4);
        PROVIDE(__rodata_end = ABSOLUTE(.));
    } > flash

    .data : {
        PROVIDE(__data_start = ABSOLUTE(.));
        *(.data .data.*)
        . = ALIGN(4);
        PROVIDE(__data_end = ABSOLUTE(.));
    } > sram

    .bss : {
        PROVIDE(__bss_start = ABSOLUTE(.));
        *(.bss .bss.*)
        . = ALIGN(4);
        PROVIDE(__bss_end = ABSOLUTE(.));
    } > sram
}

PROVIDE(__stack_start = __bss_end);
PROVIDE(__stack_end = ORIGIN(sram) + LENGTH(sram));
