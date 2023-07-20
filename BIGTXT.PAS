unit BIGTXT;

interface

uses crt;

procedure BigLost;
procedure BigWon;

implementation

type stringtyp = string[10];

Procedure Bigtext(x,y:integer; chr:char) ;
var Table : array[0..127,0..7] of byte absolute $ffa6:$e;
    i,
    b : integer;
    Zeile : byte;
    c : byte;

begin
  x := x*8;
  y := y*8;
  for i := 0 to 7 do
    begin
      Zeile := Table[ord(chr),i];
      gotoxy(x+1,y+1+i);
      for b := 0 to 7 do
       begin
         c := 128 shr b;
         if (zeile and c) = c then
             write('Û')
         else
             write(' ');

       end;
    end;
end;

Procedure bigwrite(x,y:integer; zeile:stringtyp);
var i,xx : integer;
begin
  for i := 1 to length(zeile) do
    begin
      xx := x+i;
      bigtext(xx-1,y,zeile[i]);
    end;
end;

procedure BigLost;
begin
  textcolor(7);
  textbackground(4);
  Clrscr;
  bigwrite(0,0,'----------');
  textcolor(14);
  bigwrite(1,1,'YOU LOST');
  textcolor(7);
  bigwrite(0,2,'----------');
  delay(500);
  repeat until keypressed;
  textbackground(0);
  textcolor(7);
  ClrScr;
end;

procedure BigWon;
begin
  textcolor(15);
  textbackground(1);
  Clrscr;
  bigwrite(0,0,'----------');
  textcolor(14+16);
  bigwrite(1,1,'YOU WON!');
  textcolor(15);
  bigwrite(0,2,'----------');
  textcolor(15);
  delay(500);
  repeat until keypressed;
  textbackground(0);
  textcolor(7);
  ClrScr;
end;

begin
end.
