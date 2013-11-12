#include <stdio.h>
#include <stdarg.h>
#include <unistd.h>
#include <sys/mman.h>

char *code, *codep;	

/* initialize; call first once */
void emitInit() {
	int psize = sysconf(_SC_PAGESIZE);
	if(posix_memalign(&code, psize, psize)) err(1, "memalign");
	if (mprotect(code, psize, PROT_EXEC|PROT_READ|PROT_WRITE)) err(1, "mprotect");
	codep = code;
}

/* emits machine codes */
char* emit(int argc, ...) {
	int i;
	char* start = codep;

	va_list argp;
	va_start(argp, argc);
	for (i = 0; i < argc; ++i) {
		char op = va_arg(argp, int);
		*codep++ = op;
	}
	va_end(argp);
	return start;
}

/* returns address which is the start address of next emit() */
char* emitPc() { return codep; }

/* function prologue */
char* emitPrologue() {
	char* start = emit([[push %ebp]]);
	emit([[mov %esp, %ebp]]);
	return start;
}

/* function epilogue */
char* emitEpilogue() {
	char* start = emit([[mov %ebp, %esp]]);
	emit([[pop %ebp]]);
	emit([[ret]]);
	return start;
}

/* debug utility */
void dump() {
	int i;
	printf("int f(int x) {");
	printf("\tasm(\".org 0x%x\");\n", (int) code);
	for (i = 0; i < emitPc() - code; ++i) printf("\tasm(\".byte 0x%x\");\n", code[i] & 0xff);
	printf("}");
}

/* int f(int x) { return x; } */
main () {
	emitInit();

	char* f = emitPrologue();
	emit([[mov 8(%ebp), %eax]]);
	emitEpilogue();

#ifdef DUMP
	dump();
#else
	int x = ((int (*)(int))f)(1);
	printf("%d\n", x);
#endif
}

