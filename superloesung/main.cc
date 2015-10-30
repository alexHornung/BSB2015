/* $Id: main.cc 956 2008-10-19 22:24:23Z hsc $ */

/* Hier muesst ihr selbst Code vervollstaendigen */ 
#include "machine/cgascr.h"

int main()
{
/* Hier muesst ihr selbst Code vervollstaendigen */         
 	// git test
CGA_Screen screen;
	
	screen.show(19,20,'#',0x8f); // einfachen Character anzeigen
	
screen.setpos(20,15);
	screen.print("hello world!", 12, 0x1f); // Text anzeigen
	
	screen.print("hello remote", 12, 0xaf); // Text anzeigen
 
/* Hier muesst ihr selbst Code vervollstaendigen */ 
                         
/* Hier muesst ihr selbst Code vervollstaendigen */                         
 
   return 0;
 }
