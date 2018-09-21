# Architecture dependent part for TinyThreads: NiosII

## Context structure on exceptions/interrupts (SRS=OFF)

If SRS (Shadow register set) is _not_ used, all context data is stored in the stack of each thread.

* Context that saved/restored on entry/exit of exception handler (76 bytes)<sup>*1</sup>

  |Offset|Value|Description|
  |--:|:--:|--|
  | +0|`ra` |Return address|
  | +4|     |A gap for muldiv handler to store zero into|
  | +8|`r1` |Caller-saved register|
  |+12|`r2` |Caller-saved register|
  |+16|`r3` |Caller-saved register|
  |+20|`r4` |Caller-saved register|
  |+24|`r5` |Caller-saved register|
  |+28|`r6` |Caller-saved register|
  |+32|`r7` |Caller-saved register|
  |+36|`r8` |Caller-saved register|
  |+40|`r9` |Caller-saved register|
  |+44|`r10`|Caller-saved register|
  |+48|`r11`|Caller-saved register|
  |+52|`r12`|Caller-saved register|
  |+56|`r13`|Caller-saved register|
  |+60|`r14`|Caller-saved register|
  |+64|`r15`|Caller-saved register|
  |+68|`estatus`|The value of previous status register|
  |+72|`ea-4`<sup>*2</sup>|The address of the instruction to return from exception handler|
  |+76||(Used in the original thread)|

  * (*1) This structure is compatible of Intel's original exception handler.
  * (*2) When the re-issue of the instruction is needed, this value may be `ea` instead of `ea-4`.

* Context that saved/restored on thread switch (36 bytes)

  |Offset|Value|Description|
  |--:|:--:|--|
  |  +0|`r16`|Callee-saved register|
  |  +4|`r17`|Callee-saved register|
  |  +8|`r18`|Callee-saved register|
  | +12|`r19`|Callee-saved register|
  | +16|`r20`|Callee-saved register|
  | +20|`r21`|Callee-saved register|
  | +24|`r22`|Callee-saved register|
  | +28|`r23`|Callee-saved register|
  | +32|`fp` |Frame pointer|
  | +36|     |(Context saved on entry of exception handler stated above)|
  |+112|     |(Used in the original thread)|

## Context structure on exceptions/interrupts (SRS=ON)

If SRS (Shadow register set) is used, all registers are stored in each register set.

* Register set usage
  * For exception/interrupt handler: Normal register set (CRS=0)
  * For each thread: Shadow register set (CRS>0)

* Context that saved/restored on entry/exit of _top-level_ exception handler (only 8 bytes)

  |Offset|Value|Description|
  |--:|:--:|--|
  | +0|`estatus`|The value of previous status register|
  | +4|`ea-4`<sup>*3</sup>|The address of the instruction to return from exception handler|
  | +8||(Used in the original thread)|

  * (*3) When the re-issue of the instruction is needed, this value may be `ea` instead of `ea-4`.

* Context that saved/restored on entry/exit of _nested_ exception handler (72 bytes)

  |Offset|Value|Description|
  |--:|:--:|--|
  | +0|`estatus`|The value of previous status register|
  | +4|`ea-4`<sup>*4</sup>|The address of the instruction to return from exception handler|
  | +8|`ra` |Return address|
  |+12|`r1` |Caller-saved register|
  |+16|`r2` |Caller-saved register|
  |+20|`r3` |Caller-saved register|
  |+24|`r4` |Caller-saved register|
  |+28|`r5` |Caller-saved register|
  |+32|`r6` |Caller-saved register|
  |+36|`r7` |Caller-saved register|
  |+40|`r8` |Caller-saved register|
  |+44|`r9` |Caller-saved register|
  |+48|`r10`|Caller-saved register|
  |+52|`r11`|Caller-saved register|
  |+56|`r12`|Caller-saved register|
  |+60|`r13`|Caller-saved register|
  |+64|`r14`|Caller-saved register|
  |+68|`r15`|Caller-saved register|
  |+72|     |(Context saved in the upper level handler(s))|
  |   |     |(Used in the original thread)|

  * (*4) When the re-issue of the instruction is needed, this value may be `ea` instead of `ea-4`.

* Context that saved/restored on thread switch

  * No data stored in the stack for thread switches
