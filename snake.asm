;
; Snake-512
;

[bits 16]
org 7c00h                                   ; Bootloader starts at 0x7c00

C_BLACK          equ 00h
C_WHITE          equ 0fh
C_BROWN          equ 06h
C_GREEN_LIGHT    equ 75h
C_GREEN          equ 0beh
C_RED            equ 04h
C_GRAY           equ 12h
C_GRAY_LIGHT     equ 14h

DELAY            equ 4
SCALE            equ 8                      ; SCALE must divide WIDTH and HEIGHT
WIDTH            equ 320
HEIGHT           equ 200

; Colors
BACKGROUD_COLOR  equ C_GREEN_LIGHT
SNAKE_COLOR      equ C_GRAY_LIGHT
SNAKE_HEAD_COLOR equ C_GRAY
WALL_COLOR       equ C_GREEN
FOOD_COLOR       equ C_RED

; Init positions
SNAKE_INIT       equ WIDTH * SCALE + 4 * SCALE
FOOD_INIT        equ WIDTH * SCALE * 10 + 10 * SCALE

; Directions
D_LEFT           equ (-SCALE)
D_RIGHT          equ (SCALE)
D_UP             equ (-WIDTH * SCALE)
D_DOWN           equ (WIDTH * SCALE)

.setup:
  jmp word 0000h:start                      ; Make sure that CS = 0
  start:

  mov ax, cs                                ; Set DS = CS = 0
  mov ds, ax

  mov ax, 0013h                             ; Set video mode 320x200 256-color
  int 10h

  mov ax, 0a000h                            ; Set ES to start of video memory
  mov es, ax

.game_start:
  mov ax, WALL_COLOR                        ; Set wall color
  xor di, di
  mov cx, WIDTH * HEIGHT
  rep stosb

  call clear_background                     ; Set background color

  mov ah, 02h                               ; Set cursor position
  xor bh, bh
  mov dx, 0b0fh
  int 10h

  mov si, title_msg                         ; Print game title
  call print_string

  mov dx, 0d0ah                             ; Set cursor pointer
  int 10h

  mov si, new_game_msg                      ; Print new game message
  call print_string

.wait_for_n_key:
  in al, 60h                                ; Wait until n is pressed
  cmp al, 31h
  jne .wait_for_n_key

  call clear_background                     ; Clear background

  mov al, FOOD_COLOR                        ; Place food on map
  mov di, FOOD_INIT
  call draw_square

  mov word [direction], D_DOWN              ; Set current direction to down
  mov word [length], 1                      ; Set length of snake to 1

  mov di, SNAKE_INIT                        ; Set head and tail pointers
  mov word [head], di
  mov word [tail], head

  mov al, SNAKE_HEAD_COLOR                  ; Place snake on map
  call draw_square

.game_loop:
  in al, 60h                                ; Get last scan code
  and al, 7fh                               ; Recognize press and release codes

  cmp al, 11h                               ; Check if 'W' was pressed
  je .up

  cmp al, 1eh                               ; Check if 'A' was pressed
  je .left

  cmp al, 1fh                               ; Check if 'S' was pressed
  je .down

  cmp al, 20h                               ; Check if 'D' was pressed
  je .right

  jmp .move                                 ; Skip any other keypresses

.up:
  cmp word [direction], D_DOWN              ; Block move to opposite direction
  je .move

  mov word [direction], D_UP                ; Set snake direction to up
  jmp .move

.left:
  cmp word [direction], D_RIGHT             ; Block move to opposite direction
  je .move

  mov word [direction], D_LEFT              ; Set snake direction to left
  jmp .move

.down:
  cmp word [direction], D_UP                ; Block move to opposite direction
  je .move

  mov word [direction], D_DOWN              ; Set snake direction to down
  jmp .move

.right:
  cmp word [direction], D_LEFT              ; Block move to opposite direction
  je .move

  mov word [direction], D_RIGHT             ; Set snake direction to right
  ;jmp .move

.move:
  push es                                   ; Save ES register

  mov ax, cs                                ; Set ES regiter to CS
  mov es, ax

  mov bx, [tail]
  mov si, bx                                ; Set SI to tail
  lea di, [bx + 2]                          ; Set DI to 2 bytes after tail

  mov cx, [length]

  std                                       ; Set direction flag
  rep movsw                                 ; Shift positions array
  cld                                       ; Clear direction flag

  pop es                                    ; Restore ES

  mov ax, [head + 2]                        ; Set head to new position based on current direction
  add ax, [direction]
  mov word [head], ax

  mov di, [head + 2]                        ; Clear old head color
  mov al, SNAKE_COLOR
  call draw_square

  mov di, [head]                            ; Check if food was hitten
  cmp byte [es:di], FOOD_COLOR
  jne .food_no_hit

.food_hit:
  mov ax, [length]                          ; Increment length of snake
  inc ax
  mov [length], ax

  mov ax, [tail]                            ; Update tail pointer
  add ax, 2
  mov [tail], ax

.place_food:
  mov ax, [46ch]                            ; Place food on random position on map
  mov cx, 45
  mul cx
  add ax, 1337

  xor dx, dx
  mov bx, (HEIGHT / SCALE)
  div bx

  mov cx, ax

  mov ax, dx
  mov bx, WIDTH * SCALE
  mul bx

  mov di, ax

  mov ax, cx
  mov bx, (WIDTH / SCALE)
  div bx

  mov ax, dx
  mov bx, SCALE
  mul bx

  add di, ax

  cmp byte [es:di], BACKGROUD_COLOR         ; Check if food can be placed
  jne .place_food

  mov al, FOOD_COLOR                        ; Place food to new position
  call draw_square

  jmp .no_gameover

.food_no_hit:
  mov bx, [tail]                            ; Clear square after tail
  mov di, [bx + 2]
  mov al, BACKGROUD_COLOR
  call draw_square

  mov di, [head]                            ; Gameover check
  cmp byte [es:di], BACKGROUD_COLOR
  je .no_gameover

  mov ah, 02h                               ; GAMEOVER. Set cursor pointer
  xor bh, bh
  mov dx, 0b0fh
  int 10h

  mov si, gameover_msg                      ; Print gameover message
  call print_string

  mov dx, 0d0ah                             ; Set cursor pointer
  int 10h

  mov si, new_game_msg                      ; Print new game message
  call print_string

.wait_for_n_key2:
  in al, 60h                                ; Wait until n is pressed
  cmp al, 31h
  jne .wait_for_n_key2

  jmp .game_start

.no_gameover:
  mov di, [head]                            ; Color head on map
  mov al, SNAKE_HEAD_COLOR
  call draw_square

  mov bx, [46ch]                            ; Delay
  add bx, DELAY
  .delay:
    cmp [46ch], bx
    jl .delay

  jmp .game_loop

; IN al = color
; IN di = map position
draw_square:
  push di
  push ax
  push cx
  push dx

  mov cx, SCALE
  mov dx, di

_draw_square_loop:
  push cx

  mov cx, SCALE
  rep stosb

  pop cx

  add dx, WIDTH
  mov di, dx
  loop _draw_square_loop

  pop dx
  pop cx
  pop ax
  pop di
  ret


clear_background:
;  push di
;  push ax
;  push cx

  mov cx, HEIGHT - 2 * SCALE
  mov di, WIDTH * SCALE + SCALE

_clear_background_loop:
  push cx
  mov ax, BACKGROUD_COLOR
  mov cx, WIDTH - 2 * SCALE
  rep stosb
  pop cx
  add di, 2 * SCALE
  loop _clear_background_loop

;  pop cx
;  pop ax
;  pop di

  ret

; IN si = pointer to null-terminated string
print_string:
  push si
  push ax
  push bx

  mov ah, 0eh
  mov bx, 000fh
_print_char:
  mov al, [si]
  int 10h
  inc si
  cmp byte [si], 0
  jnz _print_char

  pop bx
  pop ax
  pop si
  ret

; Data
title_msg      db "SNAKE 512", 0
new_game_msg   db "press N key to start", 0
gameover_msg   db "GAME OVER!", 0

%if ($ - $$) > 510
  %fatal "Bootloader exceed 512 bytes."
%endif

times 510 - ($ - $$) db 0
dw 0aa55h                                   ; Boot sector signature

[absolute 0x7e00]                           ; Uninitialized data start after signature

tail      resw 1
length    resw 1
direction resw 1

head:

