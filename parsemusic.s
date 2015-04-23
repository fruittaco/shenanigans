.macro printtext(%msg)
la $a0, %msg
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

.macro readfile(%filedescrip, %inputbuf)
move $a0, %filedescrip
move $a1, %inputbuf
li $a2, 0
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
parsefile:
move $t0, $s0
move $t1, $s1
move $t2, $s2
move $t3, $s3
move $t5, $s5

parseloop:
    #Read in the pitch
    lw $t6, (%t5)
    #Read in the duration
    lw $t7, 1(%t5)

    #Pitch: a
    li $a0, 97
    bne $t6, $a0, elseb
    
    

    #increment output array addresses
    addi $t0, $t0, 4
    addi $t1, $t1, 4

    #increment input position
    addi $t5, $t5, 2

    
    





.globl main

main:
    addu $s7, $0, $ra

    .data
    nl: .asciiz "\n"
    welcomemsg: .asciiz "Welcome to Shenanigans Music Interpreter\n"
    filemsg: .asciiz "Choose a music file to load\n"
    readme: .asciiz "README.txt"
    #TODO: add in a help file or something

    .text
    printtext(welcomemsg)

    li $a0, 255
    malloc($a0, $s5)
    readstring($s5)
    openfile($s5, $s5)
    #TODO: test non-negative
    printint($v0)
    printtext(nl)
#TODO: Zero the string's newline and get the string length

    addu $ra, $0, $s7
    jr $ra

