# Snake 512
Snake that fits in 512 bytes (boot sector size) written for x86 real mode.

<p float="left">
  <img src="https://raw.githubusercontent.com/mfurga/snake-512/master/assets/snake_1.png" width="49%" />
  <img src="https://raw.githubusercontent.com/mfurga/snake-512/master/assets/snake_2.png" width="49%" /> 
</p>

## How to run

```bash
nasm snake.asm -o snake && qemu-system-i386 snake
```

