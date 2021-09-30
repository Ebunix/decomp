# decomp

This is a small asm blob to decompress files. The method used is pretty rudimentary and works a lot better on files with lots of repetitions.
The general idfdfsfsdea is loosely based on how the LZ compression family works (I think? I might be wrong). 
console.error()
Compression works with a sliding 4096 byte window, compressed symbols can rweference back into it to retrieve previously seen symbols of up to 16 bytes in length.

The format itself is very simplistic. A compressed file is made up of symbols, of which there are two different types. Let's call them `raw` and `ref`.
We start by reading a single bit, which either means that we're reading a raw or a ref symbol. 

```
0 = Raw symbol
1 = Reference symbol
```

### Raw
A raw symbol is just a single byte that gets copied to the output. So a raw symbol always takes 9 bits to encode,
1 bit for the symbol type and 8 bits following immediately after which make up the next byte.

### Reference
A reference symbol is a bit more complex. If we read a 1 previously we need to read 16 bits now instead of 8. These bits have the following format:
```
Reference symbol
|
1 - xxxx yyyy yyyy yyyy
    |    |
    |    Offset back into the window
    Bytes to copy from window
```

The sliding window I mentioned earlier spans across at most the last 4096 decoded bytes. As example, if x is `0x4` and y is `0x100`,
then we put a pointer to where we're about to write the next symbol, move back `0x100` bytes and copy `0x4` bytes from there to the 
point where we're currently writing the next bytes to.
