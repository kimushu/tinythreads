MEMORY {
    tcm : ORIGIN = 0xc0000000, LENGTH = 1024
    ram : ORIGIN = 0xc8000000, LENGTH = 16M
}

OUTPUT_FORMAT("elf32-littlenios2")
OUTPUT_ARCH(nios2)
ENTRY(reset)

SECTIONS {
    .tcm : {
        KEEP(*(.tcm))
    } > tcm

    .text : {
        . = 0x0000;
        KEEP(*(.reset))
        . = 0x0120;
        KEEP(*(.exception))

        PROVIDE(__text_start = ABSOLUTE(.));
        *(.text .text.*)
        . = ALIGN(4);
        PROVIDE(__text_end = ABSOLUTE(.));
    } > ram

    .rodata : {
        PROVIDE(__rodata_start = ABSOLUTE(.));
        *(.rodata .rodata.*)
        . = ALIGN(4);
        PROVIDE(__rodata_end = ABSOLUTE(.));
    } > ram

    .rwdata : {
        PROVIDE(__rwdata_start = ABSOLUTE(.));
        *(.data .data.*)
        _gp = ABSOLUTE(. + 0x8000);
        *(.rwdata .rwdata.*)
        . = ALIGN(4);
        PROVIDE(__rwdata_end = ABSOLUTE(.));
    } > ram

    .bss : {
        PROVIDE(__bss_start = ABSOLUTE(.));
        *(.bss .bss.*)
        . = ALIGN(4);
        PROVIDE(__bss_end = ABSOLUTE(.));
    } > ram
}

PROVIDE(__stack_start = __bss_end);
PROVIDE(__stack_end = ORIGIN(ram) + LENGTH(ram));

PROVIDE(__heap_start = __stack_start);
PROVIDE(__heap_end = __stack_end);
