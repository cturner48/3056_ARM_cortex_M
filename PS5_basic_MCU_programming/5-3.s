
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
	ldr r0, =0x40021018
	mov r1, #0x14 ; Enable clock A
	str r1, [r0]
	
	ldr r0, =0x40011004 ; Sets mode for port C LEDS
    ldr r1, =0x44444422  
    str r1, [r0]
	
	ldr r0, =0x40010800 ; GPIOA_CRL
	ldr r1, =0x44444444 ; Low-speed floating inputs
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

ext0_handler
	push {r4, lr} ; Save r4 and the link register
	ldr r0, =0x20000400 ; The counter is after the stack.
	ldr r4, [r0]
	add r4, #1
	str r4, [r0]
	; Clear pending-bit in EXTI; see RM0041 p. 140
	ldr r0, =0x40010414 ; EXTI->pr, see RM0041 p. 140
	mov r1, #1
	str r1, [r0]
	; Clear pending-bit in interrupt controller
	ldr r0, =0xe000e280 ; NVIC->icpr0; see PM0051 p. 123
	
	mov r1, #0x40
	str r1, [r0]
	pop {r4, pc} ; Restore r4 and return
	
	
	ldr r3, =0x20000400 ; Clear the counter.
	mov r1, #1
	str r1, [r3]
	ldr r0, =0x4001100c ; GPIOC_ODR
loop
	mov r1, #0x300 ; Set bits 8 and 9
	str r1, [r0]
	ldr r2, [r3] ; Loop 64k * counter times.
	lsl r2, #16
delay0
	sub r2, #1
	cmp r2, #0
	bne delay0
	mov r1, #0 ; Turn the LEDs off
	str r1, [r0]
	mov r2, #0x80000 ; Do nothing 1M times again
delay1
	sub r2, #1
	cmp r2, #0
	bne delay1
	b loop




  align
  END
