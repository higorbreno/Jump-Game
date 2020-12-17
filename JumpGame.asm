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
#       use a tecla espaço para pular (32 em ASCII)                  #       
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
	.eqv FLOOR_Y_POS 30 #Posição Y do chão
#Constantes do jogador
	.eqv PLAYER_X_POS 29 #Posição X do player
	.eqv PLAYER_WIDTH 5 #Largura do player
	.eqv PLAYER_HEIGHT 5 #Altura do player
	.eqv MAX_HEALTH 3 #Vida máxima do jogador
#Constantes do Inimigo
	.eqv ENEMY_Y_POS 32 #Posição Y do inimigo
	.eqv ENEMY_VELOCITY 25 #Velocidade de movimento do inimigo
	.eqv ENEMY_WIDTH 5 #Largura do inimigo
	.eqv ENEMY_HEIGHT 5  #Altura do inimigo
	
#Variáveis
	deltaTime: .double 0
	score: .word 0
#Variáveis do jogador
	health: .word 3
	playerYOldPos: .word 0
	playerYPos: .word 0
	playerVelocity: .word 1
#Variáveis do inimigo
	enemyXPos: .word 63
	
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
	sw $zero, deltaTime
	sw $zero, score
	#sw $zero, playerVelocity
	li $t0, MAX_HEALTH
	sw $t0, health
	li $t0, 1
	sw $t0, playerYPos
	li $t0, 1
	sw $t0, playerYPos
	li $t0, 255
	sw $t0, enemyXPos
	jr $ra
	
###################################################################################	

	update:
	#Função que roda o loop principal do jogo
	lw $t9, health
	beq $t9, $zero, fim #Se total de vidas for igual a zero, o jogo acaba
	li $v0, 32
	li $a0, 50
	syscall
	lw $t0, playerYPos
	lw $t1, playerVelocity
	add $t0, $t0, $t1
	sw $t0, playerYPos
	jal checkColisaoPlayerChao
	jal checkJump
	jal apagarPlayer
	lw $t0, playerYPos
	sw $t0, playerYOldPos
	jal desenharPlayer
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

	checkJump:
	lui $t0, 0xffff
	lw $t1, 0($t0)
	andi $t1, $t1, 0x0001
	bne $t1, $zero, jump
	jr $ra
	
###################################################################################

	jump:
	lw $s2, 4( $t0)
	li $t0, 1
	sw $t0, playerYPos
	sw $t0, playerVelocity
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
	
	


