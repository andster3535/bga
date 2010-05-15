(* ***** BEGIN LICENSE BLOCK *****
 * Version: GNU GPL 2.0
 *
 * The contents of this file are subject to the
 * GNU General Public License Version 2.0; you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * http://www.gnu.org/licenses/gpl.html
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is RFALib (http://code.google.com/p/bga)
 *
 * The Initial Developer of the Original Code is
 * Yann Papouin <yann.papouin at @ gmail.com>
 *
 * ***** END LICENSE BLOCK ***** *)

unit RFALib;

interface

{.$DEFINE DEBUG_RFA}
{$DEFINE USE_BUFFER}

uses
  DbugIntf, Windows, Classes, SysUtils, Contnrs;

type

  TRFAOperation =
  (
    roBegin,
    roEnd,
    roLoad,
    roSave,
    roInsert,
    roCompress,
    roExport,
    roDecompress,
    roDelete
  );

  TRFAFile = class;

  TRFAReadEntry = procedure(Sender : TRFAFile; Name: AnsiString; Offset, ucSize: Int64; Compressed : boolean; cSize : integer) of object;
  TRFAProgress = procedure(Sender : TRFAFile; Operation : TRFAOperation; Value : Integer) of object;

  TRFAResult = record
    offset : integer;
    size : integer;
  end;

  TRFAFile = class(TObject)
  private
    FLargeBuf : TMemoryStream;
    FHandle : TStream;
    FOnReadEntry: TRFAReadEntry;

    FFilepath: string;
    FCount: integer;
    FOnProgress: TRFAProgress;
    FIndexedDataSize: integer;
    procedure SetOnReadEntry(const Value: TRFAReadEntry);

    function ReadHeader : boolean;
    function GetDataSize: LongWord;
    function GetElementQuantity: LongWord;
    procedure SetDataSize(const Value: LongWord);
    procedure SetElementQuantity(const Value: LongWord);

    procedure Release;
    procedure SetOnProgress(const Value: TRFAProgress);
    function GetFragmentation: Integer;
  protected
    function DeleteData(Buf : TMemoryStream; Offset : int64; Size : int64) : TRFAResult; overload;
    function DeleteData(Offset : int64; Size : int64) : TRFAResult; overload;
    function InsertData(Data : TStream; Offset : Int64) : TRFAResult;
    function InsertDataCompressed(Data : TStream; Offset : Int64) : TRFAResult;
    procedure ReplaceData(Data : TStream; Offset : Int64; OldSize : int64);
  public
    constructor Create;
    destructor Destroy; override;

    function New(Filename: string): integer;
    function Open(Filename: string): integer;

    procedure DecompressToStream(outputstream: TStream; Offset, Size: int64; silent: boolean = true);
    procedure ExtractToStream(Data: TStream; Offset, Size, UcSize: int64);

    function DeleteFile(Offset : int64; Size : int64) : TRFAResult;
    function DeleteEntry(FullPath : AnsiString) : TRFAResult;
    function InsertFile(Data : TStream; Compressed : boolean = false) : TRFAResult;
    procedure InsertEntry(FullPath : AnsiString; Offset, Size : Int64; cSize : Int64; Index : Cardinal);
    procedure UpdateEntry(FullPath : AnsiString; NewOffset, NewUcSize, NewCSize : int64);

    property DataSize : LongWord read GetDataSize write SetDataSize;
    property ElementQuantity : LongWord read GetElementQuantity write SetElementQuantity;

    property Filepath : string read FFilepath;
    property Count : integer read FCount;

    property IndexedDataSize : Integer read FIndexedDataSize;
    property Fragmentation : Integer read GetFragmentation;

    property OnReadEntry: TRFAReadEntry read FOnReadEntry write SetOnReadEntry;
    property OnProgress: TRFAProgress read FOnProgress write SetOnProgress;
  end;


const
  PG_NULL = 0;
  PG_DEFAULT = -1;
  PG_SAME = -2;
  PG_AUTO = -3;
  NORMAL_DATA = false;
  COMPRESSED_DATA = true;

implementation

uses
  Math, CommonLib, MiniLZO;

const
  MAX_FILE_COUNT = 65535;
  MAX_SEGMENT_COUNT = 1024;
  HEADER_SIZE = 28;
  ENTRY_SIZE = 24;
  DWORD_SIZE = 4;
  INIT_DATA_SIZE = $9C;
  SEGMENT_HEADER_SIZE = DWORD_SIZE*3;
  BUFFER_SIZE = 8192;
  SEGMENT_MAX_SIZE = 32768;
  VERSION_HEADER = 'Refractor2 FlatArchive 1.1  ';
  LZO1X_1_MEM_COMPRESS = 16384 * 4;

(*
RFA File format description
|==============================================
|-RFA_Header (6 Words [Exists only in DEMO])
|
|-RFA_DataSize (2 Words)
   |
   |-RFA_DATA  (each RFA_DATA has its own size)
   |-RFA_DATA
   |-RFA_DATA
   |-RFA_DATA
   |-...
   |-...
   |-...
   |-RFA_DATA
   |-RFA_DATA
   |-RFA_DATA
   |-RFA_DATA  -> At the end of this part, total raw data = RFA_DataSize

|-Element_Quantity (2 Words)
   |
   |-RFA_Entry (each entry has a fixed length of 12 words)
      |
      |-csize   (2 Words)
      |-ucsize  (2 Words)
      |-offset  (2 Words)
      |-dummy0  (2 Words)
      |-dummy1  (2 Words)
      |-dummy2  (2 Words)

   |-RFA_Entry
   |-RFA_Entry
   |-RFA_Entry
   |-RFA_Entry
   |-...
   |-...
   |-...
   |-RFA_Entry
   |-RFA_Entry
   |-RFA_Entry
 __|-RFA_Entry
|==============================================
*)

// -------------------------------------------------------------------------- //
// Battlefield 1942 .RFA support ============================================ //
// -------------------------------------------------------------------------- //

type
    pRFA_Entry = ^RFA_Entry;
    RFA_Entry = packed record
      csize: integer;
      ucsize: integer;
      offset: integer;
      unknown: array[0..2] of integer;
    end;

    pRFA_DataHeader = ^RFA_DataHeader;
    RFA_DataHeader = packed record
      csize: longword;
      ucsize: longword;
      doffset: longword;
    end;


function StringFrom(AStream: TStream): AnsiString;
var
  Size: Cardinal;
begin
  AStream.Read(Size,4);   // Read string length (stored in a 32bits value)
  if Size > 255 then
  begin
    Size := 0;
    Result := EmptyStr;
    //raise Exception.Create('Max AnsiString size is 255');
  end
    else
  begin
    try
      SetLength(Result, Size);
      AStream.Read(Result[1], Size);
    finally

    end;
  end;
end;

{ TRFAFile }

constructor TRFAFile.Create;
begin
  inherited;
  FLargeBuf := TMemoryStream.Create;
  Release;
end;

destructor TRFAFile.Destroy;
begin
  Release;

  if Assigned(FLargeBuf) then
    FLargeBuf.Free;

  inherited;
end;

procedure TRFAFile.Release;
begin
  if Assigned(FHandle) then
    FHandle.Free;

  FHandle := nil;
  FIndexedDataSize := 0;
  FCount := 0;
  FFilepath := EmptyStr;
end;


function TRFAFile.New(Filename: string): integer;
var
  Value : longword;
begin
  Result := -1;
  Release;

  try
    FHandle := TFileStream.Create(Filename, fmOpenReadWrite or fmCreate);
  except
    on e:exception do
    begin
      FreeAndNil(FHandle);
      Result := -3;
    end;
  end;

  if Assigned(FHandle) then
  begin
    FHandle.Size := INIT_DATA_SIZE + DWORD_SIZE;
    DataSize := INIT_DATA_SIZE;
    ElementQuantity := 0;

    Result := 0;
    FFilepath := Filename;

    {$IfDef DEBUG_RFA}
    SendDebugFmt('New RFA (%s) = %d bytes',[FFilepath, FHandle.Size]);
    {$EndIf}
  end;
end;



function TRFAFile.Open(Filename: string): integer;
var
  ENT: RFA_Entry;
  Path: AnsiString;
  i: integer;
  Position : integer;
  IsRetail: boolean;
begin
  Release;

  try
    Fhandle := TFileStream.Create(Filename, fmOpenReadWrite);
  except
    on e:exception do
    try
      FHandle.Free;
      Fhandle := TFileStream.Create(Filename, fmOpenRead);
      Result := -1;
    except
      FHandle.Free;
      Result := -3;
    end;
  end;

  if Assigned(FHandle) then
  begin
    IsRetail := ReadHeader;
    FCount := ElementQuantity;
    FIndexedDataSize := 0;

    if FCount > MAX_FILE_COUNT then
      raise Exception.Create('File Count seems too high');

    if Assigned(FOnProgress) then
      FOnProgress(Self, roBegin, FHandle.Size);

    for i:= 1 to FCount do
    begin
      Position := FHandle.Position;

      Path := StringFrom(FHandle);      // Read entire Path\Filename
      FHandle.Read(ENT, ENTRY_SIZE);    // Read rfa entry data (24 bytes);

      FIndexedDataSize := FIndexedDataSize + ENT.csize;

      if Assigned(FOnProgress) then
        FOnProgress(Self, roLoad, FHandle.Position);

      if Assigned(FOnReadEntry) then
      begin

        if IsRetail then
        begin
          if (ENT.ucsize = ENT.csize) then
            FOnReadEntry(Self, Path, ENT.offset, ENT.ucsize, NORMAL_DATA, ENT.ucsize)
          else
            FOnReadEntry(Self, Path, ENT.offset, ENT.ucsize, COMPRESSED_DATA, ENT.csize)
        end
          else
        begin
          FOnReadEntry(Self, Path, ENT.offset, ENT.ucsize, false, 0);
        end;
      end;
    end;

    if Assigned(FOnProgress) then
      FOnProgress(Self, roEnd, 0);

    Result := 0;
    FFilepath := Filename;
  end;

end;


// Quicker if ReAllocated size of Buf is near the last one
function TRFAFile.DeleteData(Buf: TMemoryStream; Offset, Size: int64): TRFAResult;
var
  NewSize : Int64;
begin
  Assert(Offset+Size <= FHandle.Size, 'Out of range');

  // Put final data in Buf
  FHandle.Seek(Offset+Size, soBeginning);
  NewSize := FHandle.Size - FHandle.Position;
  Buf.Size := NewSize;
  Buf.Seek(0, soBeginning);
  Buf.CopyFrom(FHandle, Buf.Size);

  // Write back shifted data into stream
  Buf.Seek(0, soBeginning);
  FHandle.Size := FHandle.Size - Size;
  FHandle.Seek(Offset, soBeginning);
  FHandle.CopyFrom(Buf, Buf.Size);

  Result.offset := Offset;
  Result.size := Size;

end;


function TRFAFile.DeleteData(Offset, Size: int64): TRFAResult;
var
  Buf : TMemoryStream;
begin
  Buf := TMemoryStream.Create;
  Result := DeleteData(Buf, Offset, Size);
  Buf.Free;
end;

function TRFAFile.InsertData(Data: TStream; Offset: Int64): TRFAResult;
var
  Buf : TMemoryStream;
  {$IfDef USE_BUFFER}
  i, BufferCount, FlakedBuffer: Integer;
  {$EndIf}
begin
  Buf := TMemoryStream.Create;

  FHandle.Seek(Offset, soBeginning);

  // Put final data in Buf
  Buf.Size := FHandle.Size - FHandle.Position;
  Buf.Seek(0, soBeginning);
  Buf.CopyFrom(FHandle, Buf.Size);

  // Expand current archive
  FHandle.Size := FHandle.Size + Data.Size;

  if Assigned(FOnProgress) then
    FOnProgress(Self, roBegin, Data.Size + Buf.Size);

  // Write the new data
  Data.Seek(0, soBeginning);
  FHandle.Position := Offset;
  {$IfDef USE_BUFFER}
    BufferCount := Data.Size div BUFFER_SIZE;
    FlakedBuffer := Data.Size mod BUFFER_SIZE;

    for i := 1 to BufferCount do
    begin
      FHandle.CopyFrom(Data, BUFFER_SIZE);

      if Assigned(FOnProgress) then
        FOnProgress(Self, roInsert, Data.Position);
    end;
    if FlakedBuffer > 0 then
      FHandle.CopyFrom(Data, FlakedBuffer);
  {$Else}
    FHandle.CopyFrom(Data, Data.Size);
  {$EndIf}

  // Write back shifted data
  Buf.Seek(0, soBeginning);
  {$IfDef USE_BUFFER}
    BufferCount := Buf.Size div BUFFER_SIZE;
    FlakedBuffer := Buf.Size mod BUFFER_SIZE;

    for i := 1 to BufferCount do
    begin
      FHandle.CopyFrom(Buf, BUFFER_SIZE);

      if Assigned(FOnProgress) then
        FOnProgress(Self, roInsert, Data.Position + Buf.Position);
    end;
    if FlakedBuffer > 0 then
      FHandle.CopyFrom(Buf, FlakedBuffer);
  {$Else}
    FHandle.CopyFrom(Buf, Buf.Size);
  {$EndIf}

  if Assigned(FOnProgress) then
    FOnProgress(Self, roEnd, 0);

  Buf.Free;

  // The result is the offset position of the file and its size
  Result.offset := Offset;
  Result.size := Data.Size;
end;

function TRFAFile.InsertDataCompressed(Data: TStream; Offset: Int64): TRFAResult;
var
  WBuff: PByteArray; // Working buffer
  SBuff: PByteArray; // Source buffer
  OBuff: PByteArray; // Output buffer
  DataH: RFA_DataHeader;
  SegmentHeader, SegmentData : TMemoryStream;
  RemainingSize : integer;
  CompressedSize : cardinal;
  LzoResult : integer;
  SegmentCounter : longword;
  Buf : TMemoryStream;
  PreviousPos : integer;
  {$IfDef USE_BUFFER}
  i, BufferCount, FlakedBuffer: Integer;
  {$EndIf}
begin

  SegmentCounter := 0;
  Data.Position := 0;

  SegmentData := TMemoryStream.Create;
  SegmentData.Size := 0;

  SegmentHeader := TMemoryStream.Create;
  SegmentHeader.Size := 0;
  SegmentHeader.Write(SegmentCounter, DWORD_SIZE);

  {We want to compress the data block at `in' with length `IN_LEN' to
  the block at `out'. Because the input block may be incompressible,
  we must provide a little more output space in case that compression
  is not possible.}

  GetMem(SBuff, SEGMENT_MAX_SIZE);
  GetMem(OBuff, SEGMENT_MAX_SIZE + SEGMENT_MAX_SIZE div 64 + 16 + 3);
  GetMem(WBuff, LZO1X_1_MEM_COMPRESS);

  if Assigned(FOnProgress) then
    FOnProgress(Self, roBegin, Data.Size);

  while True do
  begin
    // Write a new segment in the source buffer
    RemainingSize := Min(SEGMENT_MAX_SIZE, Data.Size - Data.Position);

    //FillChar(SBuff^, SEGMENT_MAX_SIZE, #0);
    Data.Read(SBuff^, RemainingSize);
   // Data.Position := Data.Position + RemainingSize; // Position need to be set manually on TFileStream

    // Compress the new segment
    LzoResult := _lzo1x_1_compress(SBuff, RemainingSize, OBuff, CompressedSize, WBuff);

    // Add compressed segment with others
    if LzoResult = LZO_E_OK then
    begin
      SegmentData.Write(OBuff^, CompressedSize);
      Inc(SegmentCounter);

      if SegmentCounter = 1 then
        DataH.doffset := 0
      else
        DataH.doffset := DataH.doffset + DataH.csize;

      DataH.csize := CompressedSize;
      DataH.ucsize := RemainingSize;

      {$IfDef DEBUG_RFA}
      SendSeparator;
      SendDebugFmt('RFAInsertDataCompressed::SegmentCounter=%d',[SegmentCounter]);
      SendDebugFmt('RFAInsertDataCompressed::DataH.csize=%d',[DataH.csize]);
      SendDebugFmt('RFAInsertDataCompressed::SegmentData.size=%d',[DataH.ucsize]);
      {$EndIf}

      SegmentHeader.Write(DataH.csize,DWORD_SIZE);
      SegmentHeader.Write(DataH.ucsize,DWORD_SIZE);
      SegmentHeader.Write(DataH.doffset,DWORD_SIZE);
    end;

    if Assigned(FOnProgress) then
      FOnProgress(Self, roCompress, Data.Position);

    if (Data.Size = Data.Position) then
    begin
      SegmentHeader.Position := 0;
      SegmentHeader.Write(SegmentCounter, DWORD_SIZE);
      Break;
    end;
  end;

  if Assigned(FOnProgress) then
    FOnProgress(Self, roEnd, 0);

  FreeMem(WBuff); WBuff:= nil;
  FreeMem(OBuff); OBuff:= nil;
  FreeMem(SBuff); SBuff:= nil;

  // Finally wrote full data
  Buf := TMemoryStream.Create;
  FHandle.Seek(Offset, soBeginning);

  // Put final data in Buf
  Buf.Size := FHandle.Size - FHandle.Position;
  Buf.Seek(0, soBeginning);
  Buf.CopyFrom(FHandle, Buf.Size);

  // Expand current archive
  FHandle.Size := FHandle.Size + SegmentHeader.Size + SegmentData.Size;

  // Write the new data
  SegmentHeader.Seek(0, soBeginning);
  SegmentData.Seek(0, soBeginning);
  FHandle.Position := Offset;
  FHandle.CopyFrom(SegmentHeader, SegmentHeader.Size);

  if Assigned(FOnProgress) then
    FOnProgress(Self, roBegin, SegmentData.Size+Buf.Size);

  {$IfDef USE_BUFFER}
    BufferCount := SegmentData.Size div BUFFER_SIZE;
    FlakedBuffer := SegmentData.Size mod BUFFER_SIZE;

    for i := 1 to BufferCount do
    begin
      FHandle.CopyFrom(SegmentData, BUFFER_SIZE);

      if Assigned(FOnProgress) then
        FOnProgress(Self, roCompress, SegmentData.Position);
    end;
    if FlakedBuffer > 0 then
      FHandle.CopyFrom(SegmentData, FlakedBuffer);
  {$Else}
    FHandle.CopyFrom(SegmentData, SegmentData.Size);
  {$EndIf}

  // Write back shifted data
  Buf.Seek(0, soBeginning);
  {$IfDef USE_BUFFER}
    BufferCount := Buf.Size div BUFFER_SIZE;
    FlakedBuffer := Buf.Size mod BUFFER_SIZE;

    for i := 1 to BufferCount do
    begin
      FHandle.CopyFrom(Buf, BUFFER_SIZE);

      if Assigned(FOnProgress) then
        FOnProgress(Self, roCompress, SegmentData.Position + Buf.Position);
    end;
    if FlakedBuffer > 0 then
      FHandle.CopyFrom(Buf, FlakedBuffer);
  {$Else}
    FHandle.CopyFrom(Buf, Buf.Size);
  {$EndIf}

  Buf.Free;

  if Assigned(FOnProgress) then
    FOnProgress(Self, roEnd, 0);

  // The result is the offset position of the file and its size
  Result.offset := Offset;
  Result.size := SegmentHeader.Size + SegmentData.Size;

  {$IfDef DEBUG_RFA}
  SendSeparator;
  SendDebugFmt('RFAInsertDataCompressed::SegmentHeader.size=%d',[SegmentHeader.size]);
  SendDebugFmt('RFAInsertDataCompressed::SegmentData.size=%d',[SegmentData.size]);
  SendDebugFmt('RFAInsertDataCompressed::SegmentCounter=%d',[SegmentCounter]);
  SendDebugFmt('RFAInsertDataCompressed::Result.offset=%d',[Result.offset]);
  SendDebugFmt('RFAInsertDataCompressed::Result.size=%d',[Result.size]);
  {$EndIf}

  SegmentHeader.Free;
  SegmentData.Free;
end;


procedure TRFAFile.ReplaceData(Data: TStream; Offset, OldSize: int64);
begin
  DeleteData(Offset, OldSize);
  InsertData(Data, Offset);
end;

procedure TRFAFile.DecompressToStream(outputstream: TStream; Offset, Size: int64; silent: boolean);
var
  SBuff: PByteArray;
  OBuff: PByteArray;
  Result: integer;

  DataH: array of RFA_DataHeader;
  i, Segments: longword;
begin
  Assert(Assigned(outputstream));

  // Reinit variables;
  SetLength(DataH,0);
  Segments := 0;

  // A compressed file is made of multi-segment

  // Reading quantity of segment for this file
  FHandle.Seek(offset,0);
  FHandle.Read(segments,DWORD_SIZE);

  if segments > MAX_SEGMENT_COUNT then
    raise Exception.Create('Segment Count seems too high');

  // Creating as much as Data header than segments
  {$IfDef DEBUG_RFA}
  SendDebugFmt('Setting DataH length to %d', [Segments]);
  {$EndIf}
  SetLength(DataH,Segments);

  if Assigned(FOnProgress) then
    FOnProgress(Self, roBegin, (Segments-1)*2);

  // Filling each header with usable values
  for i := 0 to Segments-1 do
  begin
    FHandle.Read(DataH[i].csize,DWORD_SIZE);
    FHandle.Read(DataH[i].ucsize,DWORD_SIZE);
    FHandle.Read(DataH[i].doffset,DWORD_SIZE);

    {$IfDef DEBUG_RFA}
    SendDebugFmt('DecompressRFAToStream::FHandle.Position = %d', [FHandle.Position]);
    SendDebugFmt('DecompressRFAToStream::Segment No_%d (%d)(%d)(%d)', [i, DataH[i].csize, DataH[i].ucsize, DataH[i].doffset]);
    {$EndIf}

    if Assigned(FOnProgress) then
      FOnProgress(Self, roDecompress, PG_AUTO);
  end;

  {$IfDef DEBUG_RFA}
  SendDebugFmt('DecompressRFAToStream::Start', []);
  {$EndIf}


  for i := 0 to Segments-1 do
  begin

    GetMem(SBuff, DataH[i].csize);
    GetMem(OBuff, DataH[i].ucsize);

    FHandle.Seek(Offset+(segments*SEGMENT_HEADER_SIZE)+DataH[i].doffset+DWORD_SIZE,0);

    {$IfDef DEBUG_RFA}
    SendDebugFmt('DecompressRFAToStream::FHandle.Position = %d', [FHandle.Position]);
    {$EndIf}
		FHandle.Read(SBuff^,DataH[i].csize);

    Result := _lzo1x_decompress_safe(SBuff, DataH[i].csize, OBuff, DataH[i].ucsize, nil);

    if Result <> LZO_E_OK then
    begin
      raise Exception.Create('not LZO_E_OK');

      FreeMem(SBuff);
      FreeMem(OBuff);
      Break;
    end;

    outputstream.WriteBuffer(OBuff^, DataH[i].ucsize);
    FreeMem(SBuff);
    FreeMem(OBuff);

    if Assigned(FOnProgress) then
      FOnProgress(Self, roDecompress, PG_AUTO);
  end;

  if Assigned(FOnProgress) then
    FOnProgress(Self, roEnd, 0);
end;

procedure TRFAFile.ExtractToStream(Data: TStream; Offset, Size, UcSize: int64);
var
  Buffer : TMemoryStream;
  {$IfDef USE_BUFFER}
  i, BufferCount, FlakedBuffer: Integer;
  {$EndIf}
begin
  Assert(Assigned(Data));

  Buffer := TMemoryStream.Create;
  Buffer.Size := Size;
  Buffer.Seek(0, soFromBeginning);
  //Data.Seek(0, soFromBeginning);
  FHandle.Seek(Offset, soFromBeginning);

  {$IfDef USE_BUFFER}
    BufferCount := Size div BUFFER_SIZE;
    FlakedBuffer := Size mod BUFFER_SIZE;

    for i := 1 to BufferCount do
    begin
      Buffer.CopyFrom(FHandle, BUFFER_SIZE);
    end;
    if FlakedBuffer > 0 then
      Buffer.CopyFrom(FHandle, FlakedBuffer);
  {$Else}
    Buffer.CopyFrom(FHandle, Size);
  {$EndIf}

  Buffer.Seek(0, soFromBeginning);

  {$IfDef DEBUG_RFA}
  SendDebugFmt('Buffer size = %d',[Buffer.Size]);
  {$EndIf}

  Buffer.SaveToStream(Data);
  Buffer.Free;
end;


function TRFAFile.DeleteFile(Offset, Size: int64): TRFAResult;
begin
  {$IfDef DEBUG_RFA}
  SendDebugFmt('Delete file at 0x%.8x with a size of %d',[Offset, Size]);
  {$EndIf}

  Result := DeleteData(FLargeBuf, Offset, Size);
  DataSize := DataSize - Size;
end;

function TRFAFile.DeleteEntry(FullPath: AnsiString): TRFAResult;
var
  ENT: RFA_Entry;
  Path: AnsiString;
  i: integer;
  Offset, DataOffset : Int64;
  Size, DataSize : Int64;
begin
  {$IfDef DEBUG_RFA}
  SendDebugFmt('Delete entry %s',[FullPath]);
  {$EndIf}

  Offset := 0;
  Size := 0;
  DataOffset := 0;
  DataSize := 0;

  FCount := ElementQuantity;

  if FCount > MAX_FILE_COUNT then
    raise Exception.Create('File Count seems too high');

  // Search the wanted entry
  for i:= 1 to FCount do
  begin
    Offset := FHandle.Position;
    Path := StringFrom(FHandle);
    FHandle.Read(ENT, ENTRY_SIZE);

    Size := FHandle.Position - Offset;

    if Path = FullPath then
    begin
      DataOffset := ENT.offset;
      DataSize := ENT.csize;
      FIndexedDataSize := FIndexedDataSize - ENT.csize;
      Break;
    end;

    if i = FCount then
      raise Exception.Create('Path not found');
  end;

  // Delete this entry if data found
  if DataSize > 0 then
  begin
    Result := DeleteData(Offset, Size);
    ElementQuantity := ElementQuantity-1;
    FCount := ElementQuantity;
  end;
end;

procedure TRFAFile.InsertEntry(FullPath: AnsiString; Offset, Size, cSize: Int64; Index: Cardinal);
var
  Buf : TMemoryStream;
  Len : LongWord;
  ENT: RFA_Entry;
  Path: AnsiString;
  i: integer;
begin
  Len := Length(FullPath);
  ENT.offset := Offset;
  ENT.csize := cSize;
  ENT.ucsize := Size;

  FIndexedDataSize := FIndexedDataSize + ENT.csize;

  Buf := TMemoryStream.Create;
  Buf.Size := DWORD_SIZE + Len + ENTRY_SIZE;
  Buf.Seek(0, soFromBeginning);

  Buf.Write(Len, DWORD_SIZE);
  Buf.Write(FullPath[1], Len);
  Buf.Write(ENT, ENTRY_SIZE);

  FCount := ElementQuantity;

  if FCount > MAX_FILE_COUNT then
    raise Exception.Create('File Count seems too high');

  if (Index = 0) or (Index > FCount) then
    Index := FCount;

  for i:= 1 to FCount do
  begin
    Path := StringFrom(FHandle);
    FHandle.Read(ENT, ENTRY_SIZE);

    if Index = i then
      Break;
  end;

  InsertData(Buf, FHandle.Position);
  ElementQuantity := ElementQuantity+1;
  FCount := ElementQuantity;

  Buf.Free;
end;


function TRFAFile.InsertFile(Data: TStream; Compressed: boolean): TRFAResult;
var
  CurrentSize : cardinal;
begin
  CurrentSize := DataSize;

  if Compressed then
  begin
    {$IfDef DEBUG_RFA}
    SendDebugFmt('RFAInsertFile::Data.Size=%d',[Data.Size]);
    {$EndIf}
    Result := InsertDataCompressed(Data, CurrentSize);
  end
    else
  begin
    Result := InsertData(Data, CurrentSize);
  end;

  Assert(Result.offset <> 0);
  DataSize := CurrentSize + Result.size;
end;

procedure TRFAFile.UpdateEntry(FullPath: AnsiString; NewOffset, NewUcSize, NewCSize: int64);
var
  ENT: RFA_Entry;
  Path: AnsiString;
  i: integer;
begin
  FCount := ElementQuantity;

  if FCount > MAX_FILE_COUNT then
    raise Exception.Create('File Count seems too high');

  // Search the wanted entry
  for i:= 1 to FCount do
  begin
    Path := StringFrom(FHandle);
    FHandle.Read(ENT, ENTRY_SIZE);

    if Path = FullPath then
    begin
      FIndexedDataSize := FIndexedDataSize + NewCSize - Ent.csize;
      ENT.offset := NewOffset;
      ENT.ucsize := NewUcSize;
      Ent.csize := NewCSize;
      FHandle.Position := FHandle.Position - ENTRY_SIZE;
      FHandle.Write(ENT, ENTRY_SIZE);
      Break;
    end;

    if i = FCount then
      raise Exception.Create('Path not found');
  end;
end;



// Jump to header, return true if we are using the retail format (not the demo one)
function TRFAFile.ReadHeader: boolean;
var
  ID: array[0..27] of AnsiChar;
begin
  Result := false;
  FHandle.Position := 0;

  if FHandle.Size >= HEADER_SIZE then
    FHandle.Read(ID, HEADER_SIZE);

  if ID <> VERSION_HEADER then
  begin
    FHandle.Position := 0;
    Result := true;
  end;
end;


function TRFAFile.GetDataSize: LongWord;
begin
  ReadHeader;

  {$IfDef DEBUG_RFA}
  SendDebugFmt('Reading data size at 0x%x',[FHandle.Position]);
  {$EndIf}

  FHandle.Read(Result, DWORD_SIZE);   // Read data length (32bits)

  {$IfDef DEBUG_RFA}
  SendDebugFmt('Data size == %s',[SizeToStr(Result)]);
  {$EndIf}
end;


procedure TRFAFile.SetDataSize(const Value: LongWord);
begin
  ReadHeader;
  FHandle.Write(Value, DWORD_SIZE);     // write data Size (32bits)
  {$IfDef DEBUG_RFA}
  SendDebugFmt('New Data size == %s',[SizeToStr(Value)]);
  {$EndIf}
end;

function TRFAFile.GetElementQuantity: LongWord;
begin
  FHandle.Seek(DataSize, soBeginning);  // Jump segment
  {$IfDef DEBUG_RFA}
  SendDebugFmt('Reading element quantity at 0x%x',[FHandle.Position]);
  {$EndIf}
  FHandle.Read(Result, DWORD_SIZE);           // Read element quantity (32bits)
  {$IfDef DEBUG_RFA}
  SendDebugFmt('Element quantity == %d',[Result]);
  {$EndIf}
end;


procedure TRFAFile.SetElementQuantity(const Value: LongWord);
begin
  FHandle.Seek(DataSize, soBeginning);  // Jump segment
  FHandle.Write(Value, DWORD_SIZE);     // write element quantity (32bits)
end;

function TRFAFile.GetFragmentation: Integer;
begin
  Result := DataSize - FIndexedDataSize - INIT_DATA_SIZE;
end;

procedure TRFAFile.SetOnProgress(const Value: TRFAProgress);
begin
  FOnProgress := Value;
end;

procedure TRFAFile.SetOnReadEntry(const Value: TRFAReadEntry);
begin
  FOnReadEntry := Value;
end;



end.