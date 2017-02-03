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
	ldr r0, =0x40021000
	ldr r1, =0x100010 ; RCC->cfgr, PLL mul x6, pll src ext; RM0041 p. 80
	str r1, [r0, #4]
	ldr r1, [r0] ; RCC->cr, turn on PLL, RM0041 p. 78
	orr r1, #0x1000000

	str r1, [r0]
	ldr r1, [r0, #4] ; RCC->cfgr, switch system clock to PLL
	bic r1, #0x3 ; RM0041 p. 81
	orr r1, #2
	str r1, [r0, #4]



	;Reset Handler based on Demo 3 Provided code.

	; Register clearing
	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
	mov r4, #0 ; systick counter
	mov r8, #0x100 ;set delay
	mov r9, #0
	mov r10, #0
	
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
    mov r1, #0x50    
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
    ldr r0, =0x20000400
    mov r1, #0
    str r1, [r0]
	ldr r9, =0x4001100c

    ; Enable interrupts. 
    cpsie i
	
loop	
	b loop
	
ext0_handler  
	push {lr}

    ; Skip the handler if the button is no longer pressed. 
    ldr r0, =0x40010808
    ldr r0, [r0]
    and r0, #1 ; Test bit 0 
    cbz r0, exitpush
        
    ; Load counter value 
    ldr r2, =0x20000400 ;Counter value stored in mem base addr
    ldr r0, [r2]
	add r0, #1
	str r0, [r2]
    bl altblink ; blink every other light
        
exitpush     
	pop {pc} ; Return from interrupt. 	
	
systick_handler
	push {lr}
	
	; Skip the handler if the button is pressed. 
    ldr r0, =0x40010808
    ldr r0, [r0]
    and r0, #1 ; Test bit 0 
    cbz r0, sysblink
	
exittick
	pop {pc}
	
sysblink	;will blink lights based on stored value of counts from ext
	 ; Load counter value 
    ldr r2, =0x20000400 ;Counter value stored in mem
    ldr r0, [r2]
	push {r10}
	
	
doubleblink ;subrouting to blink both lights
	
	cmp r0, #0
	beq exitsys
	sub r0, #1
	str r0, [r2] ;str new counter value back into memory
	mov r10, #0x300
	str r10, [r9]
	bl blinkdelay
	mov r10, #0x0
	str r10, [r9]
	bl blinkdelay
	
	
	;mov r10, #0x0
	;str r10, [r9]	;cler LED's
	
exitsys ;reset values and exit
	pop {r10}
	pop {pc}
	

		
altblink ;blink every other light
	push {r1}
	ldr r1, =0x4001100c
	;Alternate on LED's each interrupt
	cmp r10, #0x100
	ite eq ;if then statement to alternate light value
	moveq r10, #0x200 
	movne r10, #0x100
	str r10, [r9] 
	pop {r1} ;return value
	
	
	
blinkdelay ;half second delay for generic use
	
	mov r4, #0x40000 ;delay timer
	push {r0}
delay	;delay subroutine
	sub r4, #1
	cmp r4, #0
	bne delay
	
	pop {r0}
	bx lr ;return to call function
	
;exit	
	;mov r10, #0x0
	;str r10, [r9]
	
	; Clear pending-bit in EXTI->pr; see RM0041 p. 140 
    ;ldr r0, =0x40010414 ; EXTI->pr, see RM0041 p. 140 
    ;mov r1, #1
    ;str r1, [r0]

    ; Clear pending-bit in interrupt controller 
    ;ldr r0, =0xe000e280 ; NVIC->icpr0; see PM0051 p. 123 
    ;mov r1, #0x40
    ;str r1, [r0]
	
	;b loop
	


  align
  
  END
