j main

#function to print text to the console (address of text in a0)
printtext:
li $v0, 4
syscall
jr $ra

#function to read a string into the memory location specified by argument register
readstring:
li $v0, 8
li $a1, 255
syscall
jr $ra

#allocates memory with a given size, storing the adress in the register ptr
#assumes the size is in a0, returns the pointer
malloc:
li $v0, 9
syscall
jr $ra

#Assumptions: s0 - pitch, s1 - duration, s2 - instruments, s3 - volumes
#s4 - number of notes. Assumes string to read is in $s5
#and number of characters in the string is in $s6
#t0-3 are the locations into it
#Reads in a list of pitch, duration pairs

.globl main

main:
    	addu $s7, $0, $ra

    	.data
    	
    	nl: .asciiz "\n"
    	welcomemsg: .asciiz "Welcome to the Shenanigans Music Interpreter.\nEnter \"1\" to play music from a file, \"2\" to play directly from this window, or \"3\" to quit.\n"
    	filemsg: .asciiz "Enter a music file to load, or \"0\" to exit to the main menu.\n"
    	consolemsg: .asciiz "Enter the line of music you would like to play, or \"0\" to exit to the main menu.\n"
    	invalidfilemsg: .asciiz "Invalid file name, please try again.\n"
    	invalidmenuchoice: .asciiz "Invalid input, please try again.\n"
    	exitstring: .byte '0'

    	#Provides a list of pitches [indexed from a]
    	#		 A5  B5  C5  D5  E5  F5  G5  A4b B4b D5b E5b G5b                                                             A4  B4  C4  D4  E4  F4  G4  A3b B3b D4b E4b G4b A2  C3# D3  E3  F3  C3  G3	 A3  B3
    	pitchlist: .word 81, 83, 72, 74, 76, 77, 79, 68, 70, 73, 75, 78, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 69, 71, 60, 62, 64, 65, 67, 56, 58, 61, 63, 66, 45, 49, 50, 52, 53, 48, 55, 57, 59
    	#		 A   B   C   D   E   F   G   H   I   J   K   L   M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z                    a   b   c   d   e   f   g   h   i   j   k   l   m   n   o   p   q   r   s   t   u
    	
	durationlist: .word 0, 0, 0, 0, 4, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0 ,0, 8, 2, 2, 1, 0, 0, 32, 0, 0, 0
	#		    a  b  c  d  e  f  g  h   i  j  k  l  m  n  o  p  q  r  s  t  u  v  w   x  y  z

    	.text
	#print welcome and ask for a playback type
startScreen: 
        la $a0, welcomemsg
        jal printtext
menuInput:
	#Read menu input from a string (allocate 256 bytes)
	li $a0, 256
	jal malloc
	
	move $t0, $v0
	move $a0, $t0
	jal readstring
	#Compute the numerical value of the first character and store in t0
	lb $a0, ($a0)
	subi $t0, $a0, 48

   	beq $t0, 1, playFile
   	beq $t0, 2, playConsole
	beq $t0, 3, end
        la $a0, invalidmenuchoice
        jal printtext
   	j menuInput
	#play music line entered into the console window
playConsole:
	li $t4, 2 #marks playing from console
        la $a0, consolemsg
        jal printtext
	li $a0, 255

        jal malloc
        move $t0, $v0

        move $a0, $t0
        jal readstring

	lb $t1, ($t0)
	lb $t2, exitstring
	beq $t2, $t1, startScreen
	move $s6, $t0
	li $t0, 10000
	j allocateMemory
	#play music from a loaded file
playFile:
	li $t4, 1 #marks playing from file
        la $a0, filemsg
        jal printtext
	#attempt to open file.
	#if error msg, reprompt user, else proceed
tryAgain:
	li $a0, 255

        jal malloc
        move $s5, $v0

        move $a0, $s5
        jal readstring

	lb $t1, ($s5)
	lb $t2, exitstring
	beq $t2, $t1, startScreen

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
	
        #Open the file
        move $a0, $s5
        li $v0, 13
        li $a1, 0
        li $a2, 0
        syscall
        move $s5, $v0

        bge $v0, $0,goodFile
        la $a0, invalidfilemsg
        jal printtext
	j tryAgain
goodFile:
	# read file and prep for loading note arrays
	li $t0,10000 # max number of notes
	li $t7,2
	div $a0,$t0,$t7
	mul $t1,$t0,$t7

        jal malloc
        move $s6, $v0


        #Read the file
        move $a0, $s5 #File descriptor
        move $a1, $s6 #buffer
        move $a2, $t1 #numchars
        li $v0, 14
        syscall

        #Close the file
        move $a0, $s5
        li $v0, 16
        syscall

allocateMemory:    	
	move $a0,$t0
        jal malloc
        move $s0, $v0

        jal malloc
        move $s1, $v0

        jal malloc
        move $s2, $v0

        jal malloc
        move $s3, $v0

        #Initialize counter for number of characters
    	move $s4,$0
	li $s5, 83
	li $s7, 80
parsefile:
	move $t0, $s0
	move $t1, $s1
	move $t2, $s2
	move $t3, $s3
	move $t5, $s6
        j parseloop

#Function for storing things into the note representation arrays
storenote:
    sw $v0, ($t0)
    sw $v1, ($t1)
    sw $t8, ($t2)
    sw $s7, ($t3)
#Increment every one of the array indicators
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, 4
    addi $t3, $t3, 4
    jr $ra

nextchar:
    #Step the input position forward
    addi $t5, $t5, 1
    lb $t6, ($t5)
    jr $ra

parseloop:
	addi $s4,$s4,1
        lb $t6, ($t5)

whitespacehandler:
        #Skip any number of newlines and spaces
        li $t7, 32 #Skip spaces
        beq $t7, $t6, skipwhitespace
        li $t7, 10 #Skip newlines
        beq $t7, $t6, skipwhitespace
        li $t7, 13 #Skip carriage returns
        beq $t7, $t6, skipwhitespace
        j parsecontinue

skipwhitespace:
        jal nextchar
        j whitespacehandler

parsecontinue:

        #Determine if the first character is a '{'. If so, must be a command terminated with '}'.
        #Otherwise, must be dealing with a note
        li $t7, 123
        beq $t6, $t7, parseCommand
        #Determine if the first character is a '('. If so, must be the start of a chord.
        li $t7, 40
        beq $t6, $t7, parseChord
        j parseNoteDuration


parseChord:
        jal nextchar #Move past the opening paren

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
        jal storenote

        #increment the channel counter
        addi $t8, $t8, 1

        #If the current character is not a comma, exit
        li $t7, 44
        bne $t7, $t6, chordElementExit
    
        jal nextchar

        #Parse a note
	jal parseNote

        j chordElement

chordElementExit:        

        #Store a rest with the corresponding duration of the notes
        #NOTE: rests are taken to be a pitch of -1
        addi $t8, $t8, 1
        li $v0, -1
        jal storenote

        #Move on to the next character
        addi $t5, $t5, 1
        lb $t6, ($t5)

        j continueParse



#Parses a note for its pitch based on the array indices as earlier, returns the pitch
#The new position in the input will be after the parsed pitch
parseNote:
        #Use the first character [the note] to set the initial pitch (stored in a0)
    	#Subtract and index into the pitch array

    	subi $a0, $t6, 65
	li $t7,4
    	mul $a0,$a0,$t7
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
        blt $t6, $t7, parseOctaveMaybeTwo
	j noOctave
parseOctaveMaybeTwo:
	li $t7, 47
	bgt $t6, $t7, parseOctave
	j noOctave
noOctave:

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

    	#Subtract and index into the duration array
    	subi $a0, $t6, 97
	li $t7,4
    	mul $a0,$a0,$t7
    	la $a1, durationlist
    	add $a0, $a1, $a0
    	lw $a0, ($a0)
    	mul $a0, $a0, $s5 # $s5 is duration in ms of a 1/32nd note

        #Load next character
        addi $t5, $t5, 1
        lb $t6, ($t5)


        #If the next character is a dot, then multiply the duration by 1.5
        bne $s6,46,parseDurationExit 

        sra $t7, $a0, 1
        add $a0, $a0, $t7
        
        #Load next character
        addi $t5, $t5, 1
        lb $t6, ($t5)

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
    jal storenote

    #Append a rest with the given duration
    li $v0, -1
    jal storenote

    j continueParse

parseCommand:
    	addi $t5,$t5,1
	lb $t6,($t5)
	li $t7, 116 # t
	beq $t6, $t7, tempoCommand
	li $t7, 118 # v
	beq $t6, $t7, volumeCommand
	li $t7, 105 # i
	beq $t6, $t7, instrumentCommand
	lw $t1,-1

tempoCommand:
	addi $t5,$t5,2
	lb $s5,($t5)
	subi $s5,$s5,48
tempoLoop:
	addi $t5,$t5, 1
	lb $t8,($t5)
	subi $t8,$t8,48
	beq $t8,77,finishTempo #125=}
	li $t9, 10
	mul $s5, $s5, $t9
	add $s5,$s5,$t8
	j tempoLoop
finishTempo:		# $s5 is now beats/min
	li $t8,7500	# 60000ms/32 1/32beats
	div $s5,$t8,$s5	# $s5 is now ms/32nd note
	j endCommand

volumeCommand:
	addi $t5,$t5,2
	lb $s7,($t5)
	beq $s7,112,p #112='p'
	beq $s7,109,m #109='m'
	beq $s7,102,f #102='f'
	j endCommand
p:
	addi $t5,$t5,1
	lb $s7,($t5)
	beq $s7,112,pp #112='p'
	li $s7,49 #specified MIDI velocity for p
	j endCommand
pp:
	addi $t5,$t5,1
	lb $s7,($t5)
	beq $s7,112,ppp #112='p'
	li $s7,33 #specified MIDI velocity for pp
	j endCommand
ppp:
	addi $t5,$t5,1
	li $s7,16 #specified MIDI velocity for ppp
	j endCommand
m:
	addi $t5,$t5,1
	lb $s7,($t5)
	beq $s7,112,mp #112='p'
	beq $s7,102,mf #102='f'
	j endCommand
mp:
	addi $t5,$t5,1
	li $s7,64 #specified MIDI velocity for mp
	j endCommand
mf:
	addi $t5,$t5,1
	li $s7,80 #specified MIDI velocity for mf
	j endCommand
f:
	addi $t5,$t5,1
	lb $s7,($t5)
	beq $s7,102,ff #112='p'
	li $s7,96 #specified MIDI velocity for f
	j endCommand
ff:
	addi $t5,$t5,1
	lb $s7,($t5)
	beq $s7,102,fff #112='p'
	li $s7,112 #specified MIDI velocity for ff
	j endCommand
fff:
	addi $t5,$t5,1
	li $s7,126 #specified MIDI velocity for fff
	j endCommand

instrumentCommand:
	addi $t5,$t5,2
	lb $s6,($t5)
	subi $s6,$s6,48
instrumentLoop:
	addi $t5,$t5, 1
	lb $t8,($t5)
	subi $t8,$t8,48
	beq $t8,77,insertInstrumentChange #125=}
	li $t9, 10
	mul $s6, $s6, $t9
	add $s6,$s6,$t8
	j instrumentLoop
insertInstrumentChange:
	subi $s6,$s6,1	#convert from MIDI to mars specification
	li $v0,-2
	sw $v0, ($t0)
    	sw $s6, ($t1)
   	#Increment every one of the array indicators
    	addi $t0, $t0, 4
    	addi $t1, $t1, 4
    	addi $t2, $t2, 4
    	addi $t3, $t3, 4

endCommand:
	#Skip past the ending curly brace
	jal nextchar
	#Keep calm and parse
	j continueParse

continueParse:
    	
        #If the next character is nonzero, keep going
    	li $a1, 0
    	bne $t6, $a1, parseloop

playNotes: 
	lw $s4,($s0)
	beqz $s4, endPlay	#if pitch is zero, no more notes
	ble $s4, -3, endPlay
	bge $s4, 109, endPlay
	lw $s4, ($s1)	#long duration also signals end
	bge $s4, 10000, endPlay
	ble $s4, -1, endPlay
	lw $a0, ($s0)	# pitch
	lw $a1, ($s1)	# duration (ms)
	lw $a2, ($s2)	# channel
	lw $a3, ($s3)	# volume
	beq $a0, -1, playRest
	beq $a0, -2, instrumentChange
	li $v0, 37
	syscall		#play the note
	j increment
playRest:
	lw $a0, ($s1)
	li $v0, 32
	syscall
	j increment
instrumentChange:
	li $a0, 0
	li $v0, 38
setInstrumentLoop:
	beq $a0,10,increment
	syscall
	addi $a0,$a0,1
	j setInstrumentLoop
increment:
	add $s0, $s0, 4	#increment array indices
	add $s1, $s1, 4
	add $s2, $s2, 4
	add $s3, $s3, 4
	sub $s4, $s4, 1
	j playNotes
	#return to whatever play menu we were on
endPlay:	
	beq $t4, 1, playFile
	beq $t4, 2, playConsole
end:
	li $v0, 10
	syscall
