 {$I-}
 PROGRAM tetris;
 USES Crt,Dos,BigTXT;

 TYPE rec = RECORD
       r : ARRAY [0..9] OF Word;
       n : ARRAY [0..9] OF String [16]
      END;

 CONST cod : ARRAY [0..27] OF Word =
       (15,8738,15,8738,51,51,51,51,
        39,305,114,562,71,275,113,802,
        23,785,116,547,54,561,54,561,
        99,306,99,306);

 VAR ch,la : Char;
   pic : Word ABSOLUTE 0:$BDCA;
   fig : ARRAY [0..6,0..3,0..7] OF Byte;
   bit : rec;
   dat : File OF rec;
   spd : Real;
   fi:text;
   elin,oldlin,lin,a,b,c,d,e,f,g,h : Word;
   oldy,r,s1,t,x,y,z,id : Shortint;
   st,lt,Snake,olds,s,myChannel,cChannel,eChannel:string;
   TempI,SnakeCounter,LastMsg,i,li,si:integer;
   DEL,Net,master,isquit:Boolean;
   DirInfo: SearchRec;

procedure CMDHelp;
begin
textcolor(7);
textbackground(0);
ClrScr;
writeln;
writeln('TETRIS v1.0');
writeln('(c)1997 SDT');
writeln;
writeln('SYNTAX: TETRIS <network-path> <your name (max. 8 chars)>');
writeln('    or: TETRIS -1   (for a single player game)');
writeln;
writeln('This is a network version of the classic arcade game, TETRIS.');
writeln('The rules are simple: Complete as many lines as possible.');
writeln('As sson as you one or more lines, they`ll disappear. Your Opponent');
writeln('will receive as many additional lines as you complete!! Watch out! ;-)');
writeln;
writeln('What`s needed to play? First, you must have read/write access to a');
writeln('shared network directory (a directory on the server). Every player');
writeln('needs R/W-access to this specific directory. Let`s assume that your');
writeln('company`s poject-directory is "U:\PROJECTS" and everyone has access');
writeln('to it. Now you need a name (...) Let`s take "Lucy" for example.');
writeln('Now start the game with "TETRIS U:\PROJECTS Lucy". Voil†!');
writeln('Your game-mates should do the same (except for the name, of course)');
writeln('and TADAAA! Select your opponent from the userlist and get into it!');
writeln('');
writeln('If you want to play alone (no network) then just execute "TETRIS -1"');
writeln('');
repeat until keypressed;
halt(1);
end;


procedure Cursor_Off; Assembler;
asm
push ax
push cx
mov ah,01h
mov ch,20h
mov cl,20h
int 10h
pop ax
pop cx
end;

procedure Cursor_On; Assembler;
asm
mov ah,01h
mov cx,0607h
int 10h
end;

procedure PurgeChannel;
var sx,sy:integer;
begin;
  if NET then begin;
  sx:=wherex;sy:=wherey;gotoxy(75,1);
  textcolor(14);textbackground(4);
  write('PURGE');textcolor(7);textbackground(0);gotoxy(sx,sy);
  assign (fi, ParamStr(1)+'\' + cChannel+'.TET');
  {$I-} rewrite (fi); {$I+}
  if IORESULT<>0 then begin;
  sx:=wherex;sy:=wherey;gotoxy(75,1);write('     ');gotoxy(sx,sy);
   writeln;
   writeln ('ERROR: Couldn`t create a file in directory '+ParamStr(1));
   writeln ('       Make sure that it exists and you have read/write -access!');
   writeln;
  halt(1);
  end;
  {$I-} close(fi); {$I+}
  sx:=wherex;sy:=wherey;gotoxy(75,1);write('     ');gotoxy(sx,sy);
end;
end;

procedure PurgeMyChannel;
var sx,sy:integer;
begin;
  if NET then begin;
  sx:=wherex;sy:=wherey;gotoxy(75,1);
  textcolor(14);textbackground(4);
  write('PURGE');textcolor(7);textbackground(0);gotoxy(sx,sy);
  assign (fi, ParamStr(1)+'\' + myChannel+'.TET');
  {$I-} rewrite (fi); {$I+}
  {$I-} close(fi); {$I+}
  sx:=wherex;sy:=wherey;gotoxy(75,1);write('     ');gotoxy(sx,sy);
  if Del then erase(fi);
  end;
end;

procedure ListenChannel;
var i,sx,sy:integer;
begin;
  if NET then begin;
  sx:=wherex;sy:=wherey;gotoxy(76,1);textcolor(14);textbackground(4);write('BUSY');
  textcolor(7);textbackground(0);
  assign (fi, ParamStr(1)+'\' + cChannel+'.TET');
  {$I-} reset (fi); {$I+}
  i:=0;
  if IORESULT=0 then begin;
  if (not eof (fi)) then
  begin
    repeat
    inc(i);
    ReadLn (fi, s);
    until (i>LastMsg) or eof(fi);
  end;
  if s=olds then begin
  s:='';
  end
  else
  begin
  olds:=s;
  end;
  Close(Fi);
  LastMsg:=i;
  gotoxy(76,1);write('    ');gotoxy(sx,sy);
end;
end;
end;

procedure SendChannel(C:string);
var sx,sy:integer;
begin;
  if NET then begin;
  sx:=wherex;sy:=wherey;gotoxy(76,1);textcolor(15);textbackground(3);write('SEND');
  textcolor(7);textbackground(0);
  gotoxy(sx,sy);
  assign (fi, ParamStr(1)+'\' + cChannel+'.TET');
  {$I-} append (fi); {$I+}
  if IORESULT=0 then
  begin;
    Writeln (fi, c);
    Close(Fi);
    sx:=wherex;sy:=wherey;gotoxy(76,1);write('    ');gotoxy(sx,sy);
    s:=' ';
  end;
end;
end;

procedure Quit;
begin;
ClrScr;
DEL:=True;
PurgeMyChannel;
Cursor_On;
halt(0);
end;


procedure CheckWhoIsMaster;
begin;
  assign (fi, ParamStr(1)+'\'+echannel+'.TET');
  {$I-} reset (fi); {$I+}
  s:='';
  if (IORESULT=0) then begin;
   if not eof(fi) then readln(fi,s);
   if s='*' then begin; {Is there already a master?}
    master:=false;
    close(fi);
    assign (fi, ParamStr(1)+'\'+echannel+'.TET');
    {$I-} rewrite (fi); {$I+}
    writeln(fi,'˛'); {Yep, so send info that I'm Slave and Ready}
   end;
   close(fi);
  end;
  if s<>'*' then begin; {Else claim me to be Master.}
  assign (fi, ParamStr(1)+'\'+mychannel+'.TET');
  {$I-} rewrite (fi); {$I+}
  writeln(fi,'*');
  writeln(fi,eChannel);
  master:=TRUE;
  close(fi);
  end;
end;

procedure Handshake; {The Master calls this to check is his slave is ready}
begin;
SnakeCounter:=0;
repeat
  delay(500);
  assign (fi, ParamStr(1)+'\'+mychannel+'.TET');
  {$I-} reset (fi); {$I+}
  s:='';
  if (IORESULT=0) then begin;
   if not eof(fi) then readln(fi,s);
   inc(SnakeCounter); if SnakeCounter>25 then SnakeCounter:=1;
   case SnakeCounter of
     1  : Snake:='[-     -]';
     2  : Snake:='[=-   -=]';
     3  : Snake:='[=- -=]';
     4  : Snake:='[∞=-=∞]';
     5  : Snake:='[±∞=∞±]';
     6  : Snake:='[≤±∞∞±≤]';
     7  : Snake:='[€≤±∞±≤€]';
     8  : Snake:='[≤€≤±≤€≤]';
     9  : Snake:='[±≤€≤€≤±]';
     10 : Snake:='[∞±≤€≤±∞]';
     11 : Snake:='[ ∞±≤±∞ ]';
     12 : Snake:='[  ∞±∞  ]';
     13 : Snake:='[   ∞   ]';
     14 : Snake:='[       ]';
     15 : Snake:='[€      ]';
     16 : Snake:='[≤€     ]';
     17 : Snake:='[±≤€    ]';
     18 : Snake:='[∞±≤€   ]';
     19 : Snake:='[ ∞±≤€  ]';
     20 : Snake:='[  ∞±≤€ ]';
     21 : Snake:='[   ∞±≤€]';
     22 : Snake:='[    ∞±≤]';
     23 : Snake:='[     ∞±]';
     24 : Snake:='[      ∞]';
     25 : Snake:='[       ]';
   end;
   gotoxy(1,2);
   write(snake);
   close(fi);
  end;
  if keypressed then ch:=readkey;
until (s='˛') or (s='Quit') or (ord(ch)=27);
if (ord(ch)=27) or (s='Quit') then begin; Quit; end;
PurgeMyChannel;
end;

procedure SendLinesToEnemy(num:integer);
begin;
if Master then SendChannel('S');
if not Master then SendChannel('M');
str(num,s);
SendChannel(s);
end;


 PROCEDURE init;
 BEGIN
  Randomize;
  FOR a:=0 TO 27 DO BEGIN
   d:=0;
   FOR b:=0 TO 15 DO BEGIN
    IF cod [a] MOD 2=1 THEN BEGIN
     fig [a DIV 4,a MOD 4,d]:=b MOD 4*2;
     fig [a DIV 4,a MOD 4,d+1]:=b DIV 4;
     Inc (d,2)                          
    END;
    cod [a]:=cod [a] DIV 2
   END
  END;
  Assign (dat,'tetris.tbl');
  {$I-} Reset (dat); {$I+}
  IF IOresult<>0 THEN BEGIN
   Rewrite (dat);
   FOR a:=0 TO 9 DO BEGIN
    bit.r [a]:=0;
    bit.n [a]:=''
   END;
   Write (dat,bit)
  END ELSE Read (dat,bit);
  IF IOresult=0 THEN Close (dat)
 END;



 PROCEDURE rahmen;
 BEGIN
  TextBackground (0); TextColor (7);
  ClrScr; lin:=0;
  FOR a:=34 TO 55 DO Memw [pic:a*2]:=4060;
  FOR a:=34 TO 55 DO Memw [pic:a*2+3680]:=4063;
  FOR a:=1 TO 22 DO
   FOR b:=0 TO 1 DO Memw [pic:a*160+b*42+68]:=4059;

  if not net then begin;
   textcolor(14);
   gotoxy(2,6);writeln(' HI-SCORE TOP TEN');
   gotoxy(2,7);writeln(' ˛˛˛˛˛˛˛˛˛˛˛˛˛˛˛˛');
  textcolor(15);
  FOR a:=0 TO 9 DO BEGIN
   GotoXY (1,a+9);
   Write (bit.r [a]:5,'  ',bit.n [a])
  END;
  END;
  spd:=110;
  textcolor(11);
  GotoXY (1,1); Write ('ROWS: ');Write(lin);
  if net then begin;
  if eChannel<>'' then begin;GotoXY (1,2); Write ('ENEMY ROWS: ');Write(elin);end;
   textcolor(15);
   gotoxy(1,3);writeln('GAME: MULTIPLAYER');
  end;
  if not net then begin;
   textcolor(15);
   gotoxy(1,3);writeln('GAME: SINGLE PLAYER');
  end;
  if eChannel<>'' then begin;
  textcolor(10);
  GotoXY (1,5); Write ('Player  : ');Write(myChannel);
  textcolor(12);
  GotoXY (1,6); Write ('Opponent: ');Write(eChannel);
  end;
  textcolor(14);
  gotoxy(65,2);
  write('Preview:');
  textcolor(11);
  gotoxy(58,21);
  write('[SPACE] Rotate tile');
  gotoxy(58,22);
  write('[ARROW KEYS] Move tile');
  gotoxy(58,23);
  write('[DOWN ARROW] Throw down');
  gotoxy(58,24);
  write('[ESC] Quit TETRIS');
  textcolor(7);
 END;

procedure AddLines(num:integer);
var numcount:integer;
    oldc:integer;
begin
oldc:=c;
inc(elin,num);
if net then begin; GotoXY (1,2); Write ('ENEMY ROWS: '); Write(elin); end;
textcolor(7);
for numcount:=1 to num do begin;

 FOR a:=0 TO 3 DO         {Akt. Teil lîschen}
  FOR b:=0 TO 1 DO
   Memw [pic:(b+x+fig [r,z,a*2])*2+(y+fig [r,z,a*2+1])*160+226]:=0;

 for a:=2 to 21 do begin; {Alles eine Zeile rauf}
   c:=0;
   FOR b:=4 TO 43 DO IF Mem [pic:a*160+b*2+66]=219 THEN c:=1;
   if c=1 then FOR c:=4 TO 43 DO Mem [pic:a*160+c+66]:=Mem [pic:a*160+c+226]
 end;

 a:=35;
 repeat                 {Hier wird die letzte Zeile zufÑllig ausgefÅllt}
 c:=Random(6)+1;
 b:=Random(10);
 textcolor(c);
 inc(a);
 gotoxy(a,23);
 if b<=5 then write('€');
 if b>5 then write(' ');
 inc(a);
 gotoxy(a,23);
 if b<=5 then write('€');
 if b>5 then write(' ');
 until a>=55;
 textcolor(7);

 c:=oldc;
 FOR a:=0 TO 3 DO         {Akt. Teil wieder zeichnen}
  FOR b:=0 TO 1 DO
   Memw [pic:(b+x+fig [r,z,a*2])*2+(y+fig [r,z,a*2+1])*160+226]:=219+c*256;

Sound(500);
delay(40);
NoSound;
Sound(510);
delay(40);
NoSound;
Sound(520);
delay(40);
NoSound;
delay(40);
end;
delay(100);
ch:=#0;
end;

procedure CheckNet;
begin;
if net then begin;
  ListenChannel;

  if ((s='M') and Master) or ((s='S')and (not Master)) then begin;
   repeat
    ListenChannel;
   until s<>'';
   val(s,i,tempi);
   AddLines(i);
  end;

  if s='Won' then begin;
  SendChannel('Ack');
  WHILE KeyPressed DO ch:=ReadKey;
  BigWon;
  Quit;
  end;

  if s='Quit' then begin;
  SendChannel('Ack');
  Quit;
  end;
end;
end;

PROCEDURE spiel;
BEGIN
  s1:=Random (7);
  t:=Random (6)+1;
  GotoXY (56,23); ch:=#0;
  REPEAT
   r:=s1; c:=t;
   s1:=Random (7);
   t:=Random (6)+1;
   IF s1 IN [3..6] THEN s1:=Random (7);
   d:=0; h:=0; x:=10; y:=0; z:=0; id:=0;
   FOR a:=0 TO 3 DO
    FOR b:=0 TO 7 DO Memw [pic:a*160+b*2+610]:=0;
   FOR a:=0 TO 3 DO
    FOR b:=0 TO 1 DO
     Memw [pic:(b+x+fig [s1,z,a*2])*2+(y+fig [s1,z,a*2+1])*160+590]:=219+t*256;
   FOR a:=0 TO 3 DO
    FOR b:=0 TO 1 DO
     IF Mem [pic:(b+x+fig [r,z,a*2])*2+(y+fig [r,z,a*2+1])*160+226]>32
     THEN Exit;
   GotoXY (56,23);

   REPEAT
    ch:=#0;

    if (oldy<>y) and (id=2) then CheckNet;
    oldy:=y;
    WHILE KeyPressed DO ch:=ReadKey;
    if ch=#65 then begin; AddLines(1);end;
    IF ch=#80 THEN h:=y+1;
    IF ch=#27 THEN BEGIN
    if net then begin;
     SendChannel('Quit');
     si:=0;
     repeat
      inc(si);
      delay(200);
      ListenChannel;
     until (s='Ack') or (si>10);
    end;
    Quit;
    END;

    IF h>0 THEN d:=Round (spd)+2;
    IF (id=1) OR (ch IN [#13,#32,#75,#77]) THEN BEGIN
     FOR a:=0 TO 3 DO
      FOR b:=0 TO 1 DO
       Memw [pic:(b+x+fig [r,z,a*2])*2+(y+fig [r,z,a*2+1])*160+226]:=0;
     e:=x; f:=z; g:=0;
     IF ch IN [#13,#32] THEN IF z<3 THEN
      Inc (z) ELSE z:=0;
     IF ch=#75 THEN Dec (x,2);
     IF ch=#77 THEN Inc (x,2);
     FOR a:=0 TO 3 DO
      FOR b:=0 TO 1 DO
       IF Mem [pic:(b+x+fig [r,z,a*2])*2+(y+fig [r,z,a*2+1])*160+226]>32
       THEN g:=1;
     IF g=1 THEN BEGIN
      x:=e; z:=f
     END
    END;
    IF id=1 THEN Inc (y);
    FOR a:=0 TO 3 DO
     FOR b:=0 TO 1 DO
      Memw [pic:(b+x+fig [r,z,a*2])*2+(y+fig [r,z,a*2+1])*160+226]:=32+c*4096;
    id:=2; Inc (d);
    IF d>spd THEN BEGIN
     d:=0; id:=1;
     FOR a:=0 TO 3 DO
      FOR b:=0 TO 1 DO
       IF Mem [pic:(b+x+fig [r,z,a*2])*2+(y+fig [r,z,a*2+1])*160+386]>32
       THEN id:=0
    END;
    ch:=#0; Delay (6);
   UNTIL id=0;
   FOR a:=0 TO 3 DO
    FOR b:=0 TO 1 DO
     Memw [pic:(b+x+fig [r,z,a*2])*2+(y+fig [r,z,a*2+1])*160+226]:=219+c*256;
   IF h>0 THEN h:=y-h;
   FOR a:=1 TO 22 DO BEGIN
    c:=1;
    FOR b:=2 TO 21 DO IF Mem [pic:a*160+b*2+66]<>219 THEN c:=0;{Gibt es eine}
                                                               {LÅcke => c=0}
    IF c=1 THEN BEGIN                           {Wenn nicht: Zeile komplett!}
Sound(400);
delay(40);
NoSound;
Sound(600);
delay(40);
NoSound;
Sound(800);
delay(40);
NoSound;
delay(40);
     Inc (lin);
     IF spd>30 THEN spd:=spd-spd/75;              {Ok, also schneller machen}
     FOR b:=a-1 DOWNTO 1 DO                          {Alles fÑllt nach unten}
      FOR c:=4 TO 43 DO Mem [pic:b*160+c+226]:=Mem [pic:b*160+c+66]
    END
   END;
  textcolor(11);
  GotoXY (1,1); Write ('ROWS: ');Write(lin);
  textcolor(7);

if (Net) and (lin<>oldlin) then SendLinesToEnemy(lin-oldlin);
  oldlin:=lin;

 UNTIL y=0;
if net then begin;
SendChannel('Won');
repeat
ListenChannel;
until s='Ack';
WHILE KeyPressed DO ch:=ReadKey;
BigLost;
Quit;
end;
END;


 PROCEDURE list;
 VAR x : String;
 BEGIN
  c:=9;
  WHILE (lin>=bit.r [c-1]) AND (c>0) DO
 Dec (c);
  FOR a:=8 DOWNTO c DO BEGIN
   bit.r [a+1]:=bit.r [a];
   bit.n [a+1]:=bit.n [a];
   FOR b:=0 TO 49 DO Mem [pic:a*160+b+1440]:=Mem [pic:a*160+b+1280]
  END;
  GotoXY (1,c+9); Write (lin:5);
  GotoXY (8,c+9); x:='';                
  TextBackground (7); TextColor (0);
  FOR a:=1 TO 16 DO Write (#32);        
  REPEAT                                
   GotoXY (8,c+9); Write (x);           
   IF x [0]<#16 THEN Write (#32,#8);
   REPEAT                               
    ch:=#0;                             
    WHILE KeyPressed DO ch:=ReadKey;
    IF (ch IN [#65..#90]) AND NOT (Mem [65:7] MOD 16 IN [1,2]) THEN ch:=#0;
   UNTIL ch IN [#8,#13,#32..#255];
   IF ch=#8 THEN Delete (x,Length (x),1)
    ELSE IF (ch<>#13) AND (x [0]<#16) THEN x:=x+ch;
  UNTIL ch=#13;
  bit.r [c]:=lin; bit.n [c]:=x;
  Assign (dat,'tetris.tbl');
  Rewrite (dat);
  IF IOresult=0 THEN BEGIN
   Write (dat,bit);
   Close (dat)
  END
 END;


function Status(c:string):string;
var i,sx,sy:integer;
begin;
  sx:=wherex;sy:=wherey;gotoxy(76,1);textcolor(14);textbackground(4);write('BUSY');
  textcolor(7);textbackground(0);gotoxy(sx,sy);
  delay(100);
  s:='';
    assign (fi, ParamStr(1)+'\' + c);
    {$I-} reset (fi); {$I+}
    if IORESULT=0 then begin;
        if not eof(fi) then ReadLn (fi, s);
        Status:=s;
        if s='*' then begin;
         ReadLn(fi,s);
         Status:='HEY! Please join me, '+s+'!';
        end;
        close(fi);
    end;
  sx:=wherex;sy:=wherey;gotoxy(76,1);write('    ');gotoxy(sx,sy);
end;

procedure ShowChannels;
var sx,sy:integer;
begin;
  writeln('TETRIS v1.0');
  writeln('(c)1997 SDT');
  writeln;
  writeln('Select the user you want to play with and enter his name.');
  writeln('Press ESC if you want to quit.');
  writeln;
  textcolor(15);
  writeln('List of Players: ');
  textcolor(7);
  writeln;
  sx:=wherex;sy:=wherey;gotoxy(76,1);textcolor(14);textbackground(4);write('BUSY');
  textcolor(7);textbackground(0);gotoxy(sx,sy);
  FindFirst(ParamStr(1)+'\*.TET', $3F, DirInfo);
  while DosError = 0 do
   begin
     if (Dirinfo.Size>0) and (DirInfo.Name<>'.') and (DirInfo.Name<>'..') then begin;
     write(' ');
     textcolor(10);
     textbackground(1);
     write(Dirinfo.Name);
     gotoxy(WhereX-4, WhereY);
     textcolor(7);
     textbackground(0);
     write('    ');
     gotoxy(15, WhereY);
     writeln(Status(Dirinfo.Name));
     end;
     FindNext(DirInfo);
   end;
  writeln;
  textcolor(11);
  if myChannel<>'' then writeln('Your name: '+myChannel);
  writeln;
  textcolor(7);
  sx:=wherex;sy:=wherey;gotoxy(76,1);write('    ');gotoxy(sx,sy);
end;



BEGIN
IF (pic<>$B000) AND (pic<>$B800) THEN
pic:=$B800;
init;
Net:=true;
if ParamCount=0 then CMDHelp;
if ParamStr(1)='-1' then Net:=False;


if Net then begin;
if ParamCount<1 then CMDHelp;
Randomize;

myChannel:=ParamStr(2);
cchannel:=myChannel;
PurgeChannel;
SendChannel('Idle');
repeat
Cursor_On;
clrscr; ShowChannels;
  LI:=0;
  Repeat
    repeat
    if i=3000 then begin; clrscr; ShowChannels; write(LT); end;
    i:=0;
    repeat
    delay(1);inc(i);
    until (i=3000) or (keypressed);

    until keypressed;
    LA:=readKey;
    inc(LI);
    IF LA=CHR(13) THEN begin; writeln; isquit:=true; end;
    IF LA=CHR(27) THEN begin; Quit; end;
    IF LA=CHR(8) THEN
                   BEGIN
                     IF LI> 0 then
                       begin
                       dec(LI,2);if LI<0 then Li:=0;
                       gotoXY (wherex-1,wherey);
                       write (' ');
                       delete(LT,LI+1,1);
                       LA:=#0;
                       gotoXY (1,wherey);
                       write (LT);
                       end;
                   end;


if (not isquit) and (LA<>#0) then begin; write(LA); LT:=LT+LA; end;
until (LI=80) or (isquit);
isquit:=false;

st:=LT;


if st<>'' then eChannel:=st;
if st='quit' then begin;ClrScr;Quit;end;
until eChannel<>'';
PurgeMyChannel;
Cursor_Off;
CheckWhoIsMaster;
ClrScr;
st:=eChannel;
eChannel:='';
rahmen;
eChannel:=st;
gotoxy(1,1);
textcolor (15);
writeln('Waiting for '+echannel+'`s answer');
if Master then Handshake;
ClrScr;
cChannel:=myChannel;
SendChannel('Currently playing TETRIS against '+eChannel);
if not Master then begin;
cChannel:=eChannel;
end;
rahmen;
spiel;
SendChannel('Won');
si:=0;
repeat
delay(200);
inc(si);
ListenChannel;
until (s='Ack') or (si>10);
WHILE KeyPressed DO ch:=ReadKey;
BigLost;
Quit;
end;




if not NET then begin;
  Cursor_Off;
  rahmen;
  spiel;
  Cursor_On;
   IF lin>=bit.r [9] THEN list ELSE BEGIN
    GotoXY (41,25); Write ('Game Over');
    Delay (500);
    WHILE KeyPressed DO ch:=ReadKey;
   END;
 Cursor_On;
 ClrScr;
 end;

END.

