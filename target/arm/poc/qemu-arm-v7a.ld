MEMORY {
    ext_ram : ORIGIN = 0x00000000, LENGTH = 128M
}

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(reset)

SECTIONS {
    .text : {
        . = 0x100000;
        KEEP(*(.vectors))
        . = ALIGN(4);

        PROVIDE(__text_start = ABSOLUTE(.));
        *(.text .text.*)
        . = ALIGN(4);
        PROVIDE(__text_end = ABSOLUTE(.));
    } > ext_ram

    .rodata : {
        PROVIDE(__rodata_start = ABSOLUTE(.));
        *(.rodata .rodata.*)
        . = ALIGN(4);
        PROVIDE(__rodata_end = ABSOLUTE(.));
    } > ext_ram

    .data : {
        PROVIDE(__data_start = ABSOLUTE(.));
        *(.data .data.*)
        . = ALIGN(4);
        PROVIDE(__data_end = ABSOLUTE(.));
    } > ext_ram

    .bss : {
        PROVIDE(__bss_start = ABSOLUTE(.));
        *(.bss .bss.*)
        . = ALIGN(4);
        PROVIDE(__bss_end = ABSOLUTE(.));
    } > ext_ram
}

PROVIDE(__stack_start = __bss_end);
PROVIDE(__stack_und = ORIGIN(ext_ram) + LENGTH(ext_ram));
PROVIDE(__stack_abt = __stack_und - 1024);
PROVIDE(__stack_svc = __stack_abt - 1024);
PROVIDE(__stack_irq = __stack_svc - 1024);
PROVIDE(__stack_fiq = __stack_irq - 1024);
PROVIDE(__stack_sys = __stack_fiq - 1024);

PROVIDE(__heap_start = __stack_start);
PROVIDE(__heap_end = __stack_end);
