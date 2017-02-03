
; Vector table: Initial stack and entry point address. PM0056 p. 36
	AREA    RESET, DATA, READONLY
		
	EXPORT __Vectors
	EXPORT Reset_Handler
		
__Vectors
	DCD 0x20000400         ; Intial stack: 1k into SRAM, datasheet p. 11
	DCD Reset_Handler + 1  ; Entry point (+1 for thumb mode)

	AREA flash, CODE, READONLY
			
  ENTRY		



Reset_Handler
	ldr r0, =0x40021018
	mov r1, #0x14 ; Enable clock A
	str r1, [r0]
	
	ldr r0, =0x40011004 ; Sets mode for port C LEDS
    ldr r1, =0x44444422  
    str r1, [r0]
	
	
	

	ldr r0, =0x40010800 ; GPIOA_CRL
	ldr r1, =0x44444444 ; Low-speed floating inputs
	str r1, [r0]

	mov r2, 0x100 ; activate bits 8 and 9
	mov r4, #0 ; set LED's off value
	mov r3, #0 ; set counter to 0

loop
	ldr r0, =0x40010808 ; GPIOA_IDR
	ldr r0, [r0] ; Load IDR
	and r0, #1 ; Light LEDs if pressed
	orr r0, r0, r0, lsl #1
	lsl r0, #9
	
	ldr r1, =0x4001100c
	str r0, [r1]
	
	cmp r0, #0 ; check to see if button is being pushed.
	addne r3, #1 ; Continue to increase r3 as long as button is held.
	bne loop ; recheck button status.
	
	cmp r3, #0 
	beq loop ; hold in loop if the button has not been pressed
	
	str r2, [r1]
	
delay
	sub r3, #1 ; countdown while blue led is active
	cmp r3, #0
	bne delay
	str r4, [r1] ; set leds to off
	
	b loop ; restart loop
	


  align
  END
