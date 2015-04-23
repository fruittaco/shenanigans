removeNewline:
	#$s5-string address
	#$s6-character count
	move $t1,$s5
	move $s6,$0
loop:
	lb $t2,($t1)
	addi $t1,$t1,1
	addi $s6,$s6,1
	bnez $t2, loop
	subi $t1,$t1,1
	sb $0,$t1
	subi $s6,$s6,1
	

playNotes: 
	ble $s4, 0, end	#$s4 is the number of notes remaining to be played
	lw $a0, ($s0)	#pitch
	lw $a1, ($s1)	#duration (ms)
	lw $a2, 0	#instrument (currently hard-coded to grand piano, final version may implement multiple insturments, stored in $s2)
	lw $a3, 63	#volume (will be adjustable in final version, stored in $s3)
	li $v0, 33
	syscall		#play the note
	add $s0, $s0, 4	#increment array indices
	add $s1, $s1, 4
	add $s2, $s2, 4
	add $s3, $s3, 4
	sub $s4, $s4, 1
	j playNotes
end:
	li $v0, 10
	syscall
