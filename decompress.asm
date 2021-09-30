; Assumptions: 
;	There's a payload to decompress before this code. [main - 2] contains the compressed length
;	as a single word. There's also a section of memory after this code that's large enough to
;	fit the entire decompressed payload. See equ at the end of the file.

main:
	xor eax, eax
	mov ax, [PayloadLength]
	mov esi, stub_start - 2
	sub esi, eax
	mov edi, WriteBuffer

;	DL = bit position counter
;	DH = bits to buffer
;	EBX = holds clocked in data
;	AL = target for loading and storing
ebu_decomp:
	lodsb			; Buffer next byte
	mov dl, 8		; Reset bit position counter

ebu_decode_symbol:
	dec dl			; increase bit counter
	shl al, 1		; shift out a flag bit. 
				; 0 = 8 bits of raw data
				; 1 = 4 bits length, 12 bits backwards offset
	mov dh, 8		
	jnc _only_8		; Set the counter to only 8 if we need a raw byte
	add dh, 8
_only_8:
	xor ebx, ebx		; Clear ebx to clock data into
ebu_clock_bits:
	cmp dl, 0		; Loop header, check that we still have data
	jne _read		
	lodsb			; If data is empty, clock in a new byte
	mov dl, 8		; and reset bit counter
	
_read:
	shl al, 1		; shift out one bit from al...
	adc ebx, 0		; ...and add it to ebx through carry
	dec dh			; decrease remaining bits to read
	jz _refill		; if this was the last bit, exit loop and
				; make sure we still have data available

	shl ebx, 1		; shift ebx to make room for the next bit
	dec dl			; otherwise just rinse and repeat
	jmp ebu_clock_bits

_refill:
	dec dl			; reading the last bit might have left us with an
	jnz ebu_bits_read	; empty buffer, if so we clock in one more byte here
	lodsb
	mov dl, 8

ebu_bits_read:

	mov ecx, ebx		; Done reading 8 or 16 bits, check if the highest nibble
	and ecx, 0xf000		; has any contents. If yes we decoded 16 bits, if no we decoded
	jz ebu_write_raw	; 8. If it's the 8 bit one we jump to the code for writing a single 
				; 8 bit value and repeat from the top.

ebu_write_coded:
	shr ecx, 12		; We read 16 bits, huh? Means we have a section to copy
	inc ecx			; Figure out the length of data to copy, shift right to align with
				; the register and add one

	and ebx, 0xfff		; ebx still has the 16 bit value, and with 0xfff gives us just the 
				; backward offset into the window

	push esi		; save esi, we'll need to go back there later!
	mov esi, edi		; Point esi at our current writing destination, then move
	sub esi, ebx		; back as many bytes as the offset tells us to

	rep movsb		; Now just loop and copy up to 16 times
	
	pop esi
	jmp ebu_symbol_done
ebu_write_raw:
	push ax			; simple copy finction for 8 bit value goes here
	mov al, bl		; like, really simple
	stosb
	pop ax

ebu_symbol_done:
	cmp esi, main - 2	; If we're not past the compressed payload yet, 
	jl ebu_decode_symbol	; rinse and repeat from the top
	
	ret			; done, do whatever
	

PayloadLength			equ main - 2
WriteBuffer			equ $ + 0x20 ; Some distance for good measure ;)
