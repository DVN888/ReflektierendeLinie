UNIT Unit1;

{$mode objfpc}{$H+}

INTERFACE

USES
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

TYPE

  { TForm1 }

  TForm1 = CLASS(TForm)
    TimerBewegung: TTimer;
    PROCEDURE FormCreate(Sender: TObject);
    PROCEDURE FormKeyPress(Sender: TObject; VAR Key: char);
    PROCEDURE FormResize(Sender: TObject);
    PROCEDURE TimerBewegungTimer(Sender: TObject);
  private

  public

  END;

VAR
  Form1: TForm1;

IMPLEMENTATION

{$R *.lfm}
//===================================================================
// Cooler Coder Name: PokoWare
//===================================================================
//               eigene globale Deklarationen
//-------------------------------------------------------------------
CONST
  GC_anz = 22;
TYPE
tVektor = RECORD
           dx,dy:INTEGER;
          END;

tPunkt = RECORD
           x,y         :INTEGER;
           richtung    :tVektor;
           maxX,maxY   :INTEGER;  //für Randkontrolle
           maxdelta    :BYTE;     //für die Sprungweite
         END;
tStrecke = RECORD
           p1,p2:tPunkt;
           farbe:TColor;
           CAN:TCanvas;
           END;
tStreckenFeld = ARRAY [1..(GC_anz+1)] OF tStrecke;

VAR
  st:tStrecke;
  StreckenFeld:tStreckenFeld;     //IDEE: 1 echte Strecke, Speichern der Werte im Array
                                  //      Farbe der letzten Strecke auf Hintergrundfarbe setzen
                                  //      Abruf der Koordinaten der "letzten echten" Linie aus Array
                                  //      (GC+1)te Strecke ist die Löschstrecke
//===================================================================
//               eigene coole abgeschlossene Routinen
//-------------------------------------------------------------------
FUNCTION delta(max:BYTE):SHORTINT;
BEGIN
  Result:=Random(2*max+1)-max;
END;

FUNCTION delta_ohneNull(max:BYTE):SHORTINT;
VAR plusminus:SHORTINT;
BEGIN
  plusminus:=Random(2)-1;
  IF plusminus=0 THEN plusminus:=1;
  Result:=plusminus*(Random(max)+1);
END;

FUNCTION neuErzeugteStrecke(FRM:TForm):tStrecke;
VAR s:tStrecke;
BEGIN
  //Abspeichern der Grenzen und Beschränkungen
   //s.p1
  s.p1.maxX:=FRM.Width;
  s.p1.maxY:=FRM.Height;
  s.p1.maxdelta:=20;
   //s.p2
  s.p2.maxX:=FRM.Width;
  s.p2.maxY:=FRM.Height;
  s.p2.maxdelta:=20;
   //s
  s.CAN:=FRM.Canvas;

  //Belegung der Anfangswerte:
   //s.p1
  s.p1.x:=Random(s.p1.maxX);
  s.p1.y:=Random(s.p1.maxY);
   //s.p2
  s.p2.x:=Random(s.p2.maxX);
  s.p2.y:=Random(s.p2.maxY);
   //s
  s.farbe:=Random(clWhite);

  //Bewegungsrichtung festlegen
   //s.p1
  s.p1.richtung.dx:=delta_ohneNull(s.p1.maxdelta);
  s.p1.richtung.dy:=delta_ohneNull(s.p1.maxdelta);
   //s.p2
  s.p2.richtung.dx:=delta_ohneNull(s.p2.maxdelta);
  s.p2.richtung.dy:=delta_ohneNull(s.p2.maxdelta);


  //Rückgabe der festgelegten Werte an die aufrufende Routine
  Result:=s
END;

PROCEDURE SetzeStrecke(s:tStrecke);
BEGIN
  s.CAN.Pen.Color:=s.farbe;
  s.CAN.Line(s.p1.x,s.p1.y,s.p2.x,s.p2.y);
END;

FUNCTION neueKoordinaten(s:tStrecke):tStrecke;
VAR ausserhalb:BOOLEAN;
BEGIN
  //neue x-koordinate:
  s.p1.x:=s.p1.x+s.p1.richtung.dx;
  s.p2.x:=s.p2.x+s.p2.richtung.dx;

  //Randkontrolle:
   //s.p1
  ausserhalb:=(s.p1.x<0)OR(s.p1.x>s.p1.maxX);
  IF s.p1.x<0 THEN s.p1.x:=0;
  IF s.p1.x>s.p1.maxX THEN s.p1.x:=s.p1.maxX;
  IF ausserhalb THEN s.p1.richtung.dx:=-s.p1.richtung.dx;
   //s.p2
  ausserhalb:=(s.p2.x<0)OR(s.p2.x>s.p2.maxX);
  IF s.p2.x<0 THEN s.p2.x:=0;
  IF s.p2.x>s.p2.maxX THEN s.p2.x:=s.p2.maxX;
  IF ausserhalb THEN s.p2.richtung.dx:=-s.p2.richtung.dx;

  //neue y-koordinate:
  s.p1.y:=s.p1.y+s.p1.richtung.dy;
  s.p2.y:=s.p2.y+s.p2.richtung.dy;

  //Randkontrolle:
  //s.p1
  ausserhalb:=(s.p1.y<0)OR(s.p1.y>s.p1.maxY);
  IF s.p1.y<0 THEN s.p1.y:=0;
  IF s.p1.y>s.p1.maxY THEN s.p1.y:=s.p1.maxY;
  IF ausserhalb THEN s.p1.richtung.dy:=-s.p1.richtung.dy;
  //s.p2
  ausserhalb:=(s.p2.y<0)OR(s.p2.y>s.p2.maxY);
  IF s.p2.y<0 THEN s.p2.y:=0;
  IF s.p2.y>s.p2.maxY THEN s.p2.y:=s.p2.maxY;
  IF ausserhalb THEN s.p2.richtung.dy:=-s.p2.richtung.dy;

  //Rückgabe der Änderungen
  Result:=s
END;

FUNCTION EintragInStreckenFeld (strecke:tStrecke;feld:tStreckenFeld):tStreckenFeld;
VAR i:BYTE;
BEGIN
  FOR i:= Length(feld) DOWNTO 2 DO feld[i]:=feld[i-1];

  feld[1]:=strecke;
  Result:=feld
END;

PROCEDURE LoescheLetzteStrecke(feld:tStreckenFeld);
BEGIN
  feld[Length(feld)].farbe:=Form1.Color;
  SetzeStrecke(feld[Length(Feld)]);
END;

PROCEDURE StreckenErneuern(feld:tStreckenFeld);
VAR i:BYTE;
BEGIN
  FOR i:= GC_anz DOWNTO 1 DO SetzeStrecke(feld[i]);
END;

//===================================================================
//               zusammenfassende Hilfsroutinen
//-------------------------------------------------------------------
PROCEDURE Start;
VAR i:BYTE;
BEGIN
  Form1.Repaint;
  st:=neuErzeugteStrecke(Form1);
  StreckenFeld[1]:=st;
  FOR i:= 2 TO GC_anz+1 DO BEGIN
    //StreckenFeld[i]:=neueKoordinaten(StreckenFeld[i-1]);
    StreckenFeld[i]:=st;
  END;

  SetzeStrecke(st);
  Form1.TimerBewegung.Enabled:=TRUE;             //Timer AN
END;

FUNCTION weicherFarbwechsel(farbe:TColor):TColor;
VAR r,g,b:SMALLINT;
CONST df = 10;
BEGIN
  //bereits vorhandene Funktionen
  {
  r:=Red(farbe);
  g:=Green(farbe);
  b:=blue(farbe);
  }

  //das Eigen

  r:=farbe                  MOD 256;
  g:=farbe DIV 256          MOD 256;
  b:=farbe DIV 256 DIV 256  MOD 256;


  //Werteänderung
  r:=r+delta(df);
  g:=g+delta(df);
  b:=b+delta(df);

  //Grenzwerte überschritten? Einhalten der Farbwerte
  {rot}  IF r<0 THEN r:=0; IF r>255 THEN r:=255;
  {grün} IF g<0 THEN g:=0; IF g>255 THEN g:=255;
  {blau} IF b<0 THEN b:=0; IF b>255 THEN b:=255;

  //bereits vorhandene Funktion
  //farbe:=RGBToColor(r,g,b);

  //das Eigen
  farbe:=r+g*256+b*256*256;                          //meisterhaft erratet

  Result:=farbe
END;

FUNCTION harterFarbwechsel(farbe:TColor):TColor;
BEGIN
  farbe:=farbe+delta(10);
  Result:=farbe
END;

//===================================================================
//               Ereignisbehandlungsroutinen (EBR)
//-------------------------------------------------------------------
{ TForm1 }
PROCEDURE TForm1.FormCreate(Sender: TObject);
BEGIN
    Form1.WindowState:=wsMaximized;     // falls man beim Start schon
  //Form1.BorderStyle:=bsNone;          // Vollbild ohne Rand möchte ...
  //Form1.Position:=poScreenCenter;     // ... dann ist diese Zeile aber unnötig
  Form1.Color:=clBlack;
  Randomize;
  Form1.TimerBewegung.Enabled:=FALSE;   //Timer zunächst AUS
  Form1.TimerBewegung.Interval:=1;    //Wartezeit einstellen in ms)
END;

PROCEDURE TForm1.FormKeyPress(Sender: TObject; VAR Key: char);
BEGIN
  CASE key OF
   ' ': Start;         //Leertaste zum Neustarten (FormPaint wird aufgerufen)
   #27: Form1.Close;   //Esc zum Beenden
  END;
end;

PROCEDURE TForm1.FormResize(Sender: TObject);
BEGIN
  st.p1.maxX:=Form1.Width;
  st.p1.maxY:=Form1.Height;
  st.p2.maxX:=Form1.Width;
  st.p2.maxY:=Form1.Height;
end;

PROCEDURE TForm1.TimerBewegungTimer(Sender: TObject);
BEGIN
  st:=neueKoordinaten(st);

{FARBWECHSEL}
    //st.farbe:=harterFarbwechsel(st.farbe);
    st.farbe:=weicherFarbwechsel(st.farbe);

  SetzeStrecke(st);
  StreckenFeld:=EintragInStreckenFeld(st,StreckenFeld);
  LoescheLetzteStrecke(StreckenFeld);
  StreckenErneuern(StreckenFeld);
end;

END.

