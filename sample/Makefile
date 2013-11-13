calc-x86: calc-x86.c
	gcc -m32 $< -o $@

calc-x86.c: calc-x86.asm
	../bin/dasm-x86.sh $< > $@

