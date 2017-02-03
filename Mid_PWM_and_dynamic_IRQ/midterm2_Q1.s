
; Vector table: Initial stack and entry point address. PM0056 p. 36
	AREA    RESET, DATA, READONLY
		
	EXPORT __Vectors
	EXPORT Reset_Handler
		
__Vectors
	DCD 0x20000400         ; Intial stack: 1k into SRAM, datasheet p. 11
	DCD Reset_Handler + 1  ; Entry point (+1 for thumb mode)
	SPACE 80
	DCD ext0_handler + 1 ; interrupt handler address

	AREA flash, CODE, READONLY
			
  ENTRY		



Reset_Handler
	;Reset Handler based on Demo 3 Provided code.	
	;Skeleton code from Mandisetti ECE 3056
	ldr r0, =0x40021018
	mov r1, #0x14 ; Enable clock A
	str r1, [r0]
	
	ldr r0, =0x40011004 ; Sets mode for port C LEDS
    ldr r1, =0x44444422  
    str r1, [r0]
	
	ldr r0, =0x40010800 ; GPIOA_CRL
	ldr r1, =0x44444144  ;Set bit 3 to 1 -> 00 01 MODE output 10MHz Max, CNF general purpose output.
	str r1, [r0]	
	
	ldr r0, =0x40010008 ; AFIO->exticr1, see RM0041 p. 124
	ldr r1, [r0]
	bic r1, #0xf ; Set LSBs to 0, Port A
	str r1, [r0]
	ldr r0, =0x40010400 ; EXTI base address
	mov r1, #1
	str r1, [r0, #8] ; EXTI->rtsr; event 0 rising
	str r1, [r0, #0] ; EXTI->imr; unmask line 0
	
	ldr r0, =0xe000e404 ; Address of NVIC->ipr1; PM0056 p. 128
	ldr r1, [r0] ; NVIC->ipr1; PM0056 p. 125
	bic r1, #0xff0000 ; Clear bits for IRQ6
	str r1, [r0] ; Set IRQ6 priority to 0
	ldr r0, =0xe000e100 ; NVIC->iser0; PM0056 p. 120
	mov r2, #0x40 ; Bit corresponding to IRQ6
	str r2, [r0] ; NVC->iser0; set enabled
	
	ldr r9, =0x4001100c  ; LED address

loop
	b loop

ext0_handler
	push {lr} ; Save the link register
	; Clear pending-bit in EXTI; see RM0041 p. 140
	ldr r0, =0x40010414 ; EXTI->pr, see RM0041 p. 140
	mov r1, #1
	str r1, [r0]
	; Clear pending-bit in interrupt controller
	ldr r0, =0xe000e280 ; NVIC->icpr0; see PM0051 p. 123
	mov r1, #0x40
	str r1, [r0]
	
	mov r10, #0x300 ;Activate both LED light bits.
	str r10, [r9] ;Activate both lights
	
	mov r8, #0xF0000 ;1 second timer
	mov r11, #0x1b8
	mov r12, #0x4
	udiv r8, r8, r11 ; divide the 1 second total by 440. This gives the total signal period.
	udiv r7, r8, r12 ; Divide by 4 to get the 25% duty cycle.
	sub r6, r8, r7 ; Sub up cycle from total period to calculate the down cycle.
	
	mov r2, #0x1b8
	ldr r0, =0x4001080c ; GPIOA_ODR
signal
	cmp r2, #0
	beq ext_exit
	sub r2, #1
	mov r1, r7 ; up timer in r1
	mov r4, r6 ; down timer in r4
	mov r3, #0x4 ;activate bit 3
	str r3, [r0] ; activate PA3
up
	sub r1, #1
	cmp r1, #0
	bne up
	mov r3, #0x0 ;deacitavte bit 3
	str r3, [r0]
down
	sub r4, #1
	cmp r4, #0
	bne down
	b signal
	
ext_exit
	mov r10, #0x0
	str r10, [r9] ;deactivate leds
	pop {pc} ; Restore r4 and return
	
	
	







  align
  END
