
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
#					                  	     #   
#	Pontuação e quantidade de vidas restantes são mostradas      #  
#	no console do mars		                  	     #       
######################################################################

	.data
#Constantes 
	.eqv SCREEN_WIDTH 128 #Largura da tela
	.eqv SCREEN_HEIGHT 64 #Altura da tela
	.eqv SCORE_ADD_VALUE 100 #Valor de adição a pontuação
#Constantes de cores
	.eqv PRETO 0x000000
	.eqv BRANCO 0xFFFFFF
	.eqv CINZA 0x4F4F4F
	.eqv VERMELHO 0xFF0000
	.eqv VERDE 0x00FF00
	.eqv AZUL 0x0000FF
	.eqv CREME 0xFF9933
	.eqv MARROM 0x9A6700
#Constantes do mundo
	.eqv GRAVITY 10 #Aceleração da gravidade
	.eqv FLOOR_Y_POS 61 #Posição Y do chão
#Constantes do jogador
	.eqv PLAYER_X_POS 30 #Posição X do player
	.eqv PLAYER_WIDTH 9 #Largura do player
	.eqv PLAYER_HEIGHT 23 #Altura do player
	.eqv MAX_JUMP_HEIGHT 10 #Altura máxima do pulo
	.eqv MAX_HEALTH 3 #Vida máxima do jogador
#Constantes do Inimigo
	.eqv ENEMY_VELOCITY 3 #Velocidade de movimento do inimigo
	.eqv ENEMY_WIDTH 4 #Largura do inimigo
	.eqv ENEMY_HEIGHT 1  #Altura do inimigo
	.eqv ENEMY_BASE_Y_POS 10
	
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
	reiniciarStr: .asciiz "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
	
	.globl main

.text
	main: 
	#Pinta a tela de preto pra (re)iniciar
	li $a0, SCREEN_HEIGHT
	li $a1, SCREEN_WIDTH
	li $a2, BRANCO
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
	li $a2, PRETO
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
	li $t0, 20
	sw $t0, playerVelocity
	li $t0, SCREEN_WIDTH
	subi $t0, $t0, 1
	subi $t0, $t0, ENEMY_WIDTH
	sw $t0, enemyXPos
	sw $t0, enemyXOldPos
	
	li $t0, FLOOR_Y_POS
	li $t1, PLAYER_HEIGHT
	sub $t1, $t0, $t1
	#li $t1, 0
	sw $t1, playerYPos
	sw $t1, playerYOldPos
	li $t1, ENEMY_HEIGHT
	sub $t1, $t0, $t1
	subi $t1, $t1, 10
	sw $t1, enemyYPos
	jr $ra
	
###################################################################################	

	update:
	#Função que roda o loop principal do jogo
	lw $t9, health
	beq $t9, $zero, reiniciar #Se total de vidas for igual a zero, o jogo acaba
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
	la $t5, 0($ra)
	
	li $a0, PLAYER_X_POS #Posição x do player
	lw $a1, playerYPos #Posição y do player
	
	
	li $20, MARROM
	li $21, PRETO
	li $22, CINZA
	li $23, BRANCO 
	li $24, CREME
	
	jal coordenadaParaEnderecoPlayer

	move $10, $v0
	#addi $v0, $gp, 0
	jal bitmapPers
	
	jr $t5
	
###################################################################################	

	apagarPlayer:
	#Função que desenha o player no local que ele estiver
	la $t5, 0($ra)
	
	li $a0, PLAYER_X_POS #Posição x do player
	lw $a1, playerYOldPos #Posição y do player
	
	li $20, BRANCO
	li $21, BRANCO
	li $22, BRANCO
	li $23, BRANCO 
	li $24, BRANCO
	
	jal coordenadaParaEnderecoPlayer

	move $10, $v0
	#addi $v0, $gp, 0
	jal bitmapPers
	
	sw $t7, playerYOldPos
	jr $t5
	
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
			li $a1, CINZA
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
			li $a1, BRANCO
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
	li $t0, FLOOR_Y_POS
	li $t1, ENEMY_HEIGHT
	sub $t1, $t0, $t1
	subi $t1, $t1, 3
	li $v0, 42
	li $a0, 551526184
	li $a1, 14
	syscall
	li $t0, 7
	blt $a0, $t0, subtrair
	li $v0, 42
	li $a0, 1656512
	li $a1, 10
	syscall
	subi $t1, $t1, 20
	subtrair:
	sub $t1, $t1, $a0
	sw $t1, enemyYPos
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
	li $t0, -3
	sw $t0, playerVelocity
	jr $ra
	
###################################################################################

	checkAlturaMaxima:
	lw $t0, playerYPos
	li $t1, MAX_JUMP_HEIGHT
	bge $t0, $t1, fimCheckAltura
	li $t0, 3
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
	addi $t4, $t3, ENEMY_WIDTH
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

	coordenadaParaEnderecoPlayer:
	subi $a0, $a0, 36
	sll $a0, $a0, 2
	li $t0, SCREEN_WIDTH
	#li $t1, SCREEN_HEIGHT
	#sub $t1, $t1, $a1
	mul $a1, $t0, $a1
	mul $a1, $a1, 4
	li $t0, PLAYER_HEIGHT
	li $t1, FLOOR_Y_POS
	sub $t1, $t1, $t0
	mul $t1, $t1, 4
	li $t0, SCREEN_WIDTH
	mul $t1, $t1, $t0
	
	
	add $v0, $gp, $a0
	add $v0, $v0, $a1
	sub $v0, $v0, $t1
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

	#bitmap dos objetos
	bitmapPers:	
	#linha 1
sw $23, 19572($10)	
sw $23, 19576($10)	
sw $23, 19580($10)	
sw $23, 19584($10)	
sw $21, 19588($10)	
sw $21, 19592($10)	
sw $21, 19596($10)	
sw $21, 19600($10)	
sw $21, 19604($10)	
sw $21, 19608($10)	
sw $21, 19612($10)	
sw $21, 19616($10)	
sw $23, 19620($10)	
sw $23, 19624($10)	
sw $23, 19628($10)	
sw $23, 19632($10)	
sw $23, 19636($10)	
sw $23, 19640($10)	
	#linha 2
sw $23, 20084($10)	
sw $23, 20088($10)	
sw $23, 20092($10)	
sw $23, 20096($10)	
sw $21, 20100($10)	
sw $20, 20104($10)	
sw $20, 20108($10)	
sw $20, 20112($10)	
sw $20, 20116($10)	
sw $20, 20120($10)	
sw $20, 20124($10)	
sw $20, 20128($10)	
sw $21, 20132($10)	
sw $23, 20136($10)	
sw $23, 20140($10)	
sw $23, 20144($10)	
sw $23, 20148($10)	
sw $23, 20152($10)
	#linha 3
sw $23, 20596($10)
sw $23, 20600($10)
sw $23, 20604($10)
sw $23, 20608($10)
sw $21, 20612($10)
sw $20, 20616($10)
sw $20, 20620($10)
sw $20, 20624($10)
sw $20, 20628($10)
sw $20, 20632($10)
sw $20, 20636($10)
sw $20, 20640($10)
sw $21, 20644($10)
sw $23, 20648($10)
sw $23, 20652($10)
sw $23, 20656($10)
sw $23, 20660($10)
sw $23, 20664($10)
	#linha 4
sw $23, 21108($10)
sw $23, 21112($10)
sw $23, 21116($10)
sw $23, 21120($10)
sw $21, 21124($10)
sw $20, 21128($10)
sw $20, 21132($10)
sw $20, 21136($10)
sw $20, 21140($10)
sw $20, 21144($10)
sw $20, 21148($10)
sw $20, 21152($10)
sw $20, 21156($10)
sw $21, 21160($10)
sw $23, 21164($10)
sw $23, 21168($10)
sw $23, 21172($10)
sw $23, 21176($10)	
	#linha 5
sw $23, 21620($10)
sw $21, 21624($10)
sw $21, 21628($10)
sw $21, 21632($10)
sw $21, 21636($10)
sw $22, 21640($10)
sw $22, 21644($10)
sw $22, 21648($10)
sw $22, 21652($10)
sw $22, 21656($10)
sw $22, 21660($10)
sw $22, 21664($10)
sw $22, 21668($10)
sw $21, 21672($10)
sw $21, 21676($10)
sw $21, 21680($10)
sw $21, 21684($10)
sw $23, 21688($10)
	#linha 6
sw $21, 22132($10)
sw $20, 22136($10)
sw $20, 22140($10)
sw $20, 22144($10)
sw $20, 22148($10)
sw $20, 22152($10)
sw $20, 22156($10)
sw $20, 22160($10)
sw $20, 22164($10)
sw $20, 22168($10)
sw $20, 22172($10)
sw $20, 22176($10)
sw $20, 22180($10)
sw $20, 22184($10)
sw $20, 22188($10)
sw $20, 22192($10)
sw $20, 22196($10)
sw $21, 22200($10)
	#linha 7
sw $21, 22644($10)
sw $21, 22648($10)
sw $21, 22652($10)
sw $21, 22656($10)
sw $21, 22660($10)
sw $21, 22664($10)
sw $21, 22668($10)
sw $21, 22672($10)
sw $21, 22676($10)
sw $21, 22680($10)
sw $21, 22684($10)
sw $21, 22688($10)
sw $21, 22692($10)
sw $21, 22696($10)
sw $21, 22700($10)
sw $21, 22704($10)
sw $21, 22708($10)
sw $21, 22712($10)
	#linha 8
sw $23, 23156($10)
sw $23, 23160($10)
sw $23, 23164($10)
sw $21, 23168($10)
sw $20, 23172($10)
sw $20, 23176($10)
sw $20, 23180($10)
sw $24, 23184($10)
sw $24, 23188($10)
sw $20, 23192($10)
sw $20, 23196($10)
sw $20, 23200($10)
sw $20, 23204($10)
sw $20, 23208($10)
sw $21, 23212($10)
sw $23, 23216($10)
sw $23, 23220($10)
sw $23, 23224($10)
	#linha 9
sw $23, 23668($10)
sw $23, 23672($10)
sw $23, 23676($10)
sw $21, 23680($10)
sw $20, 23684($10)
sw $20, 23688($10)
sw $24, 23692($10)
sw $24, 23696($10)
sw $24, 23700($10)
sw $24, 23704($10)
sw $24, 23708($10)
sw $24, 23712($10)
sw $24, 23716($10)
sw $20, 23720($10)
sw $21, 23724($10)
sw $23, 23728($10)
sw $23, 23732($10)
sw $23, 23736($10)
	#linha 10
sw $23, 24180($10)
sw $23, 24184($10)
sw $21, 24188($10)
sw $24, 24192($10)
sw $20, 24196($10)
sw $24, 24200($10)
sw $24, 24204($10)
sw $21, 24208($10)
sw $24, 24212($10)
sw $24, 24216($10)
sw $24, 24220($10)
sw $21, 24224($10)
sw $24, 24228($10)
sw $24, 24232($10)
sw $24, 24236($10)
sw $23, 24240($10)
sw $23, 24244($10)
sw $23, 24248($10)
	#linha 11
sw $23, 24692($10)
sw $23, 24696($10)
sw $21, 24700($10)
sw $24, 24704($10)
sw $24, 24708($10)
sw $24, 24712($10)
sw $24, 24716($10)
sw $24, 24720($10)
sw $22, 24724($10)
sw $22, 24728($10)
sw $22, 24732($10)
sw $24, 24736($10)
sw $24, 24740($10)
sw $24, 24744($10)
sw $21, 24748($10)
sw $23, 24752($10)
sw $23, 24756($10)
sw $23, 24760($10)
	#linha 12
sw $23, 25204($10)
sw $23, 25208($10)
sw $23, 25212($10)
sw $21, 25216($10)
sw $22, 25220($10)
sw $24, 25224($10)
sw $24, 25228($10)
sw $22, 25232($10)
sw $21, 25236($10)
sw $21, 25240($10)
sw $21, 25244($10)
sw $22, 25248($10)
sw $24, 25252($10)
sw $24, 25256($10)
sw $21, 25260($10)
sw $23, 25264($10)
sw $23, 25268($10)
sw $23, 25272($10)
	#linha 13
sw $23, 25716($10)
sw $23, 25720($10)
sw $23, 25724($10)
sw $21, 25728($10)
sw $22, 25732($10)
sw $22, 25736($10)
sw $24, 25740($10)
sw $22, 25744($10)
sw $24, 25748($10)
sw $24, 25752($10)
sw $24, 25756($10)
sw $22, 25760($10)
sw $24, 25764($10)
sw $22, 25768($10)
sw $21, 25772($10)
sw $23, 25776($10)
sw $23, 25780($10)
sw $23, 25784($10)
	#linha 14
sw $23, 26228($10)
sw $23, 26232($10)
sw $23, 26236($10)
sw $21, 26240($10)
sw $21, 26244($10)
sw $22, 26248($10)
sw $22, 26252($10)
sw $22, 26256($10)
sw $22, 26260($10)
sw $22, 26264($10)
sw $22, 26268($10)
sw $22, 26272($10)
sw $22, 26276($10)
sw $21, 26280($10)
sw $21, 26284($10)
sw $23, 26288($10)
sw $23, 26292($10)
sw $23, 26296($10)
	#linha 15
sw $23, 26740($10)
sw $23, 26744($10)
sw $23, 26748($10)
sw $23, 26752($10)
sw $23, 26756($10)
sw $21, 26760($10)
sw $21, 26764($10)
sw $21, 26768($10)
sw $21, 26772($10)
sw $21, 26776($10)
sw $21, 26780($10)
sw $21, 26784($10)
sw $21, 26788($10)
sw $23, 26792($10)
sw $23, 26796($10)
sw $23, 26800($10)
sw $23, 26804($10)
sw $23, 26808($10)
	#linha 16
sw $23, 27252($10)
sw $23, 27256($10)
sw $23, 27260($10)
sw $23, 27264($10)
sw $21, 27268($10)
sw $20, 27272($10)
sw $20, 27276($10)
sw $20, 27280($10)
sw $23, 27284($10)
sw $24, 27288($10)
sw $23, 27292($10)
sw $21, 27296($10)
sw $21, 27300($10)
sw $21, 27304($10)
sw $23, 27308($10)
sw $23, 27312($10)
sw $23, 27316($10)
sw $23, 27320($10)
	#linha 17
sw $23, 27764($10)
sw $23, 27768($10)
sw $23, 27772($10)
sw $21, 27776($10)
sw $20, 27780($10)
sw $21, 27784($10)
sw $20, 27788($10)
sw $20, 27792($10)
sw $23, 27796($10)
sw $23, 27800($10)
sw $20, 27804($10)
sw $20, 27808($10)
sw $21, 27812($10)
sw $20, 27816($10)
sw $21, 27820($10)
sw $23, 27824($10)
sw $23, 27828($10)
sw $23, 27832($10)
	#linha 18
sw $23, 28276($10)
sw $23, 28280($10)
sw $23, 28284($10)
sw $21, 28288($10)
sw $20, 28292($10)
sw $21, 28296($10)
sw $20, 28300($10)
sw $20, 28304($10)
sw $23, 28308($10)
sw $20, 28312($10)
sw $23, 28316($10)
sw $20, 28320($10)
sw $21, 28324($10)
sw $20, 28328($10)
sw $21, 28332($10)
sw $23, 28336($10)
sw $23, 28340($10)
sw $23, 28344($10)
	#linha 19
sw $23, 28788($10)
sw $23, 28792($10)
sw $23, 28796($10)
sw $21, 28800($10)
sw $24, 28804($10)
sw $21, 28808($10)
sw $20, 28812($10)
sw $20, 28816($10)
sw $20, 28820($10)
sw $23, 28824($10)
sw $23, 28828($10)
sw $20, 28832($10)
sw $21, 28836($10)
sw $24, 28840($10)
sw $21, 28844($10)
sw $23, 28848($10)
sw $23, 28852($10)
sw $23, 28856($10)
	#linha 20
sw $23, 29300($10)
sw $23, 29304($10)
sw $23, 29308($10)
sw $23, 29312($10)
sw $21, 29316($10)
sw $22, 29320($10)
sw $22, 29324($10)
sw $22, 29328($10)
sw $22, 29332($10)
sw $22, 29336($10)
sw $22, 29340($10)
sw $20, 29344($10)
sw $21, 29348($10)
sw $21, 29352($10)
sw $23, 29356($10)
sw $23, 29360($10)
sw $23, 29364($10)
sw $23, 29368($10)
	#linha 21
sw $23, 29812($10)
sw $23, 29816($10)
sw $23, 29820($10)
sw $23, 29824($10)
sw $21, 29828($10)
sw $22, 29832($10)
sw $22, 29836($10)
sw $22, 29840($10)
sw $22, 29844($10)
sw $22, 29848($10)
sw $22, 29852($10)
sw $22, 29856($10)
sw $21, 29860($10)
sw $23, 29864($10)
sw $23, 29868($10)
sw $23, 29872($10)
sw $23, 29876($10)
sw $23, 29880($10)
	#linha 22
sw $23, 30324($10)
sw $23, 30328($10)
sw $23, 30332($10)
sw $23, 30336($10)
sw $23, 30340($10)
sw $21, 30344($10)
sw $22, 30348($10)
sw $22, 30352($10)
sw $21, 30356($10)
sw $21, 30360($10)
sw $22, 30364($10)
sw $22, 30368($10)
sw $21, 30372($10)
sw $23, 30376($10)
sw $23, 30380($10)
sw $23, 30384($10)
sw $23, 30388($10)
sw $23, 30392($10)
	#linha 23
sw $23, 30836($10)
sw $23, 30840($10)
sw $23, 30844($10)
sw $23, 30848($10)
sw $23, 30852($10)
sw $21, 30856($10)
sw $21, 30860($10)
sw $21, 30864($10)
sw $23, 30868($10)
sw $23, 30872($10)
sw $21, 30876($10)
sw $21, 30880($10)
sw $21, 30884($10)
sw $23, 30888($10)
sw $23, 30892($10)
sw $23, 30896($10)
sw $23, 30900($10)
sw $23, 30904($10)
	jr $31
		
###################################################################################

	reiniciar:
	jal apagarPlayer
	jal apagarEnemy
	li $v0, 32
	li $a0, 2000
	syscall
	li $v0, 4
	la $a0, reiniciarStr
	syscall
	j main

###################################################################################
						
	fim:
	li $v0, 10
	syscall
	
	


