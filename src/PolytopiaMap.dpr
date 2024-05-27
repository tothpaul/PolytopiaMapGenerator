program PolytopiaMap;

{$R 'assets.res' 'assets.rc'}

uses
  Vcl.Forms,
  PolytopiaMap.Main in 'PolytopiaMap.Main.pas' {Main};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
