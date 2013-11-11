tiny-dasm
=========

very tiny dynamic assembler

## What's this

Very simple preprocessor for dynamic code generation.

You can write like:
  emit([[mov r0, #1]]);
and [[...]] is preprocessed to its op code.

It use GNU as as external assembler so can support many architecture.
 
I was inspired this application by DynASM[1].

## What's not supported

### label and automatic address computation

### use C value as immediate

## Usage

##License
GPL

## Refernece
[1] http://luajit.org/dynasm.html
