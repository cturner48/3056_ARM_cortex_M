  AREA RESET, DATA, READONLY

  EXPORT __Vectors
  
  EXPORT Reset_Handler

; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
	DCD 0x20000400         ; Intial stack: 1k into SRAM, datasheet p. 11
	DCD Reset_Handler + 1  ; Entry point (+1 for thumb mode)
	SPACE 80
	DCD ext0_handler + 1 ; interrupt handler address
  
  AREA flash, CODE, READONLY
  
  ENTRY
Reset_Handler
	;Reset Handler based on Demo 3 Provided code.	
	ldr r0, =0x40021018
	mov r1, #0x14 ; Enable clock A
	str r1, [r0]
	
	ldr r0, =0x40011004 ; Sets mode for port C LEDS
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
	
	;clear memory
	ldr r0, =0x20000400 ; click counter on stack
	ldr r4, [r0]
	mov r4, #0
	str r4, [r0]
	
	; Register clearing
	mov r0, #0	
	mov r1, #0	;Usable Registers 0->2
	mov r2, #0
	mov r3, #0	; player 1 point value
	mov r4, #0x80000 ; delay counter
	mov r5, #0	; player 2 point value
	mov r6, #1 ; flag bit
	;mov r8, #0x100 ;set delay
	ldr r9, =0x4001100c  ; LED address
	mov r10, #0x300 ; LED Value initially blink both LED's 0x100 blue, 0x200 green.
	mov r11, #10	; Secondary countdown value.
	
	str r10, [r9]


startup_loop	;Begin player acceptance sequence.
	sub r4, #1 ;subtract 1 from timer
	mov r6, #1
	cmp r4, #0
	bne startup_loop
	cmp r10, #0x300 ;check for current color
	ite eq		;Alternate from both lights to no lights, or no lights to both lights.
	moveq r10, #0x000
	movne r10, #0x300
	str r10, [r9]
	sub r11, #1 ;decrement secondary counter.
	cmp r11, #0
	beq game_mode ; If 10 seconds have passed, decide game mode.
	mov r4, #0x80000 ;else reload timer and start loop
	b startup_loop


game_mode
	mov r11, #6 ; store 5 into secondary counter for number of rounds
	ldr r0, =0x20000400 ;loading memory for click counter
	ldr r1, [r0]
	cmp r1, #1 ;compare ext0 counter with 1
	blt no_player ;no entry, branch and exit
	beq one_player ;one entry, branch to one player mode
	mov r11, #10 ; move 5 into secondary counter for player initilization
	cmp r1, #2 ;compare ext0 with 2
	beq two_player ;two players, branch to two player mode
	bne too_many ;too many entries, branch and exit.
	b startup_loop ;error, restart function.


ext0_handler  
	push {r4, lr}
	; Clear pending-bit in EXTI; see RM0041 p. 140
	ldr r0, =0x40010414 ; EXTI->pr, see RM0041 p. 140
	mov r1, #1
	str r1, [r0]
    ; Clear pending-bit in interrupt controller
	ldr r0, =0xe000e280 ; NVIC->icpr0; see PM0051 p. 123
	mov r1, #0x40
	str r1, [r0]
	;check to see if the point has already been assigned for given round
	cmp r6, #1
	bne ext_exit
	cmp r10, #0x200
	beq ext_exit
	ldr r0, =0x20000400 ; load click counter on stack
	ldr r4, [r0]
	add r4, #1
	str r4, [r0]
	mov r6, #0
ext_exit
	pop {r4, pc}
		

no_player
	mov r10, #0x100 ; turn on blue led
	str r10, [r9] ;store LED value
	b dead
	

too_many
	mov r10, #0x200 ; turn on green led
	str r10, [r9]
	b dead
	
	
one_player
	ldr r0, =0x20000400 ; load click counter on stack
	mov r4, #0x0 ; reset counter
	str r4, [r0] 
	cmp r10, #0x000
	str r10, [r9]
	mov r4, #0xF0000 ; set delay timer for one second
	bl delay
	mov r11, #6 ; set counter to 6 rounds
one_flash
	mov r6, #1 ; set flag bit to high for round
	mov r10, #0x200 ; start green
	str r10, [r9] ; activate green
	ldr r0, =0x20000400 ; load point value address into r0
	ldr r3, [r0]
	add r3, r3, #1 ; add one to the point value, dont reload
	mov r4, #0xF0000
	udiv r4, r4, r3 ; load into r4 1 second delay divided by point value +
	bl delay
	mov r10, #0x100 ; blue led active
	str r10, [r9] ; load new led value onto board
	ldr r0, =0x20000400 ; load point value address into r0
	ldr r3, [r0]
	add r3, r3, #1 ; add one to the point value, dont reload
	mov r4, #0xF0000
	udiv r4, r4, r3 ; load into r4 1 second delay divided by point value +1
	bl delay
	sub r11, #1
	cmp r11, #0
	bne one_flash
	ldr r0, =0x20000400 ; load point value address into r0
	ldr r1, [r0]
	mov r10, #0x000 ; turn off lights
	str r10, [r9]
one_score
	mov r4, #0xF0000
	bl delay
	cmp r1, #0
	beq one_over
	mov r10, #0x200
	str r10, [r9]
	mov r4, #0xF0000
	bl delay
	mov r10, #0x000 ; turn off lights
	str r10, [r9]
	sub r1, #1
	b one_score
one_over	
	mov r10, #0x300 ; turn on leds
	str r10, [r9]
	b dead


two_player
	ldr r0, =0x20000400 ; load click counter on stack
	mov r4, #0x0 ; reset counter
	str r4, [r0] 
	cmp r10, #0x200
	ite ne
	movne r10, #0x200 ; start with green led
	moveq r10, #0x000 ; otherwise lights off
	str r10, [r9]
	mov r4, #0xF0000 ; set delay timer for one second
	bl delay
	sub r11, #1
	cmp r11, #0
	bne two_player
	mov r11, #6
two_one_flash
	mov r6, #1 ; set flag bit to high for round
	mov r10, #0x200 ; start green
	str r10, [r9] ; activate green
	ldr r0, =0x20000400 ; load point value address into r0
	ldr r3, [r0]
	add r3, r3, #1 ; add one to the point value, dont reload
	mov r4, #0xF0000
	udiv r4, r4, r3 ; load into r4 1 second delay divided by point value +
	bl delay
	mov r10, #0x100 ; blue led active
	str r10, [r9] ; load new led value onto board
	ldr r0, =0x20000400 ; load point value address into r0
	ldr r3, [r0]
	add r3, r3, #1 ; add one to the point value, dont reload
	mov r4, #0xF0000
	udiv r4, r4, r3 ; load into r4 1 second delay divided by point value +1
	bl delay
	sub r11, #1
	cmp r11, #0
	bne two_one_flash
	ldr r0, =0x20000400 ; load point value address into r0
	ldr r1, [r0] ;load player one point value into r1
	add r0, r0, #0x04 ; increment memory space
	str r1, [r0] ; store player 1 points into second memory on stack
	mov r10, #0x000 ; turn off lights
	str r10, [r9]
	mov r11, #10 ; reset round counter for player two
two_player2
	ldr r0, =0x20000400 ; load click counter on stack
	mov r4, #0x0 ; reset counter
	str r4, [r0] 
	cmp r10, #0x100
	ite ne
	movne r10, #0x100 ; start with green led
	moveq r10, #0x000 ; otherwise lights off
	str r10, [r9]
	mov r4, #0xF0000 ; set delay timer for one second
	bl delay
	sub r11, #1
	cmp r11, #0
	bne two_player2
	mov r11, #6
two_two_flash
	mov r6, #1 ; set flag bit to high for round
	mov r10, #0x200 ; start green
	str r10, [r9] ; activate green
	ldr r0, =0x20000400 ; load point value address into r0
	ldr r3, [r0]
	add r3, r3, #1 ; add one to the point value, dont reload
	mov r4, #0xF0000
	udiv r4, r4, r3 ; load into r4 1 second delay divided by point value +
	bl delay
	mov r10, #0x100 ; blue led active
	str r10, [r9] ; load new led value onto board
	ldr r0, =0x20000400 ; load point value address into r0
	ldr r3, [r0]
	add r3, r3, #1 ; add one to the point value, dont reload
	mov r4, #0xF0000
	udiv r4, r4, r3 ; load into r4 1 second delay divided by point value +1
	bl delay
	sub r11, #1
	cmp r11, #0
	bne two_two_flash
	mov r10, #0x000 ; turn off lights
	str r10, [r9]
	ldr r0, =0x20000404 ; load point value address into r0 for player 1
	ldr r1, [r0]
two_score1
	mov r4, #0xF0000
	bl delay
	cmp r1, #0
	beq two_score1_over
	mov r10, #0x200
	str r10, [r9]
	mov r4, #0xF0000
	bl delay
	mov r10, #0x000 ; turn off lights
	str r10, [r9]
	sub r1, #1
	b two_score1
two_score1_over
	mov r10, #0x000 ; turn off lights
	str r10, [r9]
	ldr r0, =0x20000400 ; load point value address into r0 for player 2
	ldr r1, [r0]
two_score2
	mov r4, #0xF0000
	bl delay
	cmp r1, #0
	beq two_over
	mov r10, #0x100
	str r10, [r9]
	mov r4, #0xF0000
	bl delay
	mov r10, #0x000 ; turn off lights
	str r10, [r9]
	sub r1, #1
	b two_score2
	
two_over	
	mov r10, #0x300 ; turn on leds
	str r10, [r9]
	b dead
	

exitpush	
	pop {pc}


delay
	sub r4, #1 ;subtract 1 from timer
	cmp r4, #0
	bne delay
	bx lr
	
	
dead
	b dead


  align
  
  END
