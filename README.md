tiny-dasm
=========

very tiny dynamic assembler

## What's this

Very simple preprocessor for dynamic code generation.

You can write in C like:
```C
  emit([[mov r0, #1]]);
```
and [[...]] is preprocessed to its machine code.

It use GNU assembler(gas) as external assembler so can support many architectures.
 
I was inspired this application by DynASM[1].

## What's NOT supported
Why so few and poor facilities? Because it is meant to use as 1-path generator.
Address linking involves multiple path, I'm afraid.

### label and automatic address computation
If you want to generate code like 
```asm
  mov r0, #10
label:
  sub r0, #1
  bne label
```
then you must 
```C
  emit([[mov r0, #10]]);
  label = emit([[sub r0, #1]]);
  emit([[bne 0]] | calc_relative_offset(label, pc()));
```

It's too tedious. But this is an TINY assembler.

### use C value as immediate
Even if you want to write 
```C
  int x = ...;
  emit([[mov r0, x]]);
```
you cannot. Insted
```C
  int x = ...;
  emit([[mov r0, #0] | (x & 0xff));
```
or like.

Too tedious? Remember this is an TINY assembler.

### C call convention support
When writing an function, you have to know the call convention.
Some appropriate library might help, but there isn't now. Sorry.

### Macro
No, no, no.

## Usage
```
  bin/dasm.sh source.asm > target.c
  gcc target.c
```

## TODO
Add sample C codes (tutorial).

Helpful support library (as long as which does not break 1-pathness).

##License
GPL

## Refernece
[1] http://luajit.org/dynasm.html

