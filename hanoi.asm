############ COMP 273, Fall 2024, Assignment 4, Tower of Hanoi - non-recursive ###########
#TODO: Add the info below
# Student ID: 261138380
# Name: Sofie Bieker
# Using my Penalty Waiver on this assignment !!

# TODO: ADD OTHER COMMENTS YOU HAVE HERE AT THE TOP OF THIS FILE
# TODO END

.data
AlgorithmType:	.word 1	# TODO: Which Algorithm to run!
				# 0 Recursive
				# 1 Non-recursive
	
# TODO: add any variables here you if you need
step: .asciiz "Step "
letter: .asciiz " move disk "
from: .asciiz " from"
to: .asciiz "to"
rod1: .asciiz " A "
rod2: .asciiz " B "
rod3: .asciiz " C "
# TODO END
.text
#  There are some helper functions for IO at the end of this file, which might be helpful for you.
# Feel free to write additional functions as necessary to the TO DO block just before the helper functions.

main:
        # read the integer n from the standard input
	jal readInt
	# now $v0 contains the number of disk n
       # check for which algorithm is set to use: Recursive or non-recursive.
        la $t0 AlgorithmType
	lw $t0 ($t0)
	beq $t0 0 TOH_Recursive
	beq $t0 1 TOH_Nonrecursive
	li $v0 10 # exit if the algorithm number is out of range
        syscall	

TOH_Recursive:
# TODO:
#       Use a recursive algorithm described in the assignment document to print the solution steps. Make sure you follow the output format.
# Set the first breakpoint to measure cache performance and instruction count for the recursive method at the first instruction of this label
# you set breakpoints when you assemble the asm file
# Step i: move disk <disk label> from <rod label> to <rod label>.
#v0 has the number for n
add $a0, $v0, $0
la $a1, rod1
la $a2, rod3
la $a3, rod2
addi $t5, $0, 1 #t5 is the step counter

jal recursive
j end

recursive:
beq $a0, 1, moveOne

addi $sp, $sp, -20
sw $ra, 16($sp)
sw $a3, 12($sp)
sw $a2, 8($sp)
sw $a1, 4($sp)
sw $a0, 0($sp)

move $t1, $a3
move $a3, $a2
move $a2, $t1
addi $a0, $a0, -1
jal recursive
 
lw $ra, 16($sp)
lw $a3, 12($sp)
lw $a2, 8($sp)
lw $a1, 4($sp)
lw $a0, 0($sp)
jal moveOne

lw $ra, 16($sp)
lw $a0, 0($sp)

move $t3, $a3
move $a3, $a1
move $a1, $t3
addi $a0, $a0, -1
jal recursive

lw $ra, 16($sp)
lw $a3, 12($sp)
lw $a2, 8($sp)
lw $a1, 4($sp)
lw $a0, 0($sp)
addi $sp, $sp, 20
jr $ra

moveOne:
addi $t0, $a0, 0
la $a0, step
li $v0, 4
syscall
move $a0, $t5
li $v0, 1
syscall
la $a0, letter
li $v0, 4
syscall
move $a0, $t0      
li $v0, 1
syscall
la $a0, from           
li $v0, 4
syscall
move $a0, $a1
li $v0, 4
syscall
la $a0, to
li $v0, 4
syscall
move $a0, $a2
li $v0, 4
syscall
li $a0, 10
li $v0, 11
syscall

addi $t5, $t5, 1
jr $ra

end:
# TODO END
# Set the second breakpoint to measure cache performance and instruction count for the recursive method at the following line
li $v0, 10	# exit the program
syscall


TOH_Nonrecursive:
# TODO: Use a non-recursive algorithm to print the solution steps. Make sure you follow the output format.
# Set the first breakpoint to measure cache performance and instruction count for the non-recursive method at the first instruction of this label
add $t3, $v0, $0 #t3 = number of disks
move $t4, $t3 #moves number of disks to $t4

la $t0, rod1 
la $t1, rod2 
la $t2, rod3


li $t5, 1 #num of moves
addi $t9, $t9, 1 #step counter +1

jal calc_total #calculates total number of moves required for the loop

loop1:
bgt $t9, $t5, end2 #if step counter is greater than number of moves required, end loop/function
move $t7, $t9
li $t8, 0

loop2: #finds which disk number based on step number
andi $t4, $t7, 1
bnez $t4, mover
srl $t7, $t7, 1
addi $t8, $t8, 1 
j loop2

mover: #just prints the answer
addi $t8, $t8, 1
la $a0, step
li $v0, 4
syscall

move $a0, $t9 #step number
li $v0, 1
syscall

la $a0, letter
li $v0, 4
syscall

move $a0, $t8 # needs to be disk number
li $v0, 1
syscall

la $a0, from           
li $v0, 4
syscall

move $a0, $t0 #source rod
li $v0, 4
syscall

la $a0, to
li $v0, 4
syscall

move $a0, $t2 #destination rod
li $v0, 4
syscall

li $a0, 10
li $v0, 11
syscall

addi $t9, $t9, 1 #step counter +1
rem $t8, $t9, 3 
beq $t8, 1, A
beq $t8, 2, B
beq $t8, 0, C

j loop1

end2:
# TODO END
# Set the second breakpoint to measure cache performance and instruction count for the non-recursive method at the following line
li $v0, 10	# exit the program
syscall

# TODO: your functions here
calc_total:
beqz $t3, total_moves
mul $t5, $t5, 2 #iteratively multiplys by 2, to get 2^n
sub $t3, $t3, 1
j calc_total

total_moves:
sub $t5, $t5, 1 # 2^n -1

andi $t7, $t4, 1 #if even, swap
beqz $t7, swap 
jr $ra

swap: #swaps destination with auxilary pole IF EVEN
move $t8, $t1 #t8 = rod1
move $t1, $t2 #t1 = rod2
move $t2, $t8 #t2 = rod1
jr $ra

A:
la $t0, rod1 
la $t1, rod2 
la $t2, rod3

j loop1

B:
move $t8, $t2 # t8 = desination
move $t2, $t1 # t2 = auxilary
move $t1, $t8 #auxilary = source

j loop1

C:
move $t8, $t0 # t8 = source
move $t0, $t2 # t0 = destination
move $t2, $t1 # t2 = auxilary
move $t1, $t8 #auxilary = source

j loop1

# TODO END

########### Helper functions for IO ###########

# read an integer
# int readInt()
readInt:
	li $v0, 5
	syscall
	jr $ra
	
# print an integer
# printInt(int n)
printInt:
	li $v0, 1
	syscall
	jr $ra

# print a character
# printChar(char c)
printChar:
	li $v0, 11
	syscall
	jr $ra
	
# print a null-ended string
# printStr(char *s)
printStr:
	li $v0, 4
	syscall
	jr $ra
