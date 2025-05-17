# Sofie Bieker 261138380

.data
commands: .asciiz "Commands (encrypt, decrypt, quit): "
encryptText: .asciiz "\nEnter text to encrypt (upper case letters only): \n"
decryptText: .asciiz "\nEnter text to decrypt (upper case letters only): \n"
keyText: .asciiz "Enter key (upper case letters only): "
finEncrypt: .asciiz "Encrypted text: "
finDecrypt: .asciiz "Decrypted text: "
newline: .asciiz "\n"

input_space: .space 2
text_space: .space 501
final_text: .space 501
key_space: .space 51

.text

main:
la $a0, commands
li $v0, 4
syscall

li $v0, 12
syscall
move $t3, $v0

li $t0, 'e'
li $t1, 'd'
li $t2, 'q'

#decides which function to call
beq $t3, $t0, call_encrypt
beq $t3, $t1, call_decrypt
beq $t3, $t2, quit

la $a0, newline
li $v0, 4
syscall
j main

call_encrypt:
#processes the input texts
la $a0, encryptText
li $v0, 4
syscall

la $a0, text_space
li $a1, 500
li $v0, 8
syscall  
la $t0, text_space  


la $a0, keyText
li $v0, 4
syscall

la $a0, key_space
li $a1, 50
li $v0, 8
syscall  

la $a1, key_space 
la $a2, final_text 
la $a0, ($t0)

jal terminate_key 

la $a0, finEncrypt
li $v0, 4
syscall

la $a0, final_text
li $v0, 4
syscall
j main


terminate_key:
#null terminates the key
lb $t9, 0($a1)             
beq $t9, 10, replace_newline     
addi $a1, $a1, 1           
j terminate_key

replace_newline:
sb $zero, 0($a1)  

encrypt_loop:
#goes through the input and encrypts it
lb $t3, 0($a0)
beq $t3, $zero, end_encrypt

li $t7, 'A'
li $t8, 'Z'
blt $t3,$t7 skip
bgt $t3, $t8, skip

lb $t4, 0($a1)
beq $t4, $zero, reset_key

subi $t3, $t3, 'A'
subi $t4, $t4, 'A'

add $t5, $t3, $t4
li $t6, 26
div $t5, $t6
mfhi $t5

addi $t5, $t5, 'A'
sb $t5, 0($a2)

addi $a2, $a2, 1
addi $a0, $a0, 1
addi $a1, $a1, 1

lb $t4, 0($a1)
beq $t4, $zero, reset_key

j encrypt_loop

reset_key:
#if at end of key, resets
la $a1, key_space
j encrypt_loop

skip:
#skips non-letter character
sb $t3, 0($a2)
addi $a2, $a2, 1
addi $a0, $a0, 1
j encrypt_loop

end_encrypt:
#finished encryption, loads the answer into v0 and returns
sb $zero, 0($a2)
jr $ra


call_decrypt:
#gets user input and key, then calls for decryption and outputs decrypted text
la $a0, decryptText
li $v0, 4
syscall

la $a0, text_space
li $a1, 500
li $v0, 8
syscall 
la $t0, text_space 

la $a0, keyText
li $v0, 4
syscall

la $a0, key_space
li $a1, 50
li $v0, 8
syscall  

la $a1, key_space 
la $a2, final_text 
la $a0, ($t0)
    
jal d_terminate_key

la $a0, finDecrypt
li $v0, 4
syscall
    
la $a0, final_text
li $v0, 4
syscall
j main

d_terminate_key:
#goes through the key to find the newline and replace
lb $t9, 0($a1)             
beq $t9, 10, d_replace_newline     
addi $a1, $a1, 1           
j d_terminate_key

d_replace_newline:
#replaces the newline with a null terminator
sb $zero, 0($a1)  

decrypt_loop:
#loops through the inputted string and decrypts according to the code
lb $t3, 0($a0)
beq $t3, $zero, end_decrypt

li $t7, 'A'
li $t8, 'Z'
blt $t3, $t7 d_skip
bgt $t3, $t8, d_skip

lb $t4, 0($a1)
beq $t4, $zero, d_reset_key

subi $t3, $t3, 'A'
subi $t4, $t4, 'A'

sub $t5, $t3, $t4
li $t6, 26
div $t5, $t6
mfhi $t5

addi $t5, $t5, 'A'
sb $t5, 0($a2)

addi $a2, $a2, 1
addi $a0, $a0, 1
addi $a1, $a1, 1

lb $t4, 0($a1)
beq $t4, $zero, d_reset_key

j decrypt_loop

d_reset_key:
#resets the key if it reaches the end
la $a1, key_space
j decrypt_loop

d_skip:
#skips non-letter characters
sb $t3, 0($a2)
addi $a2, $a2, 1
addi $a0, $a0, 1
j decrypt_loop

end_decrypt:
#ends the decryption
sb $zero, 0($a2)
jr $ra

quit:
#quits the program if q is inputted
li $v0, 10
syscall
