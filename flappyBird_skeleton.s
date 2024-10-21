.data
# Each single-value variable is stored as a word

#--------------------------------------------------------------------
# An array of 4 obstacles, each obstacle has 5 variables: 
# topPipe, bottomPipe, isPassedOn, topPipeType, bottomPipeType
# Each top/bottom pipe is a Rectangle, it has 4 single-valued variables: x, y, width, height
# isPassedOn: 0 if the flappy bird has not passed the obstacle, 1 otherwise
# topPipeType/bottomPipeType: 0, 1, 2 (three different types of pipes)
#--------------------------------------------------------------------
obstacles: .word 0:44
#--------------------------------------------------------------------
# Rectangle: x, y, width, height
# x, y: top-left corner coordinate of the rectangle
# width, height: width and height of the rectangle
# each box is a Rectangle
#--------------------------------------------------------------------
backgroundBox: .word 0:4    
floorBox: .word 0:4    
flappyBox: .word 0:4    

birdIdx: .word 0 # the index of the bird image
record: .word 0 # the highest score
point: .word 0 # the current score
objectVelocity: .word 6 # the velocity of the obstacles
winningScore: .word 20 # the score to win the game
won: .word -1 # 1 if the game is won, 0 otherwise, -1 if the game is not started
inGame: .word 0 # 1 if the game is in progress, 0 otherwise and display the start screen
direction: .word -1 # 1 if the bird is controlled by mouse (mouse pressed), 0 if the bird is controlled by gravity (mouse released), -1 if the game is not started
intervalFrame: .word 5 # the interval of the bird animation frame, the bird image changes every 5 frames (for flappying wings effect)
velocity: .word 0 # the vertical velocity of the flappy bird
gravity: .word 1 # the gravity of the world
# Constants
SIZE: .word 1024 # the size of the game window
obstacleDistance: .word 400 # the vertical distance between two pipes in the same obstacle


.text


# syscall initializeGUI();
addi $v0, $zero, 300
syscall

#--------------------------------------------------------------------
# procedure: initialize data for the game
#--------------------------------------------------------------------
initializeData:

    la $t0, SIZE
    lw $s0, 0($t0) # $s0: SIZE

    # initialize position of the background
    la $s1, backgroundBox
    sw $zero, 0($s1)
    sw $zero, 4($s1)
    addi $t0, $zero, 1716
    sw $t0, 8($s1)
    addi $t0, $zero, 1024
    sw $t0, 12($s1)

    # initialize position of the floor
    la $s1, floorBox
    sw $zero, 0($s1)
    addi $t0, $s0, -220
    sw $t0, 4($s1)
    addi $t0, $zero, 1848
    sw $t0, 8($s1)
    addi $t0, $zero, 220
    sw $t0, 12($s1)

    jal startPositionObs

    # initialize the width and height of the flappy bird
    la $s2, flappyBox
    addi $t0, $zero, 68
    sw $t0, 8($s2)
    addi $t0, $zero, 48
    sw $t0, 12($s2)

    # place the flappy bird to initial position
    jal startPositionFlappy


endInitializeData:

# syscall renderer.start();
addi $v0, $zero, 301
syscall

#--------------------------------------------------------------------
# procedure: main game loop
#--------------------------------------------------------------------
mainGameLoop:

    jal updateBackgroundFloor
    jal updateBirdAnimation

    # syscall get Mouse input as direction
    addi $v0, $zero, 302
    syscall
    la $t0, direction
    sw $v0, 0($t0)
    
    jal updateObstacles
    jal updateFlappy


endMainGameLoop:
    # syscall renderer.draw();
    addi $v0, $zero, 303
    la $a0, obstacles
    syscall
    # syscall checkSolution()
    addi $v0, $zero, 305
    la $a0, obstacles
    syscall
    # syscall Thread.sleep();
    addi $v0, $zero, 32
    addi $a0, $zero, 16
    syscall
    j mainGameLoop


#--------------------------------------------------------------------
# task 2: Move the background and the floor, 
#         reset their x coordinates when necessary
#--------------------------------------------------------------------
updateBackgroundFloor:

	#***** Task 2 *****
    # step 1: subtract value 1 from the x coordinate attribute of the backgroundBox.
    # step 2: subtract value 3 from the x coordinate attribute of the floorBox.
    # step 3: check if backgroundBox.x + backgroundBox.width is <= 0,
    #         if true, set backgroundBox.x to 0.
    # step 4: check if floorBox.x + floorBox.width is <= 0,
    #         if true, set floorBox.x to floorBox.x + floorBox.width
    # 
    # Additional note (no need to understand): step 3 and step 4 may be confusing here. The image used to render 
    # the background and the floor has larger widths than the SIZE of the game window. 
    # When GUI renders the image, it will render the image twice, one after another.
    # Therefore, the background and the floor will be rendered seamlessly.
    # We directly reset the backgroundBox.x to 0 because the background moves only one pixel each time.
    # The floor moves three pixels each time, so we need to reset the floorBox.x to floorBox.x + floorBox.width
    # so that the floor will be rendered seamlessly after reset.
	#------ Your code starts here ------
	# step 1
	la $t0, backgroundBox
	lw $t1, 0($t0) # t1 = bgB.x
	lw $t2, 8($t0) # t2 = bgB.w
	addi $t1, $t1, -1
	sw $t1, 0($t0)
	# do step 3 first
	add $t2, $t2, $t1
	bgt $t2, 0, falseOfBgCheck
	sw $zero, 0($t0)
	falseOfBgCheck:
	# step 2
	la $t0, floorBox
	lw $t1, 0($t0)
	lw $t2, 8($t0)
	addi $t1, $t1, -3
	sw $t1, 0($t0)
	# step 4
	add $t2, $t2, $t1
	bgt $t2, 0, falseOfFCheck
	sw $zero, 0($t0)
	falseOfFCheck:
	#------ Your code ends here ------

    jr $ra


#--------------------------------------------------------------------
# procedure: Loop through the bird images, 
#            update the birdIdx every 5 frames
#--------------------------------------------------------------------
updateBirdAnimation:

    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s1, 4($sp)
    sw $s0, 0($sp)

    la $s0, intervalFrame # $s0: intervalFrame address
    la $s1, birdIdx # $s1: birdIdx address

    lw $t0, 0($s0) # $t0: intervalFrame
    addi $t0, $t0, 1
    sw $t0, 0($s0)

    add $t1, $t0, $zero
    addi $t2, $zero, 5
    sub $t1, $t1, $t2
    blez $t1, endUpdateBirdAnimation

    sw $zero, 0($s0) # intervalFrame = 0
    lw $t0, 0($s1) # $t0: birdIdx
    addi $t0, $t0, 1
    sw $t0, 0($s1)

    addi $t1, $zero, 2
    sub $t0, $t0, $t1
    blez $t0, endUpdateBirdAnimation

    sw $zero, 0($s1) # birdIdx = 0


endUpdateBirdAnimation:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra


#--------------------------------------------------------------------
# task 3: Loop through each obstacle and update each of them
#--------------------------------------------------------------------
updateObstacles:
	#***** Task 3 *****
    # step 1: if the value of variable direction != -1, set variable inGame to 1.
    # step 2: if variable inGame is 1, proceeds to next step, otherwise, end this procedure.
    # step 3: loop through each obstacle. For each obstacle:
    #     step 3.1: subtract value of variable objectVelocity from the topPipe.x and bottomPipe.x.
    #     step 3.2: if topPipe.x + topPipe.width < 0, use procedure resetToNewPosition to reset the obstacle to a new position.
    #               When calling the procedure, pass the address of the obstacle and the new x coordinate as arguments.
    #               The new x coordinate is (SIZE + topPipe.width + 110). You can read the resetToNewPosition procedure for more details.
    #     step 3.3: use procedure intersects to check if the flappy bird intersects with the topPipe or bottomPipe.
    #               If intersects, sets variable won to 0 and calls procedure handleGameEnd. 
    #               When returned from handleGameEnd, end this procedure.
    #     step 3.4: call procedure updateGamePointLevel to update the score and level. The argument is the address of the obstacle.
    #               When returned from updateGamePointLevel, check if variable inGame is 0, if it is 0, then end this procedure.
    #     step 3.5: proceed to the next obstacle.
	#------ Your code starts here ------
	# step 1
	lw $t0, direction
	beq $t0, -1, falseOfUOCheck
	li $t0, 1
	sw $t0, inGame
	falseOfUOCheck:
	# step 2
	lw $t0, inGame # t0 = inGame
	bne $t0, 1, endOfUpObsfirst
	# step 3.1
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	li $s0, 0 # loop counter
	loopOfUpObs:
	beq $s0, 4, endOfUpObs
	li $t2, 11
	mult $s0, $t2
	mflo $t2
	sll $t2, $t2, 2
	la $s1, obstacles
	add $s1, $s1, $t2
	#la $s1, obstacles($t2) # load obstacle x
	lw $t2, 0($s1) # topPipe.x
	lw $t4, 16($s1) # bottomPipe.x
	lw $t5, objectVelocity
	sub $t2, $t2, $t5
	sub $t4, $t4, $t5
	sw $t2, 0($s1)
	sw $t4, 16($s1)
	# step 3.2
	lw $t4, 8($s1) # topPipe.w
	add $t2, $t2, $t4
	bgez $t2, dunCallreset
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a0, $s1
	lw $a1, SIZE
	add $a1, $a1, $t4
	addi $a1, $a1, 110
	jal resetToNewPosition
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	dunCallreset:
	# 3.3
	la $a0, flappyBox
	move $a1, $s1
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal intersects
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	beq $v0, 1, theyIntersects
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, flappyBox
	la $a1, 16($s1)
	jal intersects
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	beq $v0, 1, theyIntersects
	j theyDidnt
	theyIntersects:
	sw $zero, won
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal handleGameEnd
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j endOfUpObs
	theyDidnt:
	# 3.4
	move $a0, $s1
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal updateGamePointLevel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	lw $t3, inGame
	bne $t3, 0, continueUpObs
	j endOfUpObs
	#------ Your code ends here ------
	#3.5
	continueUpObs:
	addi $s0, $s0, 1
	j loopOfUpObs
endOfUpObs:
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 8
endOfUpObsfirst:
    jr $ra


#--------------------------------------------------------------------
# task 4: update game points if the bird has passed by an obstacle 
#         and decide whether to win the game by checking the winning score. 
#         Update variable objectVelocity to increase the difficulty
#--------------------------------------------------------------------
# $a0: obstacles[i] address
updateGamePointLevel:
	#***** Task 4 *****
    # step 1: if (flappyBox.x <= topPipe.x + topPipe.width) end this procedure.
    #         if the variable isPassedOn of the current obstacle is 1, end this procedure.
    # step 2: set the variable isPassedOn of the current obstacle to 1.
    # step 3: increment the variable point by 1.
    # step 4: if the variable point is larger than the variable record, 
    #         assign the value of variable point to the variable record.
    # step 5: if the variable point is equal to the variable winningScore,
    #         set the variable won to 1 and call procedure handleGameEnd.
    #         Then end this procedure.
    # step 6: if the two variables fulfill the following condition:
    #         (point % 2 == 0) && (objectVelocity < 12), increment the variable objectVelocity by 1.
	#------ Your code starts here -----
	# step 1
	lw $t0, 0($a0) # topPipe.x 
	lw $t1, 8($a0) # topPipe.w
	add $t0, $t0, $t1
	la $t1, flappyBox # flappy x
	lw $t1, 0($t1)
	ble $t1 , $t0, endOfGPL
	lw $t0, 32($a0)
	beq $t0, 1, endOfGPL
	#step2
	li $t0, 1
	sw $t0, 32($a0)
	#step3
	lw $t0, point
	addi $t0, $t0, 1
	sw $t0, point
	#step4
	lw $t1, record
	ble $t0, $t1, falseIfOfGPL
	sw $t0, record
	falseIfOfGPL: #step5
	lw $t1, winningScore
	bne $t1, $t0, falseIf2GPL
	li $t0, 1
	sw $t0, won
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal handleGameEnd
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j endOfGPL
	falseIf2GPL:#step6
	lw $t0, point
	li $t1, 2
	div $t0, $t1
	mfhi $t0
	bne $t0, 0, endOfGPL
	lw $t0, objectVelocity
	bge $t0, 12, endOfGPL
	addi $t0, $t0, 1
	sw $t0, objectVelocity
	#------ Your code ends here ------
endOfGPL:
    jr $ra


#--------------------------------------------------------------------
# task 5: update the bird's velocity based on mouse response and gravity, 
#         update the bird's vertical position based on its velocity. 
#         Check if the bird has collided with the floor or the ceiling 
#         and end the game accordingly
#--------------------------------------------------------------------
updateFlappy:
	#***** Task 5 *****
    # step 1: if the variable inGame is 0, end this procedure.
    # step 2: if the variable (intervalFrame % 2 == 0), update the bird velocity and position, otherwise proceeds to step 3.
    #        step 2.1: if variable direction is 0, increment the variable velocity by the value of variable gravity.
    #        step 2.2: if variable direction is 1, sets variable velocity to -9.
    #        step 2.3: update flappyBox.y as follows: flappyBox.y = flappyBox.y + velocity.
    # step 3: if flappyBox.y + flappyBox.height >= SIZE - gameData.floorBox.height, end game,
    #         if flappyBox.y <= 0, end game.
    #         If end game condition is met, set variable won to 0 and call procedure handleGameEnd.
	#------ Your code starts here ------
	#step1
	lw $t0, inGame
	beq $t0, 0, endOfupdateFlappy
	#step2
	lw $t0, intervalFrame
	li $t1, 2
	div $t0, $t1
	mfhi $t0
	bne $t0, 0, step3OfupdateF
	#2.1
	lw $t0, direction
	bne $t0, 0, notZero
	lw $t1, velocity
	lw $t2, gravity
	add $t1, $t2, $t1
	sw $t1, velocity
	notZero: #2.2
	bne $t0, 1, notOne
	li $t0, -9
	sw $t0, velocity
	notOne:  #2.3
	la $t0, flappyBox
	lw $t1, 4($t0)
	lw $t2, velocity
	add $t1, $t1, $t2
	sw $t1, 4($t0)
	step3OfupdateF:
	la $t0, flappyBox
	lw $t1, 4($t0) 
	lw $t0, 12($t0) 
	add $t0, $t1, $t0
	lw $t2, SIZE
	la $t3, floorBox
	lw $t3, 12($t3)
	sub $t2, $t2, $t3
	bge $t0, $t2, endOfGameInUF
	blez $t1, endOfGameInUF
	j endOfupdateFlappy
	endOfGameInUF:
	sw $zero, won
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal handleGameEnd
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	#------ Your code ends here ------
endOfupdateFlappy:
    jr $ra


#--------------------------------------------------------------------
# task 1: check if two rectangles intersect
#--------------------------------------------------------------------
# $a0: rectangle1 address, $a1: rectangle2 address
# return value: $v0: 1 if intersects, 0 otherwise
intersects:
    #***** Task 1 *****
    # two rectangles intersect if the following condition is fulfilled:
    #            rectangle1.x < rectangle2.x + rectangle2.width
    #            && rectangle1.x + rectangle1.width > rectangle2.x
    #            && rectangle1.y < rectangle2.y + rectangle2.height
    #            && rectangle1.y + rectangle1.height > rectangle2.y
    #------ Your code starts here ------
    lw $t0, 0($a0) #rectangle1.x
    lw $t1, 0($a1) #rectangle2.x
    lw $t3, 8($a0) #rectangle1.w
    lw $t2, 8($a1) #rectangle2.w
    add $t4, $t2, $t1 # rectangle2.x + rectangle2.width
    bge $t0, $t4, ExitOfInt #rectangle1.x >= rectangle2.x + rectangle2.width
    add $t4, $t3, $t0
    ble $t4, $t1, ExitOfInt
    lw $t0, 4($a0) #rectangle1.y
    lw $t1, 4($a1) #rectangle2.y
    lw $t3, 12($a0) #rectangle1.h
    lw $t2, 12($a1) #rectangle2.h
    add $t4, $t2, $t1 
    bge $t0, $t4, ExitOfInt 
    add $t4, $t3, $t0
    ble $t4, $t1, ExitOfInt
    li $v0, 1 #Intersect
    j RealExitOfInt
ExitOfInt:
	li $v0, 0
RealExitOfInt:
	#------ Your code ends here ------
    jr $ra


#--------------------------------------------------------------------
# procedure
#--------------------------------------------------------------------
# $a0: obstacle address, $a1: newX
resetToNewPosition:

    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)

    # set newX
    add $s0, $a0, $zero # $s0: obstacle address
    sw $a1, 0($s0)
    sw $a1, 16($s0)

    # set random newY for topPipe: -(new Random().nextInt(280) + 200)
    addi $a1, $zero, 280
    addi $v0, $zero, 42
    syscall
    add $t0, $a0, $zero #t0: int[0, 280)
    addi $t0, $t0, 200
    sub $t0, $zero, $t0 #t0: topPipe.y
    sw $t0, 4($s0)

    # set newY for bottomPipe: topPipe.y + topPipe.height + obstacleDistance
    lw $t1, 12($s0) #t1: topPipe.height
    la $t2, obstacleDistance
    lw $t2, 0($t2) #t2: obstacleDistance
    add $t3, $t0, $t1 
    add $t3, $t3, $t2 #t3: bottomPipe.y
    sw $t3, 20($s0)

    # set isPassedOn to false
    sw $zero, 32($s0)

    # set topPipeType and bottomPipeType to random int in [0, 3)
    addi $a1, $zero, 3
    addi $v0, $zero, 42
    syscall
    sw $a0, 36($s0)
    addi $a1, $zero, 3
    addi $v0, $zero, 42
    syscall
    sw $a0, 40($s0)

endResetToNewPosition:
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra


#--------------------------------------------------------------------
# procedure
#--------------------------------------------------------------------
startPositionObs:

    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s2, 8($sp)
    sw $s1, 4($sp)
    sw $s0, 0($sp)

    la $t0, SIZE
    lw $s0, 0($t0) # $s0: SIZE

    # initialize positions of obstacles
    add $s1, $zero, $zero # $s1: loop index

    obsInitLoop:
        addi $t0, $zero, 4
        beq $s1, $t0, endStartPositionObs

        la $t0, obstacles
        addi $t1, $zero, 11
        mult $s1, $t1
        mflo $t1
        sll $t1, $t1, 2
        add $s2, $t0, $t1 # $s2: address of the obstacle[i]

        # initialize the width and height of the topPipe
        addi $t0, $zero, 104
        sw $t0, 8($s2) # topPipe.width
        sw $t0, 24($s2) # bottomPipe.width
        addi $t1, $zero, 540 
        sw $t1, 12($s2) # topPipe.height
        sw $t1, 28($s2) # bottomPipe.height

        # place the obstacle
        # newX: (SIZE + 104) + (i * 340)
        addi $t0, $zero, 340
        mult $s1, $t0
        mflo $t0
        addi $t1, $s0, 104
        add $t2, $t1, $t0 # $t2: newX
        add $a0, $s2, $zero
        add $a1, $t2, $zero
        jal resetToNewPosition

        obsInitLoopEnd:
        addi $s1, $s1, 1
        j obsInitLoop

endStartPositionObs:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra


#--------------------------------------------------------------------
# procedure
#--------------------------------------------------------------------
startPositionFlappy:

    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s1, 4($sp)
    sw $s0, 0($sp)

    la $t0, SIZE
    lw $s0, 0($t0) # $s0: SIZE
    la $s1, flappyBox # $s1: flappyBox
    # x = (SIZE / 2) - (width * 3), y = (SIZE / 2) - (height / 2)
    addi $t0, $zero, 2 # $t0: 2
    div $s0, $t0
    mflo $t1 # $t1: SIZE / 2
    lw $t2, 8($s1) # $t2: flappyBox.width
    add $t3, $t2, $t2 
    add $t3, $t3, $t2 # $t3: flappyBox.width * 3
    sub $t4, $t1, $t3 # $t4: x
    sw $t4, 0($s1)

    lw $t2, 12($s1) # $t2: flappyBox.height
    div $t2, $t0
    mflo $t3 # $t3: flappyBox.height / 2
    sub $t4, $t1, $t3 # $t4: y
    sw $t4, 4($s1)


endStartPositionFlappy:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra


#--------------------------------------------------------------------
# procedure
#--------------------------------------------------------------------
handleGameEnd:

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    la $t0, point
    sw $zero, 0($t0) # point = 0
    la $t0, objectVelocity
    addi $t1, $zero, 6
    sw $t1, 0($t0) # objectVelocity = 6
    la $t0, direction
    addi $t1, $zero, -1
    sw $t1, 0($t0) # direction = -1
    # reset GUI direction using syscall
    addi $v0, $zero, 304
    addi $a0, $zero, -1
    syscall
    la $t0, inGame
    sw $zero, 0($t0) # inGame = false
    la $t0, velocity
    sw $zero, 0($t0) # velocity = 0

    jal startPositionObs
    jal startPositionFlappy

endHandleGameEnd:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


endGame:

    addi $v0, $zero, 306
    syscall





