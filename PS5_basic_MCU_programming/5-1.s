
; Vector table: Initial stack and entry point address. PM0056 p. 36
	AREA    RESET, DATA, READONLY
		
	EXPORT __Vectors
	EXPORT Reset_Handler
		
__Vectors
	DCD 0x20000400         ; Intial stack: 1k into SRAM, datasheet p. 11
	DCD Entry_Handler + 1  ; Entry point (+1 for thumb mode)

	AREA flash, CODE, READONLY
			
  ENTRY		



Entry_Handler
	ldr r0, =0x40021018
	ldr r1, [r0]
	orr r1, #0x10
	str r1, [r0]


	
Reset_Handler
	ldr r0, =0x40011004
	mov r1, #0x22
	str r1, [r0]
	ldr r0, =0x4001100c ; GPIOC_ODR

morsecode
	mov r2, #0x80000 ; Sets on time delay
	bl greenon
	mov r3, #0x80000 ; Off delay time set short.
	bl delay0
	bl blueon
	mov r3, #0xFF000 ; Off delay time set long.
	bl delay0
	bl blueon
	mov r3, #0xFF000 ; Off delay time set long.
	bl delay0
	bl greenon
	mov r3, #0x80000 ; Off delay time set short.
	bl delay0
	bl blueon
	mov r3, #0x80000 ; Off delay time set short.
	bl delay0
	bl greenon
	mov r3, #0x80000 ; Off delay time set short.
	bl delay0
	bl greenon
	mov r3, #0xFF000 ; Off delay time set long.
	bl delay0
	
	b morsecode
	

greenon
	mov r1, #0x200 ; Set bits 8 and 9
	str r1, [r0]
	mov pc, lr
	
blueon
	mov r1, #0x100 ; Set bits 8 and 9
	str r1, [r0]
	mov pc, lr
	
delay0
	sub r2, #1
	cmp r2, #0
	bne delay0
	mov r1, #0 ; Turn the LEDs off
	str r1, [r0]
	mov r2, #0x80000 ; Resets on time delay

delay1
	sub r3, #1
	cmp r3, #0
	bne delay1
	mov pc, lr


  align
  END
