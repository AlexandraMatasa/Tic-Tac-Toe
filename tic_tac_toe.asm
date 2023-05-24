.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "TIC-TAC-TOE",0
area_width EQU 640
area_height EQU 480
area DD 0

colorare_fundal_var DD 0
mat DD 35 dup(-1)

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

;variabila care decide daca trebuie sa puem X sau O
pune_x_sau_O DD 1 ;o intializam cu 1 pt ca punem X prima data

;format pt afisare edx
format db "%d", 13, 10,0

;varibila pt oprire dupa gasire castigator
castigator_gasit DD 0

;declaram coordonatele celor 9 casute(butoane) din tabla de joc
button_size EQU 60

buton1_x EQU 200
buton1_y EQU 100

buton2_x EQU 260
buton2_y EQU 100

buton3_x EQU 320
buton3_y EQU 100

buton4_x EQU 200
buton4_y EQU 160

buton5_x EQU 260
buton5_y EQU 160

buton6_x EQU 320
buton6_y EQU 160

buton7_x EQU 200
buton7_y EQU 220

buton8_x EQU 260
buton8_y EQU 220

buton9_x EQU 320
buton9_y EQU 220

;declaram coordonatele butonului de PLAY AGAIN
buton_play_again_x EQU 460
buton_play_again_y EQU 310
buton_play_again_size EQU 70

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0e4f4fch
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm


linie_orizontala macro x, y, len, color
local bucla_line
	pusha
	mov eax, y ;EAX = y
	mov ebx, area_width
	mul ebx ;EAX = y * area_width
	add eax, x; EAX = y * area_width + x
	shl eax, 2; EAX = (y * area_width + x)*4
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, 4 ;ne deplasam la dreapta cu o pozitie
	loop bucla_line
	popa
endm

linie_verticala macro x, y, len, color
local bucla_line
	pusha
	mov eax, y ;EAX = y
	mov ebx, area_width
	mul ebx ;EAX = y * area_width
	add eax, x; EAX = y * area_width + x
	shl eax, 2; EAX = (y * area_width + x)*4
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, 4*area_width ;ne deplasam in jos, adica cu o linie
	loop bucla_line
	popa
endm

desenare_buton macro x, y, len, color
	pusha
	linie_orizontala x, y, len, color
	linie_orizontala x, y + len, len, color
	linie_verticala x, y, len, color
	linie_verticala x + len, y, len, color
	popa
endm

desenare_matrice macro buton1_x, buton1_y, buton2_x, buton2_y, buton3_x, buton3_y, buton4_x, buton4_y, buton5_x, buton5_y, buton6_x, buton6_y, buton7_x, buton7_y, buton8_x, buton8_y, buton9_x, buton9_y
	pusha
	desenare_buton buton1_x, buton1_y, button_size, 0
	desenare_buton buton2_x, buton2_y, button_size, 0
	desenare_buton buton3_x, buton3_y, button_size, 0
	desenare_buton buton4_x, buton4_y, button_size, 0
	desenare_buton buton5_x, buton5_y, button_size, 0
	desenare_buton buton6_x, buton6_y, button_size, 0
	desenare_buton buton7_x, buton7_y, button_size, 0
	desenare_buton buton8_x, buton8_y, button_size, 0
	desenare_buton buton9_x, buton9_y, button_size, 0
	popa
endm


verif_click_buton_1 macro buton_x, buton_y, buton_dim, pos_x, pos_y
local pune_mat_1, final
	pusha
	mov eax, pos_x
	cmp eax, buton_x ;latura din stanga
	jl button_fail_1
	cmp eax, buton_dim + buton_x ;latura din dreapta
	jg button_fail_1
	
	mov eax, pos_y
	cmp eax, buton_y
	jl button_fail_1
	cmp eax, buton_dim + buton_y
	jg button_fail_1
	
	cmp mat[0], -1
	;verificam daca pozitia nu e deja ocupata
	jne button_fail_1
	cmp pune_x_sau_O, 0
	jne pune_mat_1
	mov mat[0], 0
	jmp final

	pune_mat_1:
	mov mat[0],1
	final:
	popa
endm

verif_click_buton_2 macro buton_x, buton_y, buton_dim, pos_x, pos_y
local pune_mat_1, final
	pusha
	mov eax, pos_x
	cmp eax, buton_x ;latura din stanga
	jl button_fail_2
	cmp eax, buton_dim + buton_x ;latura din dreapta
	jg button_fail_2
	
	mov eax, pos_y
	cmp eax, buton_y
	jl button_fail_2
	cmp eax, buton_dim + buton_y
	jg button_fail_2
	
	cmp mat[4], -1
	jne button_fail_2
	cmp pune_x_sau_O, 0
	jne pune_mat_1
	mov mat[4], 0
	jmp final

	pune_mat_1:
	mov mat[4],1
	final:
	popa
endm

verif_click_buton_3 macro buton_x, buton_y, buton_dim, pos_x, pos_y
	local pune_mat_1, final
	pusha
	mov eax, pos_x
	cmp eax, buton_x ;latura din stanga
	jl button_fail_3
	cmp eax, buton_dim + buton_x ;latura din dreapta
	jg button_fail_2
	
	mov eax, pos_y
	cmp eax, buton_y
	jl button_fail_3
	cmp eax, buton_dim + buton_y
	jg button_fail_3
	
	cmp mat[8], -1
	jne button_fail_3
	cmp pune_x_sau_O, 0
	jne pune_mat_1
	mov mat[8], 0
	jmp final
	
	pune_mat_1:
	mov mat[8],1
	final:
	popa
endm

verif_click_buton_4 macro buton_x, buton_y, buton_dim, pos_x, pos_y
	local pune_mat_1, final
	pusha
	mov eax, pos_x
	cmp eax, buton_x ;latura din stanga
	jl button_fail_4
	cmp eax, buton_dim + buton_x ;latura din dreapta
	jg button_fail_4
	
	mov eax, pos_y
	cmp eax, buton_y
	jl button_fail_4
	cmp eax, buton_dim + buton_y
	jg button_fail_4
	
	cmp mat[12], -1
	jne button_fail_4
	cmp pune_x_sau_O, 0
	jne pune_mat_1
	mov mat[12], 0
	jmp final

	pune_mat_1:
	mov mat[12],1
	final:
	popa
endm

verif_click_buton_5 macro buton_x, buton_y, buton_dim, pos_x, pos_y
	local pune_mat_1, final
	pusha
	mov eax, pos_x
	cmp eax, buton_x ;latura din stanga
	jl button_fail_5
	cmp eax, buton_dim + buton_x ;latura din dreapta
	jg button_fail_5
	
	mov eax, pos_y
	cmp eax, buton_y
	jl button_fail_5
	cmp eax, buton_dim + buton_y
	jg button_fail_5
	
	cmp mat[16], -1
	jne button_fail_5
	cmp pune_x_sau_O, 0
	jne pune_mat_1
	mov mat[16], 0
	jmp final
	
	pune_mat_1:
	mov mat[16],1
	final:
	popa
endm

verif_click_buton_6 macro buton_x, buton_y, buton_dim, pos_x, pos_y
	local pune_mat_1, final
	pusha
	mov eax, pos_x
	cmp eax, buton_x ;latura din stanga
	jl button_fail_6
	cmp eax, buton_dim + buton_x ;latura din dreapta
	jg button_fail_6
	
	mov eax, pos_y
	cmp eax, buton_y
	jl button_fail_6
	cmp eax, buton_dim + buton_y
	jg button_fail_6
	
	cmp mat[20], -1
	jne button_fail_6
	cmp pune_x_sau_O, 0
	jne pune_mat_1
	mov mat[20], 0
	jmp final
	
	pune_mat_1:
	mov mat[20],1
	final:
	popa
endm

verif_click_buton_7 macro buton_x, buton_y, buton_dim, pos_x, pos_y
	local pune_mat_1, final
	pusha
	mov eax, pos_x
	cmp eax, buton_x ;latura din stanga
	jl button_fail_7
	cmp eax, buton_dim + buton_x ;latura din dreapta
	jg button_fail_7
	
	mov eax, pos_y
	cmp eax, buton_y
	jl button_fail_7
	cmp eax, buton_dim + buton_y
	jg button_fail_7
	
	cmp mat[24], -1
	;verificam daca pozitia nu e deja ocupata
	jne button_fail_7
	cmp pune_x_sau_O, 0
	jne pune_mat_1
	mov mat[24], 0
	jmp final
	
	pune_mat_1:
	mov mat[24],1
	final:
	popa
endm

verif_click_buton_8 macro buton_x, buton_y, buton_dim, pos_x, pos_y
	local pune_mat_1, final
	pusha
	mov eax, pos_x
	cmp eax, buton_x ;latura din stanga
	jl button_fail_8
	cmp eax, buton_dim + buton_x ;latura din dreapta
	jg button_fail_8
	
	mov eax, pos_y
	cmp eax, buton_y
	jl button_fail_8
	cmp eax, buton_dim + buton_y
	jg button_fail_8
	
	cmp mat[28], -1
	jne button_fail_8
	cmp pune_x_sau_O, 0
	jne pune_mat_1
	mov mat[28], 0
	jmp final

	pune_mat_1:
	mov mat[28],1
	final:
	popa
endm

verif_click_buton_9 macro buton_x, buton_y, buton_dim, pos_x, pos_y
	local pune_mat_1, final
	pusha
	mov eax, pos_x
	cmp eax, buton_x ;latura din stanga
	jl button_fail_9
	cmp eax, buton_dim + buton_x ;latura din dreapta
	jg button_fail_9
	
	mov eax, pos_y
	cmp eax, buton_y
	jl button_fail_9
	cmp eax, buton_dim + buton_y
	jg button_fail_9
	
	cmp mat[32], -1
	jne button_fail_9
	cmp pune_x_sau_O, 0
	jne pune_mat_1
	mov mat[32], 0
	jmp final
	
	pune_mat_1:
	mov mat[32],1
	final:
	popa
endm

pune_simbol macro x_sau_O, buton_x, buton_y
local pune_O, stop
	pusha
	mov ecx, pune_x_sau_O
	cmp ecx, 1
	jne pune_O
	make_text_macro 'X', area, buton_x + (button_size - symbol_width)/2, buton_y+(button_size - symbol_height)/2
	dec pune_x_sau_O
	jmp stop
	
	pune_O:
	make_text_macro 'O', area, buton_x+ (button_size - symbol_width)/2, buton_y+(button_size - symbol_height)/2
	inc pune_x_sau_O
	
	stop:
	jmp evt_click
	popa
endm

verif_castigator_diagonala_1 proc
	mov ebx, mat[32]
	cmp ebx, mat[16]
	jne aici
	cmp ebx, mat[0]
	jne aici
	cmp ebx, -1
	je aici
	cmp ebx, 1
	jne castig_O
	mov edx, 1
	jmp iesire
	
	castig_O:
	mov edx, 0
	jmp iesire
	
	aici:
	mov edx, -1
	iesire:
	ret
verif_castigator_diagonala_1 endp

verif_castigator_diagonala_2 proc
	mov ebx, mat[24]
	cmp ebx, mat[16]
	jne aici
	cmp ebx, mat[8]
	jne aici
	cmp ebx, -1
	je aici
	cmp ebx, 0
	jne castigator_x
	mov edx, 0
	jmp iesire
	
	castigator_x:
	mov edx, 1
	jmp iesire
	
	aici:
	mov edx, -1
	iesire:
	ret
verif_castigator_diagonala_2 endp

verif_castigator_linie proc
	mov ebx, mat[24]
	cmp ebx, mat[28]
	jne linie_2
	cmp ebx, mat[32]
	jne linie_2
	cmp ebx, -1
	je linie_2
	cmp ebx, 0
	je castiga_O
	cmp ebx, 1
	je castiga_X
	jmp aici
	
	linie_2:
	mov ebx, mat[12]
	cmp ebx, mat[16]
	jne linie_1
	cmp ebx, mat[20]
	jne linie_1
	cmp ebx, -1
	je  linie_1
	cmp ebx, 0
	je castiga_O
	cmp ebx, 1
	je castiga_X
	jmp aici
	
	linie_1:
	mov ebx, mat[0]
	cmp ebx, mat[4]
	jne aici
	cmp ebx, mat[8]
	jne aici
	cmp ebx, -1
	je  aici
	cmp ebx, 0
	je castiga_O
	cmp ebx, 1
	je castiga_X
	jmp aici
	
	castiga_X:
	mov edx, 1
	jmp iesire
	
	castiga_O:
	mov edx, 0
	jmp iesire
	
	aici:
	mov edx, -1

	iesire:
	ret
verif_castigator_linie endp

verif_castigator_coloana proc
	mov ebx, mat[8]
	cmp ebx, mat[20]
	jne col_2
	cmp ebx, mat[32]
	jne col_2
	cmp ebx, -1
	je col_2
	cmp ebx, 0
	je castiga_O
	cmp ebx, 1
	je castiga_X
	jmp aici
	
	col_2:
	mov ebx, mat[4]
	cmp ebx, mat[16]
	jne col_1
	cmp ebx, mat[28]
	jne col_1
	cmp ebx, -1
	je  col_1
	cmp ebx, 0
	je castiga_O
	cmp ebx, 1
	je castiga_X
	jmp aici
	
	col_1:
	mov ebx, mat[0]
	cmp ebx, mat[12]
	jne aici
	cmp ebx, mat[24]
	jne aici
	cmp ebx, -1
	je  aici
	cmp ebx, 0
	je castiga_O
	cmp ebx, 1
	je castiga_X
	jmp aici
	
	castiga_X:
	mov edx, 1
	jmp iesire
	
	castiga_O:
	mov edx, 0
	jmp iesire
	
	aici:
	mov edx, -1

	iesire:
	ret
verif_castigator_coloana endp

verif_remiza proc
	cmp mat[0], -1
	je aici
	cmp mat[4], -1
	je aici
	cmp mat[8], -1
	je aici
	cmp mat[12], -1
	je aici
	cmp mat[16], -1
	je aici
	cmp mat[20], -1
	je aici
	cmp mat[24], -1
	je aici
	cmp mat[28], -1
	je aici
	cmp mat[32], -1
	je aici
	
	mov edx, 2
	jmp iesire
	
	aici:
	mov edx, -1
	jmp iesire
	
	iesire:
	ret
verif_remiza endp

castigator proc
	call verif_castigator_diagonala_1
	cmp edx, -1
	jne iesire
	call verif_castigator_diagonala_2
	cmp edx, -1
	jne iesire
	call verif_castigator_linie
	cmp edx, -1
	jne iesire
	call verif_castigator_coloana
	cmp edx, -1
	jne iesire
	call verif_remiza
	cmp edx, -1
	jne iesire
	iesire:
	ret
castigator endp	

afisare_edx macro nr
	pusha
	push nr
	push offset format
	call printf
	add esp, 8
	popa
endm

afisare_matrice macro matrice 
local afisare_mat
pusha
mov esi,  0
afisare_mat:
	afisare_edx matrice[esi*4]
	inc esi
	cmp esi, 9
	jne afisare_mat
popa
endm

colorare_fundal macro culoare
local first, last
	pusha
	mov ebx, area
	mov ecx, area_width
first:
	pusha
	mov ecx, area_height
last:
	mov dword ptr[ebx], culoare
	add ebx,[area_width * 4]
	loop last
	popa
	add ebx,4
	loop first
	popa
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y

draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
	mov eax, [ebp+arg2]
	cmp eax, 380
	jg verificare_play_again_pt_eroare
	jmp verificare_play_again
	
verificare_play_again_pt_eroare:
	cmp eax, 460
	jl afisare_litere
	cmp eax, 530
	jg afisare_litere
	mov eax, [ebp+arg3]
	cmp eax, 310
	jl afisare_litere
	cmp eax, 380
	jg afisare_litere
	
verificare_play_again:
	mov eax, [ebp+arg2]
	cmp eax, buton_play_again_x
	jl sari_aici
	cmp eax, buton_play_again_size+buton_play_again_x
	jg sari_aici
	mov eax, [ebp+arg3]
	cmp eax, buton_play_again_y
	jl sari_aici
	cmp eax, buton_play_again_size+buton_play_again_y
	jg sari_aici
	make_text_macro ' ', area, 225, 120
	make_text_macro ' ', area, 285, 120
	make_text_macro ' ', area, 345, 120
	make_text_macro ' ', area, 225, 180
	make_text_macro ' ', area, 285, 180
	make_text_macro ' ', area, 345, 180
	make_text_macro ' ', area, 225, 240
	make_text_macro ' ', area, 285, 240
	make_text_macro ' ', area, 345, 240
	make_text_macro ' ', area, 260, 320
	make_text_macro ' ', area, 270, 320
	make_text_macro ' ', area, 280, 320
	make_text_macro ' ', area, 290, 320
	make_text_macro ' ', area, 300, 320
	mov mat[0], -1
	mov mat[4], -1
	mov mat[8], -1
	mov mat[12], -1
	mov mat[16], -1
	mov mat[20], -1
	mov mat[24], -1
	mov mat[28], -1
	mov mat[32], -1
	mov castigator_gasit, 0
	mov pune_x_sau_O, 1
	jmp afisare_litere
	
	
sari_aici:
	cmp castigator_gasit, 0
	jne afisare_litere
	verif_click_buton_1 buton1_x, buton1_y, button_size, [ebp+arg2], [ebp+arg3]
	pune_simbol pune_x_sau_O, buton1_x, buton1_y
	call castigator
	cmp edx, 1
	je castigator_X
	cmp edx, 0
	je castigator_O
	cmp edx, 2
	je scrie_remiza
	
button_fail_1:
		cmp castigator_gasit, 0
		jne afisare_litere
		verif_click_buton_2 buton2_x, buton2_y, button_size, [ebp+arg2], [ebp+arg3]
		pune_simbol pune_x_sau_O, buton2_x, buton2_y
		call castigator
		cmp edx, 1
		je castigator_X
		cmp edx, 0
		je castigator_O
		cmp edx, 2
		je scrie_remiza
		jmp afisare_litere
	
button_fail_2:
		cmp castigator_gasit, 0
		jne afisare_litere
		verif_click_buton_3 buton3_x, buton3_y, button_size, [ebp+arg2], [ebp+arg3]
		pune_simbol pune_x_sau_O, buton3_x, buton3_y
		call castigator
		cmp edx, 1
		je castigator_X
		cmp edx, 0
		je castigator_O
		cmp edx, 2
		je scrie_remiza	
		jmp afisare_litere
		
button_fail_3:
		cmp castigator_gasit, 0
		jne afisare_litere
		verif_click_buton_4 buton4_x, buton4_y, button_size, [ebp+arg2], [ebp+arg3]
		pune_simbol pune_x_sau_O, buton4_x, buton4_y
		call castigator
		cmp edx, 1
		je castigator_X
		cmp edx, 0
		je castigator_O
		cmp edx, 2
		je scrie_remiza
		jmp afisare_litere
		
button_fail_4:
		cmp castigator_gasit, 0
		jne afisare_litere
		verif_click_buton_5 buton5_x, buton5_y, button_size, [ebp+arg2], [ebp+arg3]
		pune_simbol pune_x_sau_O, buton5_x, buton5_y
		call castigator
		cmp edx, 1
		je castigator_X
		cmp edx, 0
		je castigator_O
		cmp edx, 2
		je scrie_remiza
		jmp afisare_litere
		
button_fail_5:
		cmp castigator_gasit, 0
		jne afisare_litere
		verif_click_buton_6 buton6_x, buton6_y, button_size, [ebp+arg2], [ebp+arg3]
		pune_simbol pune_x_sau_O, buton6_x, buton6_y
		call castigator
		cmp edx, 1
		je castigator_X
		cmp edx, 0
		je castigator_O
		cmp edx, 2
		je scrie_remiza	
		jmp afisare_litere
		
button_fail_6:
		cmp castigator_gasit, 0
		jne afisare_litere
		verif_click_buton_7 buton7_x, buton7_y, button_size, [ebp+arg2], [ebp+arg3]
		pune_simbol pune_x_sau_O, buton7_x, buton7_y
		call castigator
		cmp edx, 1
		je castigator_X
		cmp edx, 0
		je castigator_O
		cmp edx, 2
		je scrie_remiza	
		jmp afisare_litere
		
button_fail_7:
		cmp castigator_gasit, 0
		jne afisare_litere
		verif_click_buton_8 buton8_x, buton8_y, button_size, [ebp+arg2], [ebp+arg3]
		pune_simbol pune_x_sau_O, buton8_x, buton8_y
		call castigator
		cmp edx, 1
		je castigator_X
		cmp edx, 0
		je castigator_O
		cmp edx, 2
		je scrie_remiza	
		jmp afisare_litere
	
button_fail_8:
		cmp castigator_gasit, 0
		jne afisare_litere
		verif_click_buton_9 buton9_x, buton9_y, button_size, [ebp+arg2], [ebp+arg3]
		pune_simbol pune_x_sau_O, buton9_x, buton9_y
		call castigator
		cmp edx, 1
		je castigator_X
		cmp edx, 0
		je castigator_O
		cmp edx, 2
		je scrie_remiza	
		jmp afisare_litere
	
button_fail_9:
		call castigator
		cmp edx, 1
		je castigator_X
		cmp edx, 0
		je castigator_O
		cmp edx, 2
		je scrie_remiza		
		jmp afisare_litere	
		
castigator_X:
		mov castigator_gasit, 1
		make_text_macro 'X', area, 260, 320
		make_text_macro ' ', area, 270, 320
		make_text_macro 'W', area, 280, 320
		make_text_macro 'O', area, 290, 320
		make_text_macro 'N', area, 300, 320
		jmp afisare_litere
	
castigator_O:
		mov castigator_gasit, 1
		make_text_macro 'O', area, 260, 320
		make_text_macro ' ', area, 270, 320
		make_text_macro 'W', area, 280, 320
		make_text_macro 'O', area, 290, 320
		make_text_macro 'N', area, 300, 320
		jmp afisare_litere
		
scrie_remiza:
		mov castigator_gasit, 1
		make_text_macro 'D', area, 260, 320
		make_text_macro 'R', area, 270, 320
		make_text_macro 'A', area, 280, 320
		make_text_macro 'W', area, 290, 320
		jmp afisare_litere
	
evt_timer:
	inc counter
	
afisare_litere:	
	mov eax, 0
	cmp colorare_fundal_var, 0
	jne skip_colorare
	colorare_fundal 0e4f4fch
	mov colorare_fundal_var, 1
		
	skip_colorare:	
	;scriem un mesaj
	make_text_macro 'T', area, 230, 25
	make_text_macro 'I', area, 240, 25
	make_text_macro 'C', area, 250, 25
	make_text_macro ' ', area, 260, 25
	make_text_macro 'T', area, 270, 25
	make_text_macro 'A', area, 280, 25
	make_text_macro 'C', area, 290, 25
	make_text_macro ' ', area, 300, 25
	make_text_macro 'T', area, 310, 25
	make_text_macro 'O', area, 320, 25
	make_text_macro 'E', area, 330, 25
	
	make_text_macro 'P', area, 470, 320
	make_text_macro 'L', area, 480, 320
	make_text_macro 'A', area, 490, 320
	make_text_macro 'Y', area, 500, 320
	
	make_text_macro 'A', area, 470, 350
	make_text_macro 'G', area, 480, 350
	make_text_macro 'A', area, 490, 350
	make_text_macro 'I', area, 500, 350
	make_text_macro 'N', area, 510, 350

	;desenam matricea
	desenare_matrice buton1_x, buton1_y, buton2_x, buton2_y, buton3_x, buton3_y, buton4_x, buton4_y, buton5_x, buton5_y, buton6_x, buton6_y, buton7_x, buton7_y, buton8_x, buton8_y, buton9_x, buton9_y
	
	;desenam butonul de PLAY AGAIN
	desenare_buton buton_play_again_x,buton_play_again_y,buton_play_again_size, 0
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2 ;inmultim cu 4 pt ca fiecare pixel ocupa un dword <=> 4 byte
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
