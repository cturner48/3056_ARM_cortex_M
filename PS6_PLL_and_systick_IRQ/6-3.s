  AREA RESET, DATA, READONLY

  
  EXPORT __Vectors
  
  EXPORT Reset_Handler

; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400          ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1   ; Entry point (+1 for thumb mode)
  DCD 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  DCD systick_handler + 1 ; 
  DCD 0, 0, 0, 0, 0, 0 
  DCD ext0_handler + 1    ; IRQ6 : external interrupt from exti controller
  
  AREA flash, CODE, READONLY
  
  ENTRY
Reset_Handler
	;ldr r0, =0x40021000
	;ldr r1, =0x100010 ; RCC->cfgr, PLL mul x6, pll src ext; RM0041 p. 80
	;str r1, [r0, #4]
	;ldr r1, [r0] ; RCC->cr, turn on PLL, RM0041 p. 78
	;orr r1, #0x1000000

	;str r1, [r0]
	;ldr r1, [r0, #4] ; RCC->cfgr, switch system clock to PLL
	;bic r1, #0x3 ; RM0041 p. 81
	;orr r1, #2
	;str r1, [r0, #4]

	;Reset Handler based on Demo 3 Provided code.
	; Register clearing
	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0	; point value
	mov r4, #0x10000 ; delay counter
	mov r8, #0x100 ;set delay
	ldr r9, =0x4001100c  ; LED address
	mov r10, #0x100 ; LED Value initially blue
	
	
	
	;  Enable I/O port clocks 
    ldr r0, =0x40021018  
    mov r1, #0x15      
    str r1, [r0]        

    ;  GPIO Port C bits 8,9: push-pull low speed (2MHz) outputs 
    ldr r0, =0x40011004  
    ldr r1, =0x44444422  
    str r1, [r0]

    ; GPIO Port A: all bits: inputs with no pull-up/pull down 
    ldr r0, =0x40010800  
    ldr r1, =0x44444444  
    str r1, [r0]

    ; Set EXTI0 source to Port A 
    ldr r0, =0x40010008  
    ldr r1, [r0]
    bic r1, #0xf         
    str r1, [r0]

    ; Initialize the systick timer. 
    ldr r0, =0xe000e010  
    mov r1, #0x10
    str r1, [r0, #4]   
    ldr r1, [r0, #0]   
    orr r1, #3         
    str r1, [r0, #0]
        
    ; Set up interrupt on rising edge of port A bit 0 on the EXTI (external
    ; interrupt controller); see RM0041 p. 134
    ldr r0, =0x40010400 ; EXTI base address 
    mov r1, #1
    str r1, [r0, #8]    
    str r1, [r0, #0]    

    ; Set up the IRQ in the NVIC. See PM0056 p. 118
    ldr r0, =0xe000e404  
    ldr r1, [r0]         
    bic r1, #0xff0000    
    str r1, [r0]         
        
    ldr r0, =0xe000e100 
    mov r2, #0x40        
    str r2, [r0]         
        
    ; Clear our counter.
    ldr r3, =0x20000400
    mov r1, #0
    str r1, [r3]
	

    ; Enable interrupts. 
    cpsie i
	str r10, [r9]
	
loop
	b loop
	

ext0_handler  
	push {lr}

    ;Skip the handler if the button is no longer pressed. 
    ldr r0, =0x40010808
    ldr r0, [r0]
    and r0, #1 ; Test bit 0 
    cbz r0, exitpush
        
    cmp r10, #0x100 ;check if led is blue
	beq over
	bne point	
	pop {pc}
	
	
over
	mov r10, #0x00  ;deactivate lights
	str r10, [r9]
	
	b over
	
	
point
	push {r0}
	ldr r0, [r3]
	add r0, r0, #1 ;increase point value by 1
	str r0, [r3]
	
	;mov r10, #0x300

blink
	;push {r2}
	add r2, r0, #0
	pop {r0}

bloop
	cmp r2, #0
	beq exitbloop
	sub r2, #1
	mov r10, #0x300 
	str r10, [r9] ;turn on both lights
	mov r4, #0x80000
delay1
	sub r4, #1
	cmp r4, #0
	bne delay1
	
	mov r10, #0x000
	str r10, [r9]
	mov r4, #0x80000
delay2
	sub r4, #1
	cmp r4, #0
	bne delay2
	beq bloop
	
	



exitbloop
	mov r10, #0x00
	str r10, [r9] ; deavtivate lights
	;pop {r2}
exitpush	
	pop {pc}

systick_handler
	push {lr}
	cmp r4, #0
	bne countdown
	cmp r10, #0x100 ;check for current color
	bne changeblue
	beq changegreen
	pop {pc}
	

countdown
	sub r4, #1 ;Subtract 1 from delay counter
	pop {pc} ;return
	

changeblue
	mov r4, #0x10000
	mov r10, #0x100
	str r10, [r9]
	pop {pc}


changegreen
	push {r2}
	push {r0}
	ldr r0, [r3]
	mov r4, #0x10000
	cmp r0, #0
	ite eq
	moveq r2, #1
	movne r2, r0
	udiv r4, r4, r2
	pop {r0}
	pop {r2}
	mov r10, #0x200
	str r10, [r9]
	pop {pc}
	

  align
  
  END
