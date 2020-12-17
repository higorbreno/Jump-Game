######################################################################
#      	                    Higor e Felipe                           #
######################################################################
#	Esse programa precisa que o Keyboard and Display MMIO        #
#       e o Bitmap Display estejam conectados ao MIPS.               #
#								     #
#       Configurações do Bitmap Display:                             #
#	Unit Width: 8						     #
#	Unit Height: 8						     #
#	Display Width: 512					     #
#	Display Height: 256					     #
#	Base Address for Display: 0x10008000 ($gp)	             #
#                                                                    #
#       Qualquer tela digitável como letras ou numeros pode 	     #
#	ser usada para pular		                  	     #  
#					                  	     #   
#	Ajustes como tamanho do personagem e do inimigo,       	     #
#	altura do chão, velocidade do inimigo, entre outras,         #   
#	podem ser modificados mudando os valores das constantes      #   
######################################################################

	.data
#Constantes 
	.eqv SCREEN_WIDTH 64 #Largura da tela
	.eqv SCREEN_HEIGHT 32 #Altura da tela
	.eqv SCORE_ADD_VALUE 100 #Valor de adição a pontuação
#Constantes de cores
	.eqv PRETO 0x000000
	.eqv BRANCO 0xFFFFFF
	.eqv CINZA 0xCDCDCD
	.eqv VERMELHO 0xFF0000
	.eqv VERDE 0x00FF00
	.eqv AZUL 0x0000FF
#Constantes do mundo
	.eqv GRAVITY 10 #Aceleração da gravidade
	.eqv FLOOR_Y_POS 25 #Posição Y do chão
#Constantes do jogador
	.eqv PLAYER_X_POS 29 #Posição X do player
	.eqv PLAYER_WIDTH 5 #Largura do player
	.eqv PLAYER_HEIGHT 5 #Altura do player
	.eqv MAX_JUMP_HEIGHT 10 #Altura máxima do pulo
	.eqv MAX_HEALTH 3 #Vida máxima do jogador
#Constantes do Inimigo
	.eqv ENEMY_VELOCITY 1 #Velocidade de movimento do inimigo
	.eqv ENEMY_WIDTH 4 #Largura do inimigo
	.eqv ENEMY_HEIGHT 3  #Altura do inimigo
	
#Variáveis
	jaContouPonto: .word 0
	score: .word 0
#Variáveis do jogador
	health: .word 3
	playerYOldPos: .word 0
	playerYPos: .word 0
	playerVelocity: .word 0
#Variáveis do inimigo
	enemyYPos: .word 0
	enemyXPos: .word 0
	enemyXOldPos: .word 0
	
	scoreStr: .asciiz "\nSua pontuação atual é de "
	healthStr: .asciiz "\nSua quantidade de vidas restantes é "
	
	.globl main

.text
	main: 
	#Pinta a tela de preto pra (re)iniciar
	li $a0, SCREEN_HEIGHT
	li $a1, SCREEN_WIDTH
	li $a2, PRETO
	mul $a3, $a0, $a1 
	mul $a3, $a3, 4 
	add $a3, $a3, $gp 
	add $a0, $gp, $zero 
	FillLoop:
		beq $a0, $a3, endFill
		sw $a2, 0($a0) #store color
		addiu $a0, $a0, 4 #increment counter
		j FillLoop
	endFill:
	li $a2, CINZA
	add $a0, $gp, $zero
	li $a0, 0
	li $a1, FLOOR_Y_POS
	jal coordenadaParaEndereco
	addi $a0, $v0, 0
	FloorLoop:
		beq $a0, $a3, inicio
		sw $a2, 0($a0)
		addiu $a0, $a0, 4
		j FloorLoop
		
###################################################################################	
	
	inicio:
	jal init
	
	#Limpa os registradores
	li $v0, 0
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 0
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0
	
	j update
	
###################################################################################	
	
	init:
	#Inicia os valores default nas variáveis
	sw $zero, score
	
	li $t0, MAX_HEALTH
	sw $t0, health
	li $t0, 1
	sw $t0, playerVelocity
	li $t0, SCREEN_WIDTH
	subi $t0, $t0, 1
	subi $t0, $t0, ENEMY_WIDTH
	sw $t0, enemyXPos
	sw $t0, enemyXOldPos
	
	li $t0, FLOOR_Y_POS
	li $t1, PLAYER_HEIGHT
	sub $t1, $t0, $t1
	sw $t1, playerYPos
	sw $t1, playerYOldPos
	li $t1, ENEMY_HEIGHT
	sub $t1, $t0, $t1
	sw $t1, enemyYPos
	jr $ra
	
###################################################################################	

	update:
	#Função que roda o loop principal do jogo
	lw $t9, health
	beq $t9, $zero, fim #Se total de vidas for igual a zero, o jogo acaba
	li $v0, 32
	li $a0, 50
	syscall
	
	jal checkColisaoPlayerInimigo
	lw $t0, playerYPos
	lw $t1, playerVelocity
	add $t0, $t0, $t1
	sw $t0, playerYPos
	
	lw $t0, enemyXPos
	li $t1, ENEMY_VELOCITY
	sub $t0, $t0, $t1
	sw $t0, enemyXPos
	jal checkScore
	jal checkColisaoPlayerChao
	jal checkAlturaMaxima
	jal checkJump
	jal checkInimigoXPos
	jal apagarPlayer
	jal apagarEnemy
	lw $t0, playerYPos
	sw $t0, playerYOldPos
	lw $t0, enemyXPos
	sw $t0, enemyXOldPos
	jal desenharPlayer
	jal desenharEnemy
	j update	
	
###################################################################################	

	desenharPlayer:
	#Função que desenha o player no local que ele estiver
	la $t0, 0($ra)
	
	li $t1, PLAYER_X_POS #Posição x do player
	lw $t2, playerYPos #Posição y do player
	
	addi $t3, $t1, PLAYER_WIDTH
	#addi $t3, $t3, 1 #Valor para checar se o loop de x deve acabar
	addi $t4, $t2, PLAYER_HEIGHT
	#addi $t4, $t4, 1 #Valor para checar se o loop de y deve acabar
	
	addi $t5, $t1, 0 #Contador para x
	addi $t6, $t2, 0 #Contador para y
	
	loop1Desenhar:
		loop2Desenhar:
			addi $a0, $t5, 0
			addi $a1, $t6, 0
			jal coordenadaParaEndereco
			li $a1, AZUL
			jal desenharPixel
			addi $t5, $t5, 1
		bne $t5, $t3, loop2Desenhar
		addi $t6, $t6, 1
		addi $t5, $t1, 0
	bne $t6, $t4, loop1Desenhar
	jr $t0
	
###################################################################################	

	apagarPlayer:
	#Função que desenha o player no local que ele estiver
	la $t0, 0($ra)
	
	li $t1, PLAYER_X_POS #Posição x do player
	lw $t2, playerYOldPos #Posição y do player
	
	addi $t3, $t1, PLAYER_WIDTH #Valor para checar se o loop de x deve acabar
	addi $t4, $t2, PLAYER_HEIGHT #Valor para checar se o loop de y deve acabar
	
	addi $t5, $t1, 0 #Contador para x
	addi $t6, $t2, 0 #Contador para y
	
	lw $t7, playerYPos
	beq $t7, $t2, fimApagar
	loop1Apagar:
		loop2Apagar:
			addi $a0, $t5, 0
			addi $a1, $t6, 0
			jal coordenadaParaEndereco
			li $a1, PRETO
			jal desenharPixel
			addi $t5, $t5, 1
		bne $t5, $t3, loop2Apagar
		addi $t6, $t6, 1
		addi $t5, $t1, 0
	bne $t6, $t4, loop1Apagar
	fimApagar:
	sw $t7, playerYOldPos
	jr $t0
	
###################################################################################	

	desenharEnemy:
	#Função que desenha o player no local que ele estiver
	la $t0, 0($ra)
	
	lw $t1, enemyXPos #Posição x do player
	lw $t2, enemyYPos #Posição y do player
	
	addi $t3, $t1, ENEMY_WIDTH #Valor para checar se o loop de x deve acabar
	addi $t4, $t2, ENEMY_HEIGHT #Valor para checar se o loop de y deve acabar
	
	addi $t5, $t1, 0 #Contador para x
	addi $t6, $t2, 0 #Contador para y
	
	loop1DesenharEnemy:
		loop2DesenharEnemy:
			addi $a0, $t5, 0
			addi $a1, $t6, 0
			jal coordenadaParaEndereco
			li $a1, VERMELHO
			jal desenharPixel
			addi $t5, $t5, 1
		bne $t5, $t3, loop2DesenharEnemy
		addi $t6, $t6, 1
		addi $t5, $t1, 0
	bne $t6, $t4, loop1DesenharEnemy
	jr $t0
	
###################################################################################	

	apagarEnemy:
	#Função que desenha o player no local que ele estiver
	la $t0, 0($ra)
	
	lw $t1, enemyXOldPos #Posição x do inimigo
	lw $t2, enemyYPos #Posição y do inimigo
	
	addi $t3, $t1, ENEMY_WIDTH #Valor para checar se o loop de x deve acabar
	addi $t4, $t2, ENEMY_HEIGHT #Valor para checar se o loop de y deve acabar
	
	addi $t5, $t1, 0 #Contador para x
	addi $t6, $t2, 0 #Contador para y
	
	lw $t7, enemyXPos
	beq $t7, $t2, fimApagarEnemy
	loop1ApagarEnemy:
		loop2ApagarEnemy:
			addi $a0, $t5, 0
			addi $a1, $t6, 0
			jal coordenadaParaEndereco
			li $a1, PRETO
			jal desenharPixel
			addi $t5, $t5, 1
		bne $t5, $t3, loop2ApagarEnemy
		addi $t6, $t6, 1
		addi $t5, $t1, 0
	bne $t6, $t4, loop1ApagarEnemy
	fimApagarEnemy:
	sw $t7, enemyXOldPos
	jr $t0
	
###################################################################################

	checkInimigoXPos:
	lw $t0, enemyXPos
	bgez $t0, fimCheckInimigoX
	li $t0, SCREEN_WIDTH
	subi $t0, $t0, 1
	subi $t0, $t0, ENEMY_WIDTH
	sw $t0, enemyXPos
	li $t0, 0
	sw $t0, jaContouPonto
	fimCheckInimigoX:
	jr $ra

###################################################################################

	checkJump:
	lui $t0, 0xffff
	lw $t1, 0($t0)
	andi $t1, $t1, 0x0001
	beq $t1, $zero, fimCheckJump
	li $t2, FLOOR_Y_POS
	lw $t1, playerYPos
	addi $t1, $t1, PLAYER_HEIGHT
	bge $t1, $t2, jump
	fimCheckJump:
	jr $ra
	
###################################################################################

	jump:
	lw $s2, 4( $t0)
	li $t0, -1
	sw $t0, playerVelocity
	jr $ra
	
###################################################################################

	checkAlturaMaxima:
	lw $t0, playerYPos
	li $t1, MAX_JUMP_HEIGHT
	bge $t0, $t1, fimCheckAltura
	li $t0, 1
	sw $t0, playerVelocity
	fimCheckAltura:
	jr $ra
	
###################################################################################	
	
	checkColisaoPlayerChao:
	#Checa a colisão do player com o chão e zera a velocidade caso estejam se tocando
	li $t0, FLOOR_Y_POS
	lw $t1, playerYPos
	addi $t1, $t1, PLAYER_HEIGHT
	ble $t0, $t1, zerarVeloc
	jr $ra
	
###################################################################################	
	
	zerarVeloc:
	#Zera a velocidade do player
	sw $zero, playerVelocity
	subi $t1, $t0, PLAYER_HEIGHT
	sw $t1, playerYPos
	jr $ra
	
###################################################################################	

	checkColisaoPlayerInimigo:
	lw $t0, playerYPos
	li $t1, PLAYER_X_POS
	lw $t2, enemyYPos
	lw $t3, enemyXPos
	
	addi $t4, $t0, PLAYER_HEIGHT
	bgt $t2, $t4, fimCheckColisaoPI
	addi $t4, $t2, ENEMY_HEIGHT
	bgt $t0, $t4, fimCheckColisaoPI
	addi $t4, $t1, PLAYER_WIDTH
	bgt $t3, $t4, fimCheckColisaoPI
	addi $t4, $t3, ENEMY_HEIGHT
	bgt $t1, $t4, fimCheckColisaoPI
	lw $t5, health
	subi $t5, $t5, 1
	sw $t5, health
	li $v0, 4
	la $a0, healthStr
	syscall
	li $v0, 1
	lw $a0, health
	syscall
	
	li $t3, SCREEN_WIDTH
	subi $t3, $t3, 1
	subi $t3, $t3, ENEMY_WIDTH
	sw $t3, enemyXPos
		
	fimCheckColisaoPI:
	jr $ra
	
###################################################################################	

	checkScore:
	lw $t0, jaContouPonto
	bnez $t0, fimCheckScore
	
	lw $t0, enemyXPos
	addi $t0, $t0, ENEMY_WIDTH
	li $t1, PLAYER_X_POS
	bge $t0, $t1, fimCheckScore
	
	li $t0, 1
	sw $t0, jaContouPonto
	lw $t0, score
	addi $t0, $t0, SCORE_ADD_VALUE
	sw $t0, score
	li $v0, 4
	la $a0, scoreStr
	syscall
	li $v0, 1
	lw $a0, score
	syscall
	fimCheckScore:
	jr $ra

###################################################################################
	
	coordenadaParaEndereco: 
	#Retorna o endereço do pixel nas coordenadas guardadas em $a0(x) e $a1(y) em $v0
	li $v0, SCREEN_WIDTH	
	mul $v0, $v0, $a1	
	add $v0, $v0, $a0	
	mul $v0, $v0, 4		
	add $v0, $v0, $gp	
	jr $ra	
	
###################################################################################	
	
	desenharPixel:
	#Desenha o pixel no endereço guardado em $v0 na cor guardada em $a1
	sw $a1, 0($v0)
	jr $ra
	
###################################################################################	
		
	fim:
	li $v0, 10
	syscall
	
	


