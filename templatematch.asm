 #Group 145
 #Q1: Yes, they do fall into the same block, and this adds onto the cache conflict. But i tried multiple types of adding .space directives and none of them improved the hit rate, in fact some made it worse.
 #Q2: No, it doesn't matter, because the template is the last things to be written and first to be accessed. So therefore, it doesn't matter if it falls into the same block, because they don't need to be accessed at the same time
 
 
.data
.align 2 
displayBuffer:  .space 0x40000 # space for 512x256 bitmap display 
errorBuffer:    .space 0x40000 # space to store match function
templateBuffer: .space 0x100   # space for 8x8 template
imageFileName:    .asciiz "pxlcon512x256cropgs.raw" 
templateFileName: .asciiz "template8x8gsLRtest.raw"
# struct bufferInfo { int *buffer, int width, int height, char* filename }
imageBufferInfo:    .word displayBuffer  512 128   imageFileName
errorBufferInfo:    .word errorBuffer    512 128   0
templateBufferInfo: .word templateBuffer 8   8    templateFileName

.text
main:	la $a0, imageBufferInfo
	jal loadImage
	la $a0, templateBufferInfo
	jal loadImage
	la $a0, imageBufferInfo
	la $a1, templateBufferInfo
	la $a2, errorBufferInfo
	jal matchTemplate # MATCHING DONE HERE
	la $a0, errorBufferInfo
	jal findBest
	la $a0, imageBufferInfo
	move $a1, $v0
	jal highlight
	la $a0, errorBufferInfo	
	jal processError
	li $v0, 10		# exit
	syscall
	

##########################################################
# matchTemplate( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplate:	
	lw $s0, 0($a0) # address of displayBuffer
	lw $s1, 0($a1) # address of templateBuffer
	lw $s2, 0($a2) # address of errorBuffer
	
	lw $s3, 8($a0) # image height 128
	lw $s4, 4($a0) # image width 512
	
	subi $a1, $s3, 8 # subtract 8 from height to use for later 
	subi $a2, $s4, 8 # subtract 8 from width to use for later
	
	li $t0 0 #y - repeat until greater than a1
	li $t1 0 #x - repeat until greater than a2
	li $t2 0 #j - loop until equal to 8/ s6
	li $t3 0 #i - loop until equal to 8 / s6
	li $s5 4
	li $s6 8
	li $v0 0

loopHeight:
	bgt $t0 $a1 heightDone
	li $t1 0 #x
		
loopWidth:
	bgt $t1 $a2 widthDone
	li $t2 0 #j	

loopj:
	beq $t2 $s6 loopjDone
	li $t3 0 #i

loopi: 
	#SAD address calculation
	mul $t4 $t0 $s4 #y * width
	add $t4 $t4 $t1 # + x
	mul $t4 $t4 $s5 # x 4
	
	add $v0 $s2 $t4 #adds to base value- this is just the offset!!
	
	lw $t6, 0($v0) # loads current SAD

	#image[x][y]
	beq $t3 $s6 loopiDone 
	
	#(y)*512 + x
	mul $t4 $t0 $s4 #(y) * 512
	add $t4 $t4 $t1 #(y) * 512 + x
	
	#j * 512 + x
	mul $t5 $t2 $s4 # j * 512
	add $t5 $t5 $t3 # j * 512 + i

	# [y * 512 + x] + [j * 512 + i]
	add $t4 $t4 $t5 # Combine display offset with template offset 
	
	mul $t4 $t4 $s5 # ((y+j)*512 + x+i)*4 size of pixel  
	
	add $t4 $s0 $t4 # add base address of diplay buffer -> t4 holds address of display pixel
	
	# (j*8 +i)
	mul $t5 $t2 $s6 #j * width (8)
	add $t5 $t5 $t3 #+i
	mul $t5 $t5 $s5 #mult by 4 
	
	add $t5 $t5 $s1 # base address of template -> t5 holds address of template pixel
	
	lbu $t4 0($t4) # loads value at display pixel
	lbu $t5 0($t5) # loads value at template pixel
	
	sub $t4 $t4 $t5 # gets difference between intensity
	
	abs $t4 $t4
	add $t6 $t6 $t4 # adds to current SAD
	
	sw $t6 0($v0) #stores SAD
	
	addi $t3, $t3, 1 # i+1
	j loopi	
	
loopiDone:
	addi $t2 $t2 1 # j+1
	j loopj
	
loopjDone:
	addi $t1 $t1 1 # x+1
	j loopWidth
	
widthDone:
	addi $t0 $t0 1 # y+1
	j loopHeight

heightDone:
	jr $ra # end
	
	

	
##########################################################
# matchTemplateFast( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplateFast:	
	lw $s0, 0($a0) # address of displayBuffer
	lw $s1, 0($a1) # address of templateBuffer
	lw $s2, 0($a2) # address of errorBuffer
	
	lw $s3, 8($a0) # image height 128
	lw $s4, 4($a0) # image width 512
	
	subi $a1, $s3, 8 # subtract 8 from height to use for comparing later 
	subi $a2, $s4, 8 # subtract 8 from width to use for comparing later
	
	
	li $s5 0 #j

fastLoopj:
	
	beq $s5 8 jLoopDone # matchdone
	 
	# 128/4 = 32 rows
	mul $t0 $s5 32 # mult j by number of rows
	add $t0 $t0 $s1 # add template base adress to j (template height offset) to get leftmost pixel!
	
	# increase offset by 4 to get the next pixel
	lbu $t1, 1($t0) 
	lbu $t2, 5($t0) 
	lbu $t3, 9($t0) 
	lbu $t4, 13($t0) 
	lbu $t5, 17($t0)	
	lbu $t6, 21($t0)
	lbu $t7, 25($t0) 
	lbu $t8, 29($t0) 
	
	li $s6 0 # y value
	
fastLoopy: 
	 bgt $s6 $a1 yLoopDone # y <= img height -8
	 
	 li $s7 0 # x value
	 
fastLoopx:
	bgt $s7 $a2 xLoopDone # x <= img width -8
	
	# accessing image buffer
	add $t9 $s6 $s5 # y+j
	
	mul $t9 $t9 $s4 #(y+j) * width
	add $t9 $t9 $s7  #(y+j)*width +x
	mul $t9 $t9 4 # mult by pixel size
	add $t9 $t9 $s0 # base adfress of image + offset
	
	#accessing error buffer SAD
	mul $t0 $s6 $s4 # y * width 
	add $t0 $t0 $s7 # y * width +x
	mul $t0 $t0 4 # times 4

	add $v0 $t0 $s2 # base adress of error + offset
	
	lw $a3 0($v0) # load current SAD 
	
	# steps for SAD[x][y]
	# load byte of intensity from image 
	# subtract to get difference from template row
	# get absolute value of difference
	# add abs difference + SAD
	
	lbu $t0 1($t9) 
	sub $t0, $t0, $t1 
	abs $t0, $t0 
	add $a3, $a3, $t0 
	
	lbu $t0 5($t9) 
	sub $t0, $t0, $t2 
	abs $t0, $t0
	add $a3, $a3, $t0 
	
	lbu $t0 9($t9)
	sub $t0, $t0, $t3 
	abs $t0, $t0 
	add $a3, $a3, $t0 
	
	lbu $t0 13($t9) 
	sub $t0, $t0, $t4 
	abs $t0, $t0 
	add $a3, $a3, $t0 
	
	lbu $t0 17($t9) 
	sub $t0, $t0, $t5 
	abs $t0, $t0 
	add $a3, $a3, $t0 
	
	lbu $t0 21($t9) 
	sub $t0, $t0, $t6
	abs $t0, $t0 
	add $a3, $a3, $t0
	
	lbu $t0 25($t9) 
	sub $t0, $t0, $t7 
	abs $t0, $t0 
	add $a3, $a3, $t0 
	
	lbu $t0 29($t9) 
	sub $t0, $t0, $t8 
	abs $t0, $t0 
	add $a3, $a3, $t0
	
	sw $a3 0($v0) # store SAD in error buffer
	
	addi $s7 $s7 1 # x + 1
	j fastLoopx
	
xLoopDone:
	addi $s6 $s6 1 # y + 1 	
	j fastLoopy
	
yLoopDone:
	addi $s5 $s5 1 # j + 1
	j fastLoopj
	
	# TODO: write this function!
jLoopDone:
	jr $ra	
	
	
	
	

	
	
	
###############################################################
# loadImage( bufferInfo* imageBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
loadImage:	lw $a3, 0($a0)  # int* buffer
		lw $a1, 4($a0)  # int width
		lw $a2, 8($a0)  # int height
		lw $a0, 12($a0) # char* filename
		mul $t0, $a1, $a2 # words to read (width x height) in a2
		sll $t0, $t0, 2	  # multiply by 4 to get bytes to read
		li $a1, 0     # flags (0: read, 1: write)
		li $a2, 0     # mode (unused)
		li $v0, 13    # open file, $a0 is null-terminated string of file name
		syscall
		move $a0, $v0     # file descriptor (negative if error) as argument for read
  		move $a1, $a3     # address of buffer to which to write
		move $a2, $t0	  # number of bytes to read
		li  $v0, 14       # system call for read from file
		syscall           # read from file
        		# $v0 contains number of characters read (0 if end-of-file, negative if error).
        		# We'll assume that we do not need to be checking for errors!
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0, $a3	   # start address
		add $t1, $a3, $a2  # end address
loadloop:	lw $t2, ($t0)
		sw $t2, ($t0)
		addi $t0, $t0, 4
		bne $t0, $t1, loadloop
		jr $ra
		
		
#####################################################
# (offset, score) = findBest( bufferInfo errorBuffer )
# Returns the address offset and score of the best match in the error Buffer
findBest:	lw $t0, 0($a0)     # load error buffer start address	
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		li $v0, 0		# address of best match	
		li $v1, 0xffffffff 	# score of best match	
		lw $a1, 4($a0)    # load width
        		addi $a1, $a1, -7 # initialize column count to 7 less than width to account for template
fbLoop:		lw $t9, 0($t0)        # score
		sltu $t8, $t9, $v1    # better than best so far?
		beq $t8, $zero, notBest
		move $v0, $t0
		move $v1, $t9
notBest:		addi $a1, $a1, -1
		bne $a1, $0, fbNotEOL # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
fbNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, fbLoop
		lw $t0, 0($a0)     # load error buffer start address	
		sub $v0, $v0, $t0  # return the offset rather than the address
		jr $ra
		

#####################################################
# highlight( bufferInfo imageBuffer, int offset )
# Applies green mask on all pixels in an 8x8 region
# starting at the provided addr.
highlight:	lw $t0, 0($a0)     # load image buffer start address
		add $a1, $a1, $t0  # add start address to offset
		lw $t0, 4($a0) 	# width
		sll $t0, $t0, 2	
		li $a2, 0xff00 	# highlight green
		li $t9, 8	# loop over rows
highlightLoop:	lw $t3, 0($a1)		# inner loop completely unrolled	
		and $t3, $t3, $a2
		sw $t3, 0($a1)
		lw $t3, 4($a1)
		and $t3, $t3, $a2
		sw $t3, 4($a1)
		lw $t3, 8($a1)
		and $t3, $t3, $a2
		sw $t3, 8($a1)
		lw $t3, 12($a1)
		and $t3, $t3, $a2
		sw $t3, 12($a1)
		lw $t3, 16($a1)
		and $t3, $t3, $a2
		sw $t3, 16($a1)
		lw $t3, 20($a1)
		and $t3, $t3, $a2
		sw $t3, 20($a1)
		lw $t3, 24($a1)
		and $t3, $t3, $a2
		sw $t3, 24($a1)
		lw $t3, 28($a1)
		and $t3, $t3, $a2
		sw $t3, 28($a1)
		add $a1, $a1, $t0	# increment address to next row	
		add $t9, $t9, -1		# decrement row count
		bne $t9, $zero, highlightLoop
		jr $ra

######################################################
# processError( bufferInfo error )
# Remaps scores in the entire error buffer. The best score, zero, 
# will be bright green (0xff), and errors bigger than 0x4000 will
# be black.  This is done by shifting the error by 5 bits, clamping
# anything bigger than 0xff and then subtracting this from 0xff.
processError:	lw $t0, 0($a0)     # load error buffer start address
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		lw $a1, 4($a0)     # load width as column counter
        		addi $a1, $a1, -7  # initialize column count to 7 less than width to account for template
pebLoop:		lw $v0, 0($t0)        # score
		srl $v0, $v0, 5       # reduce magnitude 
		slti $t2, $v0, 0x100  # clamp?
		bne  $t2, $zero, skipClamp
		li $v0, 0xff          # clamp!
skipClamp:	li $t2, 0xff	      # invert to make a score
		sub $v0, $t2, $v0
		sll $v0, $v0, 8       # shift it up into the green
		sw $v0, 0($t0)
		addi $a1, $a1, -1        # decrement column counter	
		bne $a1, $0, pebNotEOL   # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width to reset column counter
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
pebNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, pebLoop
		jr $ra
