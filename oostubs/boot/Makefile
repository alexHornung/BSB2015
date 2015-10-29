# $Id: Makefile 956 2008-10-19 22:24:23Z hsc $

all: bootsect setup

% : %.asm
	nasm -f bin $<

clean:
	rm -f *~ bootsect setup
