#macro to print text to the console
.macro printtext(%msg)
la $a0, %msg
li $v0, 4
syscall
.end_macro

#macro to print text to the console from the memory loaction specified by the register
.macro printtext2(%msg)
move $a0, %msg
li $v0, 4
syscall
.end_macro

#macro to print an int
.macro printint(%reg)
move $a0, %reg
li $v0, 1
syscall
.end_macro

#macro to read an int into destreg
.macro readint(%destreg)
li $v0, 5
syscall
move %destreg, $v0
.end_macro

#macro to read a string into the memory location specified by destreg
.macro readstring(%destreg)
li $v0, 8
li $a1, 255
move $a0, %destreg
syscall
.end_macro

#macro to open files for reading
#NOTE: opens files read-only
.macro openfile(%filename, %filedescrip)
move $a0, %filename
li $v0, 13
li $a1, 0
li $a2, 0
syscall
move %filedescrip, $v0
.end_macro

#macro to read file into a string
#address of string is stored in $v0 after the syscall 
.macro readfile(%filedescrip, %inputbuf, %numchars)
move $a0, %filedescrip
move $a1, %inputbuf
move $a2, %numchars
li $v0, 14
syscall
.end_macro

#macro to close a file
.macro closefile(%filedescrip)
move $a0, %filedescrip
li $v0, 16
syscall
.end_macro

#allocates memory with a given size, storing the adress in the register ptr
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
    	#		 A5  B5  C5  D5  E5  F5  G5  A4b B4b D5b E5b G5b                                                             A4  B4  C4  D4  E4  F4  G4  A3b B3b D4b E4b G4b A2  C3# D3  E3  F3  C3  G3	 A3  B3
    	pitchlist: .word 81, 83, 72, 74, 76, 77, 79, 68, 70, 73, 75, 78, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 69, 71, 60, 62, 64, 65, 67, 56, 58, 61, 63, 66, 45, 49, 50, 52, 53, 48, 55, 57, 59
    	#		 A   B   C   D   E   F   G   H   I   J   K   L   M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z                    a   b   c   d   e   f   g   h   i   j   k   l   m   n   o   p   q   r   s   t   u
    	
	durationlist: .word 0, 0, 0, 0, 4, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0 ,0, 8, 2, 2, 1, 0, 0, 32, 0, 0, 0
	#		    a  b  c  d  e  f  g  h   i  j  k  l  m  n  o  p  q  r  s  t  u  v  w   x  y  z

    	#TODO: add in a help file or something

    	.text
	#print welcome and ask for a file name
    	printtext(welcomemsg)
	printtext(filemsg)
	#attempt to open file.
	#if error msg, reprompt user, else proceed
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
	# read file and prep for loading note arrays
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

#Macro for storing things into the note representation arrays
#TODO: comment on the convention used here
.macro storenote
    sw $v0, ($t0)
    sw $v1, ($t1)
    sw $t8, ($t2)
    sw $s7, ($t3)
#Increment every one of the array indicators
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, 4
    addi $t3, $t3, 4
.end_macro

.macro nextchar
        #Step the input position forward
        addi $t5, $t5, 1
        lb $t6, ($t5)
.end_macro

parseloop:
	addi $s4,$s4,1

        #Determine if the first character is a '{'. If so, must be a command terminated with '}'.
        #Otherwise, must be dealing with a note
        lb $t6, ($t5)
        li $t7, 173
        beq $t6, $t7, parseCommand
        #Determine if the first character is a '('. If so, must be the start of a chord.
        li $t7, 40
        beq $t6, $t7, parseChord
        j parseNoteDuration


parseChord:
        nextchar #Move past the opening paren

        #Format example: (cw,e,g)
        #Read the first note and a duration
        jal parseNote
        #Take the result from v0 and ensure it's not clobbered
        move $v1, $v0
        jal parseDuration

        #Swap the two
        move $t7, $v0
        move $v0, $v1
        move $v1, $t7

        #Now v0 will have notes, v1 will have the constant duration
        #Store the current channel in $t8 (incremented throughout a chord)
        li $t8, 1
        
chordElement:
        storenote

        #increment the channel counter
        addi $t8, $t8, 1

        #If the current character is not a comma, exit
        li $t7, 44
        bne $t7, $t6, chordElementExit
    
        nextchar

        #Parse a note
        jal parseNote

        j chordElement

chordElementExit:        

        #Store a rest with the corresponding duration of the notes
        #NOTE: rests are taken to be a pitch of -1
        addi $t8, $t8, 1
        li $v0, -1
        storenote

        #Move on to the next character
        addi $t5, $t5, 1
        lb $t6, ($t5)

        #TODO: assert that the current character is an ending paren
        j continueParse



#Parses a note for its pitch based on the array indices as earlier, returns the pitch
#The new position in the input will be after the parsed pitch
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
        j parseOctaveMaybe
        
parseSharp:
        addi $a0, $a0, 1 #Pitch goes up a half step
        
        #Load next character
        addi $t5, $t5, 1
        lb $t6, ($t5)
        j parseOctaveMaybe
parseFlat:
        subi $a0, $a0, 1 #Pitch goes down a half step
        
        #Load next character
        addi $t5, $t5, 1
        lb $t6, ($t5)

parseOctaveMaybe:
        #Determine if the next character could be a digit. If so, assume it's an octave specifier.
        li $t7, 58
        blt $t6, $t7, parseOctave

        #Otherwise, return with the pitch in $v0
        move $v0, $a0
        jr $ra

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

        #Return with the pitch in $v0
        move $v0, $a0
        jr $ra

#Parses a duration from the input, and returns its length in $v0
parseDuration:
        #TODO: support other tempos as well!

    	#Subtract and index into the duration array
    	subi $a0, $t6, 97
    	mul $a0,$a0,4
    	la $a1, durationlist
    	add $a0, $a1, $a0
    	lw $a0, ($a0)
    	div $a0, $a0, 1		#tempo modifiers
    	mul $a0, $a0, 2

        nextchar


        #If the next character is a dot, then multiply the duration by 1.5
        li $s7, 46
        bne $s7, $s6, parseDurationExit 

        sra $s7, $a0, 1
        add $a0, $a0, $s7
        
        nextchar

parseDurationExit:

        move $v0, $a0
        jr $ra

parseNoteDuration:
    jal parseNote
    move $v1, $v0
    jal parseDuration

    #Swap v1 and v2
    move $t7, $v0
    move $v0, $v1
    move $v1, $t7
    
    #Set the channel to 1
    li $t8, 1
    storenote

    #Append a rest with the given duration
    li $v0, -1
    storenote

    j continueParse

parseCommand:
    	addi $t5,$t5,1
	lb $t6,($t5)
	li $t7, 116 # t
	beq $t6, $t7, tempoCommand
	li $t7, 118 # v
	beq $t6, $t7, volumeCommand
	li $t7, 116 # t
	beq $t6, $t7, instrumentCommand
#TODO: error handling

tempoCommand:
	addi $t5,$t5,2
	lb $s5,($t5)
	subi $s5,$s5,48
tempoLoop:
	addi $t5,$t5, 1
	lb $t8,$t5
	subi $t8,$t8,48
	beq $t8,125,continueParse #125=}
	li $t9, 10
	mul $s5, $s5, $t9
	add $s5,$s5,$t8
	j tempoLoop

volumeCommand:

instrumentCommand:
	addi $t5,$t5,2
	lb $s6,($t5)
	subi $s6,$s6,48
instrumentLoop:
	addi $t5,$t5, 1
	lb $t8,$t5
	subi $t8,$t8,48
	beq $t8,125,setInstrument #125=}
	li $t9, 10
	mul $s6, $s6, $t9
	add $s6,$s6,$t8
	j instrumentLoop
setInstrument:
	li $a0, 0
	li $a1,$s6
	li $v0, 38
setInstrumentLoop:
	beq $a0,10,continueParse
	syscall
	addi $a0,$a0,1
	j setInstrumentLoop

continueParse:
    	
        #If the next character is nonzero, keep going
    	li $a1, 0
    	bne $t6, $a1, parseloop

playNotes: 
	ble $s4, 0, end	#$s4 is the number of notes remaining to be played
	lw $a0, ($s0)	# pitch
	lw $a1, ($s1)	# duration (ms)
	li $a2, ($s2)	# channel
	li $a3, ($s3)	# volume
	bltz $a0, playRest
	li $v0, 37
	syscall		#play the note
	j increment
playRest:
	lw $a0, ($s1)
	li $v0, 32
	syscall
increment:
	add $s0, $s0, 4	#increment array indices
	add $s1, $s1, 4
	add $s2, $s2, 4
	add $s3, $s3, 4
	sub $s4, $s4, 1
	j playNotes
end:
	li $v0, 10
	syscall
