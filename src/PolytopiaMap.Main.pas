unit PolytopiaMap.Main;

{

  Delphi 12 Polytopia Map Generator (c)2024 Execute SARL
  https://github.com/tothpaul/PolytopiaMapGenerator

  this is a Delphi port of a Javascript project to generate a Polytopia Map
  https://github.com/QuasiStellar/Polytopia-Map-Generator


}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX,
  System.SysUtils, System.Variants, System.Classes, System.Zip, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.StdCtrls,
  Vcl.CheckLst, Vcl.ExtCtrls;

type
  TTribes = (
    None,
    Xinxi, Imperius, Bardur, Oumaji, Kickoo, Hoodrick, Luxidoor, Vengir, Zebasi,
    Aimo, Quetzali, Yadakk, Aquarion, Elyrion, Polaris
  );

  TValidTribes = Xinxi..Polaris;

  TTerrains = (
    empty,
    capital, ground, forest, fruit, game, mountain,
    crop, fish, metal, water, whale, ocean, ruin, village
  );

  TProbTerrains =  forest..whale;

  TTribeTerrains = capital..mountain;

  TGeneralTerrains = crop..village;

  TAssets = record
    GeneralTerrains: array[TGeneralTerrains] of TWICImage;
    Tribes: array[TValidTribes, TTribeTerrains] of TWICImage;
  end;

  TMapInfo = record
    Seed: Cardinal;
    Size: Integer;
    Land: Integer;
    Smooth: Integer;
    Relief: Integer;
    Tribes: set of TValidTribes;
  end;

  TCell = record
    Terrain: TTerrains;
    Above  : TTerrains;
    Tribe  : TTribes;
    procedure Init;
  end;

  TMain = class(TForm)
    pnOptions: TPanel;
    Label1: TLabel;
    edMapSize: TEdit;
    lbLand: TLabel;
    pbInitalLand: TPaintBox;
    pbSmoothing: TPaintBox;
    lbSmooth: TLabel;
    lbRelief: TLabel;
    pbRelief: TPaintBox;
    lblTribes: TLabel;
    lbTribes: TCheckListBox;
    btGenerate: TButton;
    Label2: TLabel;
    edSeed: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure OnRangeMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbInitalLandMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pbInitalLandPaint(Sender: TObject);
    procedure btGenerateClick(Sender: TObject);
  private
    { Déclarations privées }
    Assets: TAssets;
    Map: TMapInfo;
    Cells: TArray<TCell>;
    CellCount: Integer;
    function LoadAsset(zip: TZipFile; const AName: string): TWICImage;
    function filterNone(const index: TArray<Integer>; AcceptWater: Boolean): TArray<Integer>;
    function Circle(Center, Radius: Integer): TArray<Integer>;
    function GetNeighbours(Center, Radius: Integer): TArray<Integer>;
    function plusSign(center: Integer): TArray<Integer>;
    function nearLand(Cell: Integer): Boolean;
    function VillageFlag(Cell: Integer): Integer;
    function SetVillage(var Villages: TArray<Integer>; Cell, Flag: Integer): Integer;
    function RandomTest(Cell: Integer; Probability: Single; Terrain: TTerrains; Village: Integer): Boolean;
    function RandomTerrainTest(Cell: Integer; Terrain: TTerrains; Village: Integer): Boolean;
    function Distance(c1, c2: Integer): Integer;
    function checkResources(resource: TTerrains; capital: Integer): Integer;
    procedure postGenerate(resource, underneath: TTerrains; quantity, capital: Integer);
    procedure Generate;
    procedure DrawImage(Image: TWICImage; x, y, size: Single; Layout: TTextLayout = tlTop);
  public
    { Déclarations publiques }
  end;

var
  Main: TMain;

implementation

{$R *.dfm}

const
  TRIBES: array[TValidTribes] of string = (
    'Xin-xi', 'Imperius', 'Bardur', 'Oumaji', 'Kickoo', 'Hoodrick', 'Luxidoor', 'Vengir', 'Zebasi',
    'Ai-mo', 'Quetzali', 'Yadakk', 'Aquarion', 'Elyrion', 'Polaris'
  );

  TRIBE_COUNT = Length(TRIBES);

  TERRAINS: array[TTribeTerrains] of string = (
    'head', 'ground', 'forest', 'fruit', 'game', 'mountain'
  );

  GENERAL_TERRAINS: array[TGeneralTerrains] of string = (
   'crop', 'fish', 'metal', 'water', 'whale', 'ocean', 'ruin', 'village'
  );

  FOREST_PROBS = 0.40;
  MOUNTAIN_PROBS = 0.15;
  FRUIT_PROBS = 0.5;
  CROP_PROBS = 0.5;
  GAME_PROBS = 0.5;
  FISH_PROBS = 0.5;
  WHALE_PROBS = 0.4;

  BORDER_EXPANSION = 1/3;

  GENERAL_PROBS: array[TProbTerrains] of Single = (
  // forest, fruit, game, mountain, crop, fish, metal, water, whale
        0.4,   0.5,  0.5,     0.15,  0.5,  0.5,  0.5,   0.0,   0.4
  );

  TERRAIN_PROBS: array[TValidTribes, TProbTerrains] of Single = (
  // forest, fruit, game, mountain, crop, fish, metal, water, whale
    (   1.0,   1.0,  1.0,      1.5,  1.0,  1.0,  1.0,   0.0,   1.0), // Xin-xi
    (   1.0,   1.0,  1.0,      1.0,  1.0,  1.0,  1.0,   0.0,   1.0), // Imperius
    (   1.0,   1.5,  2.0,      1.0,  0.1,  1.0,  1.0,   0.0,   1.0), // Bardu
    (   0.1,   1.0,  1.0,      1.0,  1.0,  1.0,  1.0,   0.0,   1.0), // Oumaji
    (   1.0,   1.0,  1.0,      0.5,  1.0,  1.5,  1.0,   0.4,   1.0), // kickoo
    (   1.5,   1.0,  1.0,      0.5,  1.0,  1.0,  1.0,   0.0,   1.0), // Hoodrick
    (   1.0,   2.0,  0.5,      1.0,  1.0,  1.0,  1.0,   0.0,   1.0), // Luxidoor
    (   1.0,   0.1,  0.1,      1.0,  1.0,  0.1,  2.0,   0.0,   1.0), // Vengir
    (   0.5,   0.5,  1.0,      0.5,  1.0,  1.0,  1.0,   0.0,   1.0), // Zebasi
    (   1.0,   1.0,  1.0,      1.5,  0.1,  1.0,  1.0,   0.0,   1.0), // Ai-mo
    (   1.0,   2.0,  1.0,      1.0,  0.1,  1.0,  0.1,   0.0,   1.0), // Quetzali
    (   0.5,   1.5,  1.0,      0.5,  1.0,  1.0,  1.0,   0.0,   1.0), // Yadakk
    (   0.5,   1.0,  1.0,      1.0,  1.0,  1.0,  1.0,   0.3,   1.0), // Aquarion
    (   1.0,   1.0,  1.0,      0.5,  1.5,  1.0,  1.0,   0.0,   1.0), // Elyrion
    (   0.0,   0.0,  0.0,      0.0,  0.0,  0.0,  0.0,   0.0,   0.0)  // Polaris
  );


{ TCell }

procedure TCell.Init;
begin
  Terrain := Ocean;
  Above := Empty;
  Tribe := None;
end;

{ TMain }

procedure TMain.FormCreate(Sender: TObject);
begin
  for var I := Low(TValidTribes) to High(TValidTribes) do
    lbTribes.Items.Add(TRIBES[I]);
  lbTribes.Checked[0] := True;
  lbTribes.Checked[1] := True;
  lbTribes.Checked[2] := True;
  lbTribes.Checked[4] := True;

  Map.Seed := 0;
  Map.Size := 18;
  Map.Land := 50;
  Map.Smooth := 3;
  Map.Relief := 4;
  Map.Tribes := [Kickoo, Xinxi, Imperius, Bardur];  // Xin-xi Imperius Bardur Kickoo
  Map.Seed := Cardinal(RandSeed);
  edSeed.TextHint := Map.Seed.ToString;

  // Load assets
  var res := TResourceStream.Create(hInstance, 'ASSETS', RT_RCDATA);
  var zip := TZipFile.Create;
  zip.Open(res, TZipMode.zmRead);

  // General terrains
  for var t := Low(TGeneralTerrains) to High(TGeneralTerrains) do
  begin
    assets.GeneralTerrains[t] := LoadAsset(zip, GENERAL_TERRAINS[t] + '.png');
  end;

  // Tribes
  for var tr := Low(TValidTribes) to High(TValidTribes) do
  begin
    for var t := Low(TTribeTerrains) to High(TTribeTerrains) do
    begin
      assets.Tribes[tr, t] := LoadAsset(zip, TRIBES[tr] + '/' + TRIBES[tr] + ' ' + TERRAINS[t] + '.png');
    end;
  end;

  Generate;
end;

function TMain.LoadAsset(zip: TZipFile; const AName: string): TWICImage;
begin
  var dat: TBytes;
  zip.Read(AName, dat);
  var stm := TBytesStream.Create(dat);
  Result := TWICImage.Create;
  Result.LoadFromStream(stm);
//  Result.EnableScaledDrawer(TWICScaledGraphicDrawer);
  stm.Free;
end;

function TMain.filterNone(const index: TArray<Integer>; AcceptWater: Boolean): TArray<Integer>;
begin
  Result := index;
  var n := 0;
  for var i := 0 to Length(Result) - 1 do
  begin
    if (Cells[Result[i]].Tribe = None) and (AcceptWater or (Cells[Result[i]].Terrain <> Water)) then
    begin
      if n < i then
      begin
        Result[n] := Result[i];
      end;
      Inc(n);
    end;
  end;
  SetLength(Result, n);
end;

function TMain.Circle(Center, Radius: Integer): TArray<Integer>;
var
  i, j: Integer;
begin
{  22222
   21112
   21X12
   21112
   22222
}
// Radius = 1 => 8
// Radius = 2 =>
  SetLength(Result, Radius * 8);
  var Count := 0;

  var row := center div Map.Size;
  var column := center mod Map.Size;

  i := row - radius;
  if (i >= 0) and (i < Map.Size) then
  begin
    for j := column  - radius to column + radius - 1 do
    begin
      if (j >= 0) and (j < Map.Size) then
      begin
        Result[Count] := i * Map.Size + j;
        Inc(Count);
      end;
    end;
  end;

  i := row + radius;
  if (i >= 0) and (i < Map.Size) then
  begin
    for j := column  + radius downto column - radius + 1 do
    begin
      if (j >= 0) and (j < Map.Size) then
      begin
        Result[Count] := i * Map.Size + j;
        Inc(Count);
      end;
    end;
  end;

  j := column - radius;
  if (j >= 0) and (j < Map.Size) then
  begin
    for i := row + radius downto row - radius + 1 do
    begin
      if (i >= 0) and (i < Map.Size) then
      begin
        Result[Count] := i * Map.Size + j;
        Inc(Count);
      end;
    end;
  end;

  j := column + radius;
  if (j >= 0) and (j < Map.Size) then
  begin
    for i := row - radius to row + radius - 1 do
    begin
      if (i >= 0) and (i < Map.Size) then
      begin
        Result[Count] := i * Map.Size + j;
        Inc(Count);
      end;
    end;
  end;

  SetLength(Result, Count);
end;

function TMain.GetNeighbours(Center, Radius: Integer): TArray<Integer>;
begin
  Result := nil;
  for var r := 1 to Radius do
  begin
    Result := Result + Circle(center, r);
  end;
  Result := Result + [Center];
end;

procedure TMain.OnRangeMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  var W := TPaintBox(Sender).Width;
  case TPaintBox(Sender).Tag of
    0: Map.Land := Max(0, Min(100 * X div W, 100));
    1: Map.Smooth := Max(0, Min(4 * X div W, 4));
    2: Map.Relief := Max(2, Min(2 + 4 * X div W, 6));
  end;
//  case TPaintBox(Sender).Tag of
//    0: lbLand.Caption := Map.Land.ToString;
//    1: lbSmooth.Caption := Map.Smooth.ToString;
//    2: lbRelief.Caption := Map.Relief.ToString;
//  end;
  TPaintBox(Sender).Invalidate;
end;

procedure TMain.pbInitalLandMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if ssLeft in Shift then
  begin
    OnRangeMouseDown(Sender, mbLeft, Shift, X, Y);
  end;
end;

procedure TMain.pbInitalLandPaint(Sender: TObject);
begin
  var R := TPaintBox(Sender).ClientRect;
  with TPaintBox(Sender).Canvas do
  begin
    Brush.Color := clSilver;
    Pen.Color := clBlack;
    FillRect(R);
    R.Inflate(1, 1);
    Pen.Style := psClear;
    var X, M: Integer;
    case TPaintBox(Sender).Tag of
      0: begin X := Map.Land; M := 100; end;
      1: begin X := Map.Smooth; M := 4; end;
      2: begin X := Map.Relief - 2; M := 6 - 2 end;
    else
      Exit;
    end;
    R.Width := R.Width * X div M;
    Brush.Color := clHighlight;
    FillRect(R);
  end;
end;

function TMain.plusSign(center: Integer): TArray<Integer>;
begin
  SetLength(Result, 4);
  var Count := 0;
  var row := center div Map.Size;
  var column := center mod Map.Size;
  if column > 0 then
  begin
    Result[Count] := center - 1;
    Inc(Count);
  end;
  if column < Map.Size - 1 then
  begin
    Result[Count] := center + 1;
    Inc(Count);
  end;
  if row > 0 then
  begin
    Result[Count] := center - Map.Size;
    Inc(Count);
  end;
  if row < Map.Size - 1 then
  begin
    Result[Count] := center + Map.Size;
    Inc(Count);
  end;
  SetLength(Result, Count);
end;

function TMain.nearLand(Cell: Integer): Boolean;
const
  lands = [ground, forest, mountain];
begin
  var r := Cell div Map.Size;
  var c := Cell mod Map.Size;
  Result := True;
  if (r > 0) and (Cells[Cell - Map.Size].Terrain in lands) then
    Exit;
  if (r < Map.Size - 1) and (Cells[Cell + Map.Size].Terrain in lands) then
    Exit;
  if (c > 0) and (Cells[Cell - 1].Terrain in lands) then
    Exit;
  if (c < Map.Size - 1) and (Cells[Cell + 1].Terrain in lands) then
    Exit;
  Result := False;
end;

function TMain.VillageFlag(Cell: Integer): Integer;
begin
  if Cells[Cell].Terrain in [ocean, mountain, water] then
    Exit(-1);
  if Cell mod Map.Size in [0, Map.Size - 1] then
    Exit(-1);
  if Cell div Map.Size in [0, Map.Size - 1] then
    Exit(-1);
  Result := 0;
end;

function TMain.SetVillage(var Villages: TArray<Integer>; Cell, Flag: Integer): Integer;
var
  f, r, c, x1, y1, x2, y2: Integer;
begin
  Result := 0;
  f := Villages[Cell];
  if f = 0 then
    Inc(Result);

  if (f < Flag) then
  begin
    Villages[Cell] := Flag;
  end;

  Dec(Flag);
  if Flag > 0 then
  begin
    c := Cell mod Map.Size;
    r := Cell div Map.Size;
    x1 := Max(0, c - 1);
    y1 := Max(0, r - 1);
    x2 := Min(c + 1, Map.Size - 1);
    y2 := Min(r + 1, Map.Size - 1);
    for var x := x1 to x2 do
      for var y := y1 to y2 do
        Inc(Result, SetVillage(Villages, x + Map.Size * y, Flag));
  end;
end;

function TMain.RandomTest(Cell: Integer; Probability: Single; Terrain: TTerrains; Village: Integer): Boolean;
begin
  if Village = 1 then
    Probability := Probability * BORDER_EXPANSION
  else
  if Village <> 2 then
    Exit(False);
  Result := Random < Probability;
  if Result then
  begin
    Cells[Cell].Above := Terrain;
  end;
end;

function TMain.RandomTerrainTest(Cell: Integer; Terrain: TTerrains; Village: Integer): Boolean;
begin
  var Tribe := Cells[cell].Tribe;
  Result := RandomTest(Cell, GENERAL_PROBS[Terrain] * TERRAIN_PROBS[Tribe, Terrain], Terrain, Village);
end;

function TMain.Distance(c1: Integer; c2: Integer): Integer;
begin
  var ax := c1 mod Map.Size;
  var ay := c1 div Map.Size;
  var bx := c2 mod Map.Size;
  var by := c2 div Map.Size;
  Result := Max(Abs(ax - bx), Abs(ay - by));
end;

procedure TMain.btGenerateClick(Sender: TObject);
begin
  if not TryStrToInt(edMapSize.Text, Map.Size) then
  begin
    ShowMessage('Invalid Map Size');
    Exit;
  end;
  Map.Tribes := [];
  var Tribe := Pred(Low(TValidTribes));
  for var I := 0 to lbTribes.Count - 1 do
  begin
    Inc(Tribe);
    if lbTribes.Checked[I] then
      Include(Map.Tribes, Tribe);
  end;
  if not TryStrToUInt(edSeed.Text, Map.Seed) then
    Map.Seed := Cardinal(RandSeed);
  edSeed.TextHint := Map.Seed.ToString;
  Generate;
  Invalidate;
end;

function TMain.checkResources(resource: TTerrains; capital: Integer): Integer;
begin
  Result := 0;
  var neighbours := circle(capital, 1);
  for var I := 0 to Length(neighbours) - 1 do
    if Cells[neighbours[i]].Above = resource then
      Inc(Result);
end;

procedure TMain.postGenerate(resource, underneath: TTerrains; quantity, capital: Integer);
begin
  while checkResources(resource, capital) < quantity do
  begin
    var pos := random(8);
    var territory := circle(capital, 1);
    pos := territory[pos];
    cells[pos].Terrain := underneath;
    cells[pos].Above := resource;
    var plus := plusSign(pos);
    for var p := 0 to Length(plus) - 1 do
    begin
      if cells[plus[p]].Terrain = Ocean then
        cells[plus[p]].Terrain  := water;
    end;
  end;
end;

procedure TMain.Generate;
begin
  RandSeed := Integer(Map.Seed);
  SetLength(Cells, Map.Size * Map.Size);

  CellCount := Length(Cells);

  // Fill with ocean tiles
  for var I := 0 to CellCount - 1 do
    Cells[I].Init;

  // Randomly replace ocean with ground
  var Land := Map.Land/100 * CellCount;
  var GroundCount := 0;
  while GroundCount < Land do
  begin
    var Cell := Random(CellCount);
    if Cells[Cell].Terrain = Ocean then
    begin
      Cells[Cell].Terrain := ground;
      Inc(GroundCount);
    end;
  end;

  // turning random water/ground grid into something smooth
  var coef := (0.5 + Map.Relief)/9;
  for var s := 0 to Map.Smooth - 1 do
  begin
    for var c := 0 to CellCount - 1 do
    begin
      var water := 0;
      var tile := 0;
      var neighbours := GetNeighbours(c, 1);
      for var i := 0 to Length(neighbours) - 1 do
      begin
        if Cells[neighbours[i]].Terrain = Ocean then
            Inc(water);
          Inc(tile);
      end;
      if water / tile <= coef then
        Cells[c].Above := Ground
      else
        Cells[c].Above := Ocean;
    end;
    // turn marked tiles into ground & everything else into water
    for var i := 0 to CellCount - 1 do
    begin
      Cells[i].Terrain := Cells[i].Above;
      Cells[i].Above := Empty;
    end;
  end;

  // capital distribution
  var Grounds: TArray<Integer>;
  SetLength(Grounds, CellCount);
  GroundCount := 0;
  for var row := 2 to Map.Size - 3 do
  begin
    var c := Map.Size * row + 2;
    for var col := 2 to Map.Size - 3 do
    begin
      if Cells[c].Terrain = Ground then
      begin
        Grounds[GroundCount] := c;
        Inc(GroundCount);
      end;
      Inc(c);
    end;
  end;

  if GroundCount = 0 then
  begin
    ShowMessage('No land available');  // fix bug from original code
    Exit;
  end;

  var Capitals: TArray<Integer>;
  SetLength(Capitals, TRIBE_COUNT);

  var Choices: TArray<Integer>;
  SetLength(Choices, GroundCount);

  var CapitalCount := 0;
  Capitals[0] := Grounds[Random(GroundCount)]; // 1st Capital

  var Distances: TArray<Integer>;
  SetLength(Distances, GroundCount);
  for var i := 0 to GroundCount - 1 do
    Distances[i] := Map.Size;
  var DistMax := 0;

  for var t := Low(TValidTribes) to High(TValidTribes) do
  begin
    if not (t in Map.Tribes) then
      Continue;

    if CapitalCount > 0 then
    begin
      var n := 0;
      for var g := 0 to GroundCount - 1 do
      begin
        if Distances[g] = DistMax then
        begin
          Choices[n] := Grounds[g];
          Inc(n);
        end;
      end;
      Capitals[CapitalCount] := Choices[Random(n)];
    end;

    var c := Capitals[CapitalCount];

    DistMax := 0;
    for var g := 0 to GroundCount - 1 do
    begin
      Distances[g] := Min(Distances[g], Distance(Grounds[g], c));
      DistMax := Max(DistMax, Distances[g]);
    end;

    if Cells[c].Tribe = None then  // fix bug
    begin
      Cells[c].Above := Capital;
      Cells[c].Tribe := t;
      Inc(CapitalCount);
    end;
  end;

  // terrain distribution
  var activesTiles: TArray<TArray<Integer>>;
  var activesCount: TArray<Integer>;
  SetLength(activesTiles, CapitalCount, CellCount);
  SetLength(activesCount, CapitalCount);
  for var I := 0 to CapitalCount - 1 do
  begin
    if Cells[Capitals[I]].Tribe = Polaris then
      activesCount[I] := 0
    else begin
      activesCount[I] := 1;
      activesTiles[I][0] := Capitals[I];
    end;
  end;

  var doneTiles := CapitalCount;
  while doneTiles < CellCount do
  begin
    for var I := 0 to CapitalCount - 1 do
    begin
      if activesCount[I] > 0 then
      begin
        var Tribe := Cells[Capitals[I]].Tribe;
        var randNumber := Random(activesCount[I]);
        var randCell := activesTiles[I, randNumber];
        var neighbours := circle(randCell, 1);
        var validNeighbours := filterNone(neighbours, False);
        if Length(validNeighbours) = 0 then
        begin
          validNeighbours := filterNone(neighbours, True);
        end;
        if Length(validNeighbours) > 0 then
        begin
          var newRandNumber := Random(Length(validNeighbours));
          var newRandCell := validNeighbours[newRandNumber];
          Cells[newRandCell].Tribe := Tribe;
          activesTiles[I, activesCount[I]] := newRandCell;
          Inc(activesCount[I]);
          Inc(doneTiles);
        end else begin
          Dec(activesCount[I]);
          Delete(activesTiles[I], randNumber, 1);
        end;
      end;
    end;
  end;

  // generate forest, mountains, and extra water according to terrain underneath
  for var I := 0 to CellCount - 1 do
  begin
    if (Cells[I].Terrain = ground) and (Cells[I].Above = Empty) then
    begin
      var Tribe := Cells[I].Tribe;
      var rand := Random();
      if rand < GENERAL_PROBS[forest] * TERRAIN_PROBS[Tribe, forest] then
        Cells[I].Terrain := Forest
      else
      if rand > 1 - GENERAL_PROBS[mountain] * TERRAIN_PROBS[Tribe, mountain] then
        Cells[I].Terrain := Mountain;
      rand := Random();
      if rand <TERRAIN_PROBS[Tribe, water] then
        Cells[I].Terrain := Ocean;
    end;
  end;

  // replace some ocean with shallow water
  for var I := 0 to CellCount - 1 do
  begin
    if (Cells[I].Terrain = ocean) and NearLand(I) then
      Cells[I].Terrain := water;
  end;

  //-1 - water far away
  // 0 - far away
  // 1 - border expansion
  // 2 - initial territory
  // 3 - village
  // 4 - Capital
  var villages: TArray<Integer>;
  SetLength(villages, CellCount);
  var VillageCount := 0;
  for var I := 0 to CellCount - 1 do
  begin
    Villages[I] := VillageFlag(I);
    if Villages[I] = 0 then
      Inc(VillageCount);
  end;

  // mark tiles next to capitals according to the notation
  for var I := 0 to CapitalCount - 1 do
  begin
    var C := Capitals[I];
//    Dec(VillageCount, SetVillage(villages, C, 3));
    if Villages[C] = 0 then
      Dec(VillageCount);
    Villages[C] := 4;
    var neighbours := circle(C, 1);
    for var n := 0 to Length(neighbours) - 1 do
    begin
      var V := neighbours[n];
      if villages[V] = 0 then
        Dec(VillageCount);
      villages[V] := Max(villages[V], 2);
    end;
    neighbours := circle(C, 2);
    for var n := 0 to Length(neighbours) - 1 do
    begin
      var V := neighbours[n];
      if villages[V] = 0 then
        Dec(VillageCount);
      villages[V] := Max(villages[V], 1);
    end;
  end;

  while VillageCount > 0 do
  begin
    var R := Random(VillageCount);
    for var I := 0 to CellCount -1 do
    begin
      if (villages[I] = 0) then
      begin
        if R = 0 then
        begin
          Dec(VillageCount, SetVillage(villages, I, 3));
          Break;
        end;
        Dec(R);
      end;
    end;
  end;

  // generate resources
  for var I := 0 to CellCount - 1 do
  begin
    var Tribe := Cells[I].Tribe;
    case Cells[I].Terrain of
      ground:
      begin
        var fruits := GENERAL_PROBS[fruit] * TERRAIN_PROBS[Tribe, fruit];
        var crops := GENERAL_PROBS[crop] * TERRAIN_PROBS[Tribe, crop];
        case Villages[I] of
          4: { Capital };
          3:
          begin
            Cells[I].Terrain := Ground;
            Cells[I].Above := Village;
          end;
          2,
          1: if not RandomTest(I, fruits * (1 - crops / 2), Fruit, Villages[I]) then
               RandomTest(I, crops * (1 - fruits / 2), Crop, Villages[I]);
        end;
      end;
      forest:
        case Villages[I] of
          4: { Capital };
          3:
          begin
            Cells[I].Terrain := Ground;
            Cells[I].Above := Village;
          end;
          2,
          1: RandomTerrainTest(I, game, Villages[I]);
        end;
      water: RandomTerrainTest(I, fish, Villages[I]);
      ocean: RandomTerrainTest(I, whale, Villages[I]);
      mountain: RandomTerrainTest(I, metal, Villages[I]);
    end;
  end;

  // ruins generation
  for var I := 0 to CellCount - 1 do
  begin
    if Abs(villages[I]) < 2 then
      Inc(VillageCount);
  end;

  var ruinsNumber := Round(Map.Size * Map.Size / 40);
  var waterRuinsNumber := Round(ruinsNumber / 3);
  var ruinsCount := 0;
  var waterRuinsCount := 0;
  while ruinsCount < ruinsNumber do
  begin
    var R := Random(VillageCount);
    for var I := 0 to CellCount - 1 do
    begin
      if  Abs(villages[I]) < 2 then
      begin
        if R = 0 then
        begin
          var Terrain := cells[I].Terrain;
          if (Terrain <> water) and ((waterRuinsCount < waterRuinsNumber) or (Terrain <> ocean)) then
          begin
            Cells[I].Above := ruin; // actually there can be both ruin and resource on a single tile but only ruin is displayed; as it is just a map generator it doesn't matter
            if Terrain = ocean then
              Inc(waterRuinsCount);
            var neighbours := circle(I, 1);
            for var n := 0 to Length(neighbours) - 1 do
            begin
              var V := neighbours[n];
              if Abs(villages[V]) < 2 then
              begin
                villages[V] := 2;
                Dec(VillageCount);
              end;
            end;
            Inc(ruinsCount);
          end else begin
            Villages[I] := 2; // fix bug from original code
            Dec(VillageCount);
          end;
          Break;
        end;
        Dec(R);
      end;
    end;
  end;

  // tribe specific things
  for var C := 0 to CapitalCount - 1 do
  begin
    var capital := Capitals[C];
    case Cells[capital].Tribe of
      Imperius : postGenerate(fruit, ground, 2, capital);
      Bardur   : postGenerate(game, forest, 2, capital);
      Kickoo   :
      begin
        while checkResources(fish, capital) < 2 do
        begin
          var pos := random(4);
          var territory := plusSign(capital);
          pos := territory[pos];
          cells[pos].Terrain := water;
          cells[pos].Above := fish;
          var neighbours := plusSign(pos);
          for var n := 0 to Length(neighbours) - 1 do
          begin
            if Cells[neighbours[n]].Terrain = water  then
            begin
              Cells[neighbours[n]].Terrain := ocean;
              var doubleNeighbours := plusSign(neighbours[n]);
              for var d := 0 to Length(doubleNeighbours) - 1 do
              begin
                if not (Cells[doubleNeighbours[d]].Terrain in [water, ocean]) then
                begin
                  Cells[doubleNeighbours[d]].Terrain := water;
                  Break;
                end;
              end;
            end;

          end;
        end;
      end;
      Zebasi   : postGenerate(crop, ground, 1, capital);
      Elyrion  : postGenerate(game, forest, 2, capital);
      Polaris  :
      begin
        var neighbours := circle(capital, 1);
        for var n := 0 to Length(neighbours) - 1 do
          cells[neighbours[n]].Tribe := Polaris;
      end;
    end;
  end;
end;

procedure TMain.DrawImage(Image: TWICImage; x, y, size: Single; Layout: TTextLayout = tlTop);
begin
  var R: TRect;
  case Layout of
    tlCenter: y := y - Image.Height * size / Image.Width / 2;
    tlBottom: y := y - Image.Height * size / Image.Width;
  end;
  R.Left := Trunc(x);
  R.Top := Trunc(y);
  R.Width := Trunc(size);
  R.Height := Trunc(Image.Height * size / Image.Width);
  if Image.ScaledDrawer <> nil then
    Image.ScaledDrawer.Draw(Canvas, R)
  else
    Canvas.StretchDraw(R, Image);
end;

procedure TMain.FormPaint(Sender: TObject);
begin
  var tileHeight := assets.Tribes[Xinxi, Ground].Height;
  var tileWidth := assets.Tribes[Xinxi, Ground].Width;
  var ratio := tileHeight / tileWidth * 1208 / 2009;

  var Width := ClientWidth - pnOptions.Width;

  var zoom := Min(Width, ClientHeight / ratio * Map.Size / (Map.Size + 2));

  var tileSize := zoom / Map.Size;

  var halfLine := tileSize * ratio / 2;

  var ox := pnOptions.Width + (Width - tileSize) / 2;
  var oy := ClientHeight / 2 - Succ(Map.Size) * halfLine;
  var dy := 2 * halfLine;

  for var i := 0 to CellCount - 1 do
  begin
    var row := i div Map.Size;
    var column := i mod Map.Size;
    var x := ox + (column - row) * tileSize / 2;
    var y := oy + (column + row) * halfLine;
    var Terrain := Cells[i].Terrain;
    var above := Cells[i].above;
    var tribe := Cells[i].Tribe;
    if Tribe = None then
      Tribe := Xinxi;
    case Terrain of
      Ocean,
      water : DrawImage(assets.GeneralTerrains[Terrain], x, y, tileSize);
      Forest,
      Mountain:
      begin
        DrawImage(assets.Tribes[Tribe, Ground], x, y, tileSize);
        if Tribe = Kickoo then
          DrawImage(assets.Tribes[Tribe, Terrain], x, y + dy * 3/5, tileSize, tlCenter)
        else
          DrawImage(assets.Tribes[Tribe, Terrain], x, y + dy, tileSize, tlBottom);
      end;
    else
      DrawImage(assets.Tribes[Tribe, Terrain], x, y, tileSize);
    end;
    case Above of
      Capital: DrawImage(assets.Tribes[Tribe, Above], x, y + dy, tileSize, tlBottom);
      Village: DrawImage(assets.GeneralTerrains[Above], x, y + dy, tileSize, tlBottom);
      Crop,
      Fish,
      Whale,
      Metal,
      Ruin  : DrawImage(assets.GeneralTerrains[Above], x, y + dy * 3/5, tileSize, tlCenter);
      fruit,
      game   : DrawImage(assets.Tribes[Tribe, Above], x, y + dy * 3/5, tileSize, tlCenter);
    end;
  end;

end;


procedure TMain.FormResize(Sender: TObject);
begin
  Invalidate;
end;

end.
