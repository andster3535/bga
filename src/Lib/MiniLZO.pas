(*
  http://www.delphi3000.com/articles/article_3024.asp?SK=DLL
*)

unit MiniLZO;

interface

uses
  Windows;

// "C" routines needed by the linked LZO OBJ file

{$LINK 'minilzo.obj'}


(*
Error codes for the compression/decompression functions. Negative
values are errors, positive values will be used for special but
normal events.
*)

const

LZO_E_OK                 = 0;
LZO_E_ERROR              = -1;
LZO_E_OUT_OF_MEMORY      = -2;    (* not used right now *)
LZO_E_NOT_COMPRESSIBLE   = -3;    (* not used right now *)
LZO_E_INPUT_OVERRUN      = -4;
LZO_E_OUTPUT_OVERRUN     = -5;
LZO_E_LOOKBEHIND_OVERRUN = -6;
LZO_E_EOF_NOT_FOUND      = -7;
LZO_E_INPUT_NOT_CONSUMED = -8;


implementation


procedure _memset(s: Pointer; c: Byte; n: Integer); cdecl;


end.