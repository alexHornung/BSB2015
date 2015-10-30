; $Id: setup.asm 1484 2009-02-11 21:03:19Z hsc $

;******************************************************************************
;* Betriebssysteme                                                            *
;*----------------------------------------------------------------------------*
;*                                                                            *
;*                             S E T U P                                      *
;*                                                                            *
;*----------------------------------------------------------------------------*
;* Der Setup-Code liegt im System-Image direkt hinter dem Bootsektor und wird *
;* von diesem direkt nach dem Laden aktiviert. Der Code wird noch im          *
;* 'Real-Mode' gestartet, so dass zu Beginn auch noch BIOS-Aufrufe erlaubt    *
;* sind. Dann werden jedoch alle Interrupts verboten, die Adressleitung A20   *
;* aktiviert und die Umschaltung in den 'Protected-Mode' vorgenommen. Alles   *
;* weitere uebernimmt der Startup-Code des Systems.                           *
;******************************************************************************

;
; Konstanten
;
	SETUPSEG	equ 0x9000	; Setup-Code (max. 64K inkl. Stack)
	SYSTEMSEG	equ 0x1000	; System-Code (max. 512K)
	SECTORSZ	equ 512		; Groesse eines Sektors in Bytes
	SYSTEMSTART	equ 0x100000	; Hierhin wird das System nach Umschalten in den
					; Protected Mode kopiert, da GRUB das auch tut
					; (und GRUB kann nur an Adressen >1M laden).

[SECTION .text]
[BITS 16]
;
; Segmentregister initialisieren
;
start:
	mov	dx, ax		; Anzahl Systemsektoren in DX sichern.

	mov	ax,cs		; Daten-, Code- und Stacksegment sollen
	mov	ds,ax		; hierher zeigen.
	mov	ss,ax		; Alle drei Segment duerfen nicht mehr
	mov	sp,0xfffe	; als 64 KByte einnehmen (zusammen).

	mov [system_sectors], dx	; Anzahl der Systemsektoren im Speicher ablegen

;
; Ausgabe einer Meldung mit Hilfe eines BIOS-Aufrufs
;
	mov	ah,0x03		; Feststellen der Cursor-Position
	xor	bh,bh
	int	0x10

	mov	cx,14
	mov	bx,0x0007	; page 0, attribute 7 (normal)
	mov	ax,ds
	mov	es,ax
	mov	bp,setupmessage
	mov	ax,0x1301	; Ausgabe des Textes, Cursor bewegen
	int	0x10
;
; So, jetzt werden die Interrupts abgeschaltet
;
	cli			; Maskierbare Interrupts verbieten
	mov	al,0x80		; NMI verbieten
	out	0x70,al
;
; IDT und GDT setzen
;
	lidt	[idt_48]
	lgdt	[gdt_48]
;
; Aktivieren der Adressleitung A20
;
	call	empty_8042
	mov	al,0xd1
	out	0x64,al
	call	empty_8042
	mov	al,0xdf
	out	0x60,al
	call	empty_8042
	mov	al,0xff
	out	0x64,al
	call	empty_8042
;
; Moeglichen Koprozessor zuruecksetzen
;
	xor	ax,ax
	out	0xf0,al
	call	delay
	out	0xf1,al
	call	delay
;
; Umschalten in den Protected Mode
;
	mov	eax,cr0			; Setze PM-Bit im Kontrollregister 1
	or	eax,1
	mov	cr0,eax

	jmp dword 0x08:SETUPSEG*0x10+copy_system ; Far-Jump, um
	                                         ; a) fetch Pipeline zu leeren
	                                         ; b) CS Register sinnvoll zu belegen
[BITS 32]
; Arbeite jetzt im Protected Mode
copy_system:
;
; Systemcode von 0x10000 nach 0x100000 kopieren.
;

	mov	ax, 0x10			; 0x10 entspricht dem Data-Eintrag in der GDT.
	mov	ds, ax				; DS und ES werden von movsd benoetigt.
	mov	es, ax

	xor	ecx, ecx			; Anzahl Systemsektoren laden
	mov	cx, [SETUPSEG*0x10+system_sectors]

	imul	ecx, SECTORSZ/4

	mov	esi, SYSTEMSEG*0x10	; Hier liegt der Systemcode noch ...
	mov	edi, SYSTEMSTART	; ... und hierhin moechten wir ihn verschieben

	cld				; Nach jedem movsb ESI,EDI inkrementieren
	rep movsd		; Kopiere 4 Byte von [ESI] nach [EDI] ecx male


;
; Sprung in den Startup-Code des Systems
;

	jmp	dword 0x08:SYSTEMSTART

error:
	hlt
[BITS 16]
; Ab hier wieder Real-Mode Code fuer die Codeteile
; vor der Umschaltung in den Protected Mode

;
; empty_8042
;
; Ein- und Ausgabepuffer des Tastaturcontrollers leeren
;
empty_8042:
	call	delay
	in	al,0x64			; 8042 Status Port
	test	al,1			; Ausgabepuffer voll?
	jz	no_output
	call	delay
	in	al,0x60			; wenn ja: ueberlesen
	jmp	empty_8042
no_output:
	test	al,2			; Eingabepuffer voll?
	jnz	empty_8042		; wenn ja, noch mal testen, irgendwann
	ret				; muss es weg sein.
;
; delay:
;
; Kurze Verzoegerung fuer in/out-Befehle
;
delay:
	out 0x80,al
	ret

;
; Datenbereich
;
[SECTION .data]

; Meldung

system_sectors:
	dw 0

setupmessage:
	db	13,10
	db	'setup active'
;
; Descriptor-Tabellen
;
gdt:
	dw	0,0,0,0		; NULL Deskriptor

	dw	0xFFFF		; 4Gb - (0x100000*0x1000 = 4Gb)
	dw	0x0000		; base address=0
	dw	0x9A00		; code read/exec
	dw	0x00CF		; granularity=4096, 386 (+5th nibble of limit)

	dw	0xFFFF		; 4Gb - (0x100000*0x1000 = 4Gb)
	dw	0x0000		; base address=0
	dw	0x9200		; data read/write
	dw	0x00CF		; granularity=4096, 386 (+5th nibble of limit)

idt_48:
	dw	0		; idt limit=0
	dw	0,0		; idt base=0L

gdt_48:
	dw	0x18		; GDT Limit=24, 3 GDT Eintraege
	dd	SETUPSEG*0x10+gdt; Physikalische Adresse der GDT
