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

It use GNU as as external assembler so can support many architectures.
 
I was inspired this application by DynASM[1].

## What's NOT supported

### label and automatic address computation

### use C value as immediate

### C call convention support

## Usage

##License
GPL

## Refernece
[1] http://luajit.org/dynasm.html
