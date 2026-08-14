	#+ BITTE NICHT MODIFIZIEREN: Vorgabeabschnitt
	#+ ------------------------------------------

.data

str_text: .asciiz "Text: "
str_rueckgabewert: .asciiz "\nRueckgabewert: "

.text

.eqv SYS_PUTSTR 4
.eqv SYS_PUTCHAR 11
.eqv SYS_PUTINT 1
.eqv SYS_EXIT 10

main:
	# Eingabe text wird ausgegeben:
	li $v0, SYS_PUTSTR
	la $a0, str_text
	syscall

	li $v0, SYS_PUTSTR
	la $a0, test_text
	syscall

	li $v0, SYS_PUTSTR
	la $a0, str_rueckgabewert
	syscall

	move $v0, $zero
	# Aufruf der Funktion bloom_evaluate:
	la $a0, test_text
	la $a1, test_bitmatrix
	la $a2, test_amt
	lw $a2, 0($a2)
	jal bloom_evaluate

	# Rueckgabewert wird ausgegeben:
	move $a0, $v0
	li $v0, SYS_PUTINT
	syscall

	# Ende der Programmausfuehrung:
	li $v0, SYS_EXIT
	syscall

	# Hilfsfunktion: int hash(char* text, int len, int seed)
hash:
	move $v0, $a2 #Seed = 0++ in v0
	li $t0, 3
	
_hash_outer_loop:

	ble $t0, $zero, _hash_outer_loop_end
	li $t1, 0
	
_hash_inner_loop:

	bge $t1, $a1, _hash_inner_loop_end

	li $t2, 31
	mult $v0, $t2
	mflo $v0
	add $t2, $a0, $t1
	lbu $t3, 0($t2)
	add $v0, $v0, $t3
	sll $t2, $v0, 15
	srl $t3, $v0, 17
	or $v0, $t2, $t3

	addi $t1, $t1, 1
	j _hash_inner_loop
	
_hash_inner_loop_end:
	addi $t0, $t0, -1
	j _hash_outer_loop
	
_hash_outer_loop_end:
	jr $ra

.data

test_amt: .word 5 #$a2 amt, Anzahl Wiederholungen für Hashaufruf

test_bitmatrix: #$a1 Bitmatrix, 5*32 Bit gespeichert als Int-Vektor mit 5 Werte (160 Bits)
	.word 0x05004400
	.word 0x31400040
	.word 0x22310020
	.word 0x10509510
	.word 0x20104110

test_text: .asciiz "Apfel" #$a0 Text-Pointer auf einzelne Char-Werte des Strings (Adresse)

###########################################################

.text

bloom_evaluate:

	#Stack nutzen um Variablen vor nested function zu sichern (Aufruf der Hash-Funktion später)
	subu $sp, $sp, 24 #Platz für 24 Bytes / 6 Wörter reservieren
	sw $ra, 0($sp) #return adress speichern, da durch die nested function dieser später überschrieben wird
	sw $s0, 4($sp) #len (Länge des Strings)
	sw $s1, 8($sp) #Bitmatrix Pointer
	sw $s2, 12($sp) #text Pointer (Adressen der Char-Werte des Strings)
	sw $s3, 16($sp) #amt (Anzahl der Hash-Funktionsaufrufe)
	sw $s4, 20($sp) #i 

	#Argumentvariablen der bloom_evaluate Funktion auf $s Register sichern, da die Hash-function später die Argumente überschreibt (Registerkonvention)
	move $s1, $a1 #Bitmatrix Pointer ($a1) auf $s1 sichern
	move $s2, $a0 #text Pointer ($a0) auf $s2 sichern
	move $s3, $a2 #amt ($a2) auf $s3 sichern 

	#Länge des Strings berechnen (Variable len bestimmen)
	li $s0, 0 #$s0 = len
	move $t0, $s2 #t0 speichert (temporär) Text-Pointer Adresse, die Basisadresse soll nach der Längenberechnung bestehen bleiben
  
  		#while-Schleife für Berechnung von len -> Addition mit 1 so lange der NULL-Wert nicht erreicht wird
		while:
		
		lb $t1, 0($t0) #Char-Werte aus den Adressen laden (Byte-adressiert)
		beq $t1, $zero, exit_while #Char-Wert = NULL -> Ende des Strings in C, springt zu exit_while, Ende der Schleife
		
		addi $s0, $s0, 1 #len++
		addi $t0, $t0, 1 #Adresse++
		
		j while #while-Schleife wird wiederholt
	
		exit_while: #NULL-Wert erreicht -> Code wird fortgesetzt

	#For-Loop
	li $s4, 0 #i = 0

	for_hash:

	bge $s4, $s3, return_true #Abbruchterm, wenn $s4 (i) >= $s3 (amt) ist

	#Befüllen der $a Register mit Argumentvariablen (char*, len, seed) für Hash-Funktionsaufruf 
	move $a0, $s2 #Basisadresse des Strings
	move $a1, $s0 #len
	move $a2, $s4 #seed (ab 0)
	
	#Funktionsaufruf hash
	jal hash #Ergebnis (Hashvalue) in $v0
	
	#Zeilenposition (0,1,2,3,4) der Bitmatrix berechnen row = hashvalue % 5
	li $t0, 5 #5 in $t0 temporär sichern
    	divu $v0, $t0 #Hashvalue % 5 berechnen mit Modulo Konvention nach Aufgabe
   	mfhi $t1
   	#in $t1 steht nun "Zeilenzahl" (n-tes Int)

    	#Spaltenposition (0-31) der Bitmatrix berechnen col = hashvalue % 32
    	li $t0, 32 #In $t0 nun 32 laden -> 5 überschrieben
    	divu $v0, $t0 #Hashvalue % 32
    	mfhi $t2 
    	#in $t2 steht nun "Spaltenzahl"


	#Abfrage der Bitmatrix
	mul $t3, $t1, 4 #Spaltenzahl * 4 rechnen, da die "Zeilen" eigentlich nur eine der 5 integer sind, die Word-adressiert sind (32 Bit)
    	add $t3, $s1, $t3 #$Basisadresse des Bitmatrix-Pointer + integerzahl zu $t3 
    	lw $t4, 0($t3) #int aus der Adresse von $t3 laden

	li $t5, 1
    	sllv $t5, $t5, $t2 #1 in $t5 wird um col-Stellen nach links verschoben um eine Bitmaske zu erstellen
    	and $t6, $t4, $t5  #Bitmaske und das geladene int in $t4 werden Stellenweise mit AND verglichen -> Nur wenn beide 1 sind ergibt es 1
    
    	beq $t6, $zero, return_false #Wenn Zahl in $t6 = 0 ist -> springe zu return_false (Element nicht vorhanden, eine Null reicht bereits)

    	addi $s4, $s4, 1 #i++
    	
    	j for_hash #For-Schleife wird wieder wiederholt

		return_false:

    		li $v0, 0 #in $v0 wird 0 als FALSE geladen (Element nicht vorhanden)
   		 j wiederherstellung

		return_true:

    		li $v0, 1 #in $v0 wird 1 als TRUE geladen (Element möglicherwiese vorhanden)
   	 	j wiederherstellung

wiederherstellung:

   	 #Alle gesicherten Register wiederherstellen und Stack wieder freigeben (Registerkonvention)

  	lw $ra, 0($sp) #Damit bloom_evaluate beendet werden kann
  	lw $s0, 4($sp)
  	lw $s1, 8($sp)
  	lw $s2, 12($sp)
 	lw $s3, 16($sp)
 	lw $s4, 20($sp)
 	addi $sp, $sp, 24 #24 Bit zu Stack addieren
    	
    	jr $ra #Ende des Codes -> return adress
