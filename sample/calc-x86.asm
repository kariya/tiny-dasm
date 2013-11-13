/* stack calculator examplae */
/* Ussage: 
	def f 1 + end
	def g dup * end
	calc 1 f g end
    => 4
*/

#include <stdio.h>
#include <stdarg.h>
#include <unistd.h>
#include <sys/mman.h>
#include <ctype.h>
#include <string.h>

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

typedef enum {
	T_EOF,
	T_DEF,
	T_CALC,
	T_END,
	T_PLUS,
	T_MINUS,
	T_AST,
	T_SLASH,
	T_DUP,
	T_SWAP,
	T_INT,
	T_ID,
} token_t;

int ch;
int token;
int token_value;

int getch() {
	ch = getchar();
	return ch;
}

token_t gettoken() {
	while (isspace(ch)) getch();
	if (ch == EOF) {
		token = T_EOF;
		return T_EOF;
	}		
	if (ch == '+') {
		getch();
		token = T_PLUS;
		return T_PLUS;
	}		
	if (ch == '-') {
		getch();
		token = T_MINUS;
		return T_MINUS;
	}		
	if (ch == '*') {
		getch();
		token = T_AST;
		return T_AST;
	}		
	if (ch == '/') {
		getch();
		token = T_SLASH;
		return T_SLASH;
	}		
	if (isdigit(ch)) {
		token_value = ch - '0';
		getch();
		while (isdigit(ch)) {
			token_value	*= 10;
			token_value += ch - '0';
			getch();
		}
		token = T_INT;
		return T_INT;
	}		
	if (isalpha(ch)) {
		char buf[32], *p = buf;
		*p++ = ch;	
		ch = getchar();
		while (isalpha(ch)) {
			*p++ = ch;
			getch();
		}
		*p++ = '\0';
		if (strcmp(buf, "def") == 0) {
			token = T_DEF;
			return T_DEF;
		}
		if (strcmp(buf, "calc") == 0) {
			token = T_CALC;
			return T_CALC;
		}
		if (strcmp(buf, "end") == 0) {
			token = T_END;
			return T_END;
		}
		if (strcmp(buf, "dup") == 0) {
			token = T_DUP;
			return T_DUP;
		}
		if (strcmp(buf, "swap") == 0) {
			token = T_SWAP;
			return T_SWAP;
		}
		token_value = (int) strdup(buf);
		token =T_ID;
		return T_ID;
	}		
}

struct tbl {
	char* name;
	void* f;
} table[32];

struct tbl *tblp = table;

void* find(char* name) {
	int i;
	
	for (i = 0; i < sizeof(table) / sizeof(table[0]); ++i) {
		if (strcmp(table[i].name, name) == 0) return table[i].f;
	}
	return NULL;
}

int main () {
	emitInit();
	emit([[nop]]);
	emit([[nop]]);
	emit([[nop]]);
	emit([[nop]]);

	getch();
	while (gettoken() != T_EOF) {
#if 0
		printf("%d %d\n", token, token_value);
#else
		if (token == T_DEF) {
			gettoken();
			tblp->name = (void*) token_value;
			tblp->f = emitPrologue();
			tblp++;
			char *p;
			while (token != T_END) {
				switch (token) {
				case T_PLUS:
					emit([[pop %eax]]);	
					emit([[pop %ebx]]);	
					emit([[add %ebx, %eax]]);
					emit([[push %eax]]);	
					break;
				case T_MINUS:
					emit([[pop %ebx]]);	
					emit([[pop %eax]]);	
					emit([[sub %ebx, %eax]]);
					emit([[push %eax]]);	
					break;
				case T_AST:
					emit([[pop %eax]]);	
					emit([[pop %ebx]]);	
					emit([[mul %ebx]]);
					emit([[push %eax]]);	
					break;
				case T_SLASH:
					emit([[pop %ebx]]);	
					emit([[pop %eax]]);	
					emit([[div %ebx]]);
					emit([[push %eax]]);	
					break;
				case T_DUP:
					emit([[pop %eax]]);	
					emit([[push %eax]]);	
					emit([[push %eax]]);	
					break;
				case T_SWAP:
					emit([[pop %eax]]);	
					emit([[pop %ebx]]);	
					emit([[push %eax]]);	
					emit([[push %ebx]]);	
					break;
				case T_INT:
					p = emit([[mov $0, %eax]]);
					*(int*)(p+1) = token_value;
					emit([[push %eax]]);	
					break;
				default:
					break;
				}
				gettoken();
			}
			emit([[pop %eax]]);	
			emitEpilogue();
		}	
		else if (token == T_CALC) {
			gettoken();
			void *f = emitPrologue(), *p, *g;
			while (token != T_END) {
				switch (token) {
				case T_PLUS:
					emit([[pop %eax]]);	
					emit([[pop %ebx]]);	
					emit([[add %ebx, %eax]]);
					emit([[push %eax]]);	
					break;
				case T_MINUS:
					emit([[pop %ebx]]);	
					emit([[pop %eax]]);	
					emit([[sub %ebx, %eax]]);
					emit([[push %eax]]);	
					break;
				case T_AST:
					emit([[pop %eax]]);	
					emit([[pop %ebx]]);	
					emit([[mul %ebx]]);
					emit([[push %eax]]);	
					break;
				case T_SLASH:
					emit([[pop %ebx]]);	
					emit([[pop %eax]]);	
					emit([[div %ebx]]);
					emit([[push %eax]]);	
					break;
				case T_DUP:
					emit([[pop %eax]]);	
					emit([[push %eax]]);	
					emit([[push %eax]]);	
					break;
				case T_SWAP:
					emit([[pop %eax]]);	
					emit([[pop %ebx]]);	
					emit([[push %eax]]);	
					emit([[push %ebx]]);	
					break;
				case T_INT:
					p = emit([[mov $0, %eax]]);
					*(int*)(p+1) = token_value;
					emit([[push %eax]]);	
					break;
				case T_ID:
					g = find((char*) token_value);
					p = emit([[call 0]]);
					*(int*)(p+1) = (int) g - (int) emitPc();
					p = emit([[push %eax]]);
					break;
				default:
					break;
				}
				gettoken();
			}
			emit([[pop %eax]]);	
			emitEpilogue();
#ifndef DUMP
			int v = (*(int(*)())f)();
			printf("%d\n", v);
#endif
		}	
#endif
	}
	

#ifdef DUMP
	dump();
#else
	//int x = ((int (*)(int))f)(1);
	//printf("%d\n", x);
#endif
	return 0;
}

