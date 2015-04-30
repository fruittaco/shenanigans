.macro printtext(%msg)
la $a0, %msg
li $v0, 4
syscall
.end_macro

.macro printtext2(%msg)
move $a0, %msg
li $v0, 4
syscall
.end_macro

.macro printint(%reg)
move $a0, %reg
li $v0, 1
syscall
.end_macro

.macro readint(%destreg)
li $v0, 5
syscall
move %destreg, $v0
.end_macro

.macro readstring(%destreg)
li $v0, 8
li $a1, 255
move $a0, %destreg
syscall
.end_macro

#NOTE: opens files read-only
.macro openfile(%filename, %filedescrip)
move $a0, %filename
li $v0, 13
li $a1, 0
li $a2, 0
syscall
move %filedescrip, $v0
.end_macro

.macro readfile(%filedescrip, %inputbuf, %numchars)
move $a0, %filedescrip
move $a1, %inputbuf
move $a2, %numchars
li $v0, 14
syscall
.end_macro

.macro closefile(%filedescrip)
move $a0, %filedescrip
li $v0, 16
syscall
.end_macro

.macro malloc(%size, %ptr)
move $a0, %size
li $v0, 9
syscall
move %ptr, $v0
.end_macro

#Assumptions: s0 - pitch, s1 - duration, s2 - instruments, s3 - volumes
#s4 - number of notes. Assumes string to read is in $s5
#and number of characters in the string is in $s6
#t0-3 are the locations into it
#Reads in a list of pitch, duration pairs
#Has

.globl main

main:
    	addu $s7, $0, $ra

    	.data
    	nl: .asciiz "\n"
    	welcomemsg: .asciiz "Welcome to Shenanigans Music Interpreter\n"
    	filemsg: .asciiz "Choose a music file to load\n"
    	invalidfilemsg: .asciiz "Invalid file name, please try again\n"

    	#Provides a list of pitches [indexed from a]
        #TODO: MAKE a be A4. Otherwise, inconsistent results will be obtained
    	#		 A4  B4  C5  D5  E5  F5  G5  A4b B4b D5b E5b G5b                                                             A3  B3  C4  D4  E4  F4  G4  A3b B3b D4b E4b G4b A2  C3# D3  E3  F3  C3  G3
    	pitchlist: .word 69, 71, 72, 74, 76, 77, 79, 68, 70, 73, 75, 78, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 57, 59, 60, 62, 64, 65, 67, 56, 58, 61, 63, 66, 45, 49, 50, 52, 53, 48, 55
    	#		 A   B   C   D   E   F   G   H   I   J   K   L   M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z                    a   b   c   d   e   f   g   h   i   j   k   l   m   n   o   p   q   r   s
    	durationlist: .word 0, 0, 0, 0, 125, 0, 0, 500, 0, 0, 0, 0, 0, 0, 0 ,0, 250, 60, 60, 30, 0, 0, 1000, 0, 0, 0
    	#TODO: add in a help file or something

    	.text
    	printtext(welcomemsg)
	printtext(filemsg)
tryAgain:
	li $a0, 255
	malloc($a0, $s5)
    	readstring($s5)
removeNewline:
	#$s5-string address
	#$s6-character count
	move $t1,$s5
loop:
	lb $t2,($t1)
	addi $t1,$t1,1
	bnez $t2, loop
	subi $t1,$t1,2
	sb $0,($t1)
	openfile($s5, $s5)
    	bge $v0, $0,goodFile
    	printtext(invalidfilemsg)
	j tryAgain
goodFile:
	li $t0,1000 # max number of notes
	div $a0,$t0,2
	mul $t1,$t0,2
    	malloc($a0,$s6)
    	readfile($s5,$s6,$t1)
    	closefile($s5)
	move $a0,$t0
    	malloc($a0,$s0)
    	move $a0,$t0
    	malloc($a0,$s1)
    	move $a0,$t0
    	malloc($a0,$s2)
    	move $a0,$t0
    	malloc($a0,$s3)
    	move $s4,$0
parsefile:
	move $t0, $s0
	move $t1, $s1
	move $t2, $s2
	move $t3, $s3
	move $t5, $s6

parseloop:
	addi $s4,$s4,1

        #Determine if the first character is a '{'. If so, must be a command terminated with '}'.
        #Otherwise, must be dealing with a note
        lb $t6, ($t5)
        li $t7, 173
        beq $t6, $t7, parseCommand
parseNote:
        #Use the first character [the note] to set the initial pitch (stored in a0)
    	#Subtract and index into the pitch array

    	subi $a0, $t6, 65
    	mul $a0,$a0,4
    	la $a1, pitchlist
    	add $a0, $a1, $a0
    	lw $a0, ($a0)

        #Move on to the next character
        addi $t5, $t5, 1
        lb $t6, ($t5)

        #Determine if a sharp or flat character exists at the next position
        li $t7, 98
        beq $t6, $t7, parseFlat
        li $t7, 35
        beq $t6, $t7, parseSharp
        j parseOctaveDuration
        
parseSharp:
        addi $a0, $a0, 1 #Pitch goes up a half step
        
        #Load next character
        addi $t5, $t5, 1
        lb $t6, ($t5)
        j parseOctaveDuration
parseFlat:
        subi $a0, $a0, 1 #Pitch goes down a half step
        
        #Load next character
        addi $t5, $t5, 1
        lb $t6, ($t5)

parseOctaveDuration:
        #Determine if the next character could be a digit. If so, assume it's an octave specifier.
        li $t7, 58
        blt $t6, $t7, parseOctave
        j parseDuration
parseOctave:
        #Load the numerical value of the octave into t7
        subi $t7, $t6, 48
        #Calculate the octave's offset relative to the default octave (centered on c4)
        subi $t7, $t7, 4
        #Multiply to obtain an offset in half-steps
        li $t6, 12
        mul $t7, $t7, $t6
        #add the result to the pitch
        add $a0, $t7, $a0

        #Move on to the next character
        addi $t5, $t5, 1
        lb $t6, ($t5)

parseDuration:
        #First, store back all of the pitch information
    	sw $a0, ($t0)

    	#Subtract and index into the duration array
    	subi $a0, $t6, 97
    	mul $a0,$a0,4
    	la $a1, durationlist
    	add $a0, $a1, $a0
    	lw $a0, ($a0)
    	div $a0, $a0, 1		#tempo modifiers
    	mul $a0, $a0, 2
    	sw $a0, ($t1)
#TODO: Add error detection

        j continueParse

parseCommand:
    #TODO: Expand!


continueParse:
    	#increment output array addresses
    	addi $t0, $t0, 4
    	addi $t1, $t1, 4

        #Move on to the next character
        addi $t5, $t5, 1
        lb $t6, ($t5)

        #If the next character is nonzero, keep going
    	li $a1, 0
    	bne $t6, $a1, parseloop

playNotes: 
	ble $s4, 0, end	#$s4 is the number of notes remaining to be played
	lw $a0, ($s0)	#pitch
	lw $a1, ($s1)	#duration (ms)
	li $a2, 0	#instrument (currently hard-coded to grand piano, final version may implement multiple insturments, stored in $s2)
	li $a3, 100	#volume (will be adjustable in final version, stored in $s3)
	li $v0, 31
	syscall		#play the note
	lw $a0, ($s1)
	li $v0, 32
	syscall
	add $s0, $s0, 4	#increment array indices
	add $s1, $s1, 4
	add $s2, $s2, 4
	add $s3, $s3, 4
	sub $s4, $s4, 1
	j playNotes
end:
	li $v0, 10
	syscall
