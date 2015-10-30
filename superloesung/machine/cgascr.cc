/* $Id: cgascr.cc 5834 2013-10-08 17:04:08Z os $ */

/*****************************************************************************/
/* Betriebssysteme                                                           */
/*---------------------------------------------------------------------------*/
/*                                                                           */
/*                             C G A _ S C R E E N                           */
/*                                                                           */
/*---------------------------------------------------------------------------*/
/* Mit Hilfe dieser Klasse kann man auf den Bildschirm des PCs zugreifen.    */
/* Der Zugriff erfolgt direkt auf der Hardwareebene, d.h. ueber den Bild-    */
/* schirmspeicher bzw. die I/O-Ports der Grafikkarte.                        */
/*****************************************************************************/

#include "machine/cgascr.h"
#include "machine/io_port.h"

/* Hier muesst ihr selbst Code vervollstaendigen */ 

static IO_Port cga_index(0x3d4);
static IO_Port cga_data(0x3d5);

void CGA_Screen::show (int x, int y, char c, unsigned char attrib){
	char *CGA_START = (char *)0xb8000;
	char *pos;	
	pos = CGA_START + 2*(x + y*80);
	*pos = c;
	*(pos + 1) = attrib; // weiss auf schwarz
}


void CGA_Screen::setpos (int x, int y){
	if (x >= 80 || y >= 25) {
		y += (int) (x / 80);
		x = x % 80;

		if (y >= 25) {
			for (unsigned int i = 0; i <= y % 25; i++) {
			  // TODO scrollUp();
			}

		y = 24;
		}
	}

	cga_index.outb(14);
	cga_data.outb(x);


	cga_index.outb(15);
	cga_data.outb(y);
}

void CGA_Screen::getpos (int &x, int &y){
	// high
	cga_index.outb(14);
	x = cga_data.inb();

	// low
	cga_index.outb(15);
	y = cga_data.inb();
}

void CGA_Screen::print (const char* text, int length, unsigned char attrib){ // sorgt dafür, dass text hier nicht ohne Hilfsmittel aus Versehen verändert wird
	int x;
   int y;
          
   getpos(x, y);

	for(int i = 0; i < length; i++){
			show(x+i, y, text[i], attrib);
	}	

}
