program dmu_smoke;

{ Deterministic package-owned proof for Dungeon Monkey Unlimited.
  This is built from the same upstream units as the game executable. }

{$LONGSTRINGS ON}

uses SysUtils, SDL, sdlgfx, gears, gamebook, randmaps, randworld;

const
  SmokeMarker = 'DMU-SMOKE: campaign-save-load-ok';
  SmokeEnemyID = 683;

procedure Fail(const Message: String);
begin
  WriteLn(StdErr, 'dungeon-monkey-unlimited smoke: ', Message);
  Halt(1);
end;

procedure Require(Condition: Boolean; const Message: String);
begin
  if not Condition then Fail(Message);
end;

procedure SaveScreenshot(const FileName: String; Board: GameBoardPtr;
                         Enemy: GearPtr);
const
  CellSize = 5;
var
  Tile: TSDL_Rect;
  Color: UInt32;
  X, Y, EnemyX, EnemyY: Integer;
begin
  if FileName = '' then Exit;
  Require(Game_Screen <> Nil, 'SDL screen was not initialized');
  ClrScreen;
  for Y := 1 to Board^.Map_Height do begin
    for X := 1 to Board^.Map_Width do begin
      Tile.X := (X - 1) * CellSize;
      Tile.Y := (Y - 1) * CellSize;
      Tile.W := CellSize;
      Tile.H := CellSize;
      if TileWall(Board, X, Y) <> 0 then begin
        Color := SDL_MapRGB(Game_Screen^.Format, 55, 55, 55);
      end else if TileVisible(Board, X, Y) then begin
        Color := SDL_MapRGB(Game_Screen^.Format, 75, 105, 65);
      end else begin
        Color := SDL_MapRGB(Game_Screen^.Format, 22, 35, 22);
      end;
      SDL_FillRect(Game_Screen, @Tile, Color);
    end;
  end;
  EnemyX := NAttValue(Enemy^.NA, NAG_Location, NAS_X);
  EnemyY := NAttValue(Enemy^.NA, NAG_Location, NAS_Y);
  Tile.X := (EnemyX - 1) * CellSize;
  Tile.Y := (EnemyY - 1) * CellSize;
  Tile.W := CellSize;
  Tile.H := CellSize;
  Color := SDL_MapRGB(Game_Screen^.Format, 230, 60, 45);
  SDL_FillRect(Game_Screen, @Tile, Color);
  Require(SDL_SaveBMP(Game_Screen, PChar(FileName)) = 0,
          'SDL screenshot failed');
end;

var
  Campaign, LoadedCampaign: CampaignPtr;
  Board, LoadedBoard: GameBoardPtr;
  Enemy, LoadedEnemy: GearPtr;
  SaveName: String;
  SaveFile: Text;
begin
  if ParamCount <> 0 then Fail('unexpected arguments');

  { uiconfig randomizes during unit initialization; replace it with a
    reproducible seed before exercising campaign generation. }
  RandSeed := 683001;
  Campaign := RandomCampaign(1);
  Require(Campaign <> Nil, 'campaign generation failed');
  Require(Campaign^.Source <> Nil, 'campaign source is missing');
  Require(Campaign^.Source^.SubCom <> Nil, 'campaign has no opening scene');

  Board := GenerateMap(Campaign, Campaign^.Source^.SubCom);
  Require(Board <> Nil, 'map generation failed');
  SetNAtt(Campaign^.Source^.NA, NAG_SaveFileData, NAS_CurrentGB, Board^.ID);

  { Activate a real model on the generated board.  This is the gameplay
    transition that the save/load round-trip below must preserve. }
  Enemy := NewGear(Nil);
  Require(Enemy <> Nil, 'enemy allocation failed');
  Enemy^.G := GG_Model;
  Enemy^.S := GS_EnemyTeam;
  Enemy^.V := GV_Inactive;
  Enemy^.Stat[STAT_Toughness] := 10;
  SetNAtt(Enemy^.NA, NAG_Location, NAS_X, 4);
  SetNAtt(Enemy^.NA, NAG_Location, NAS_Y, 4);
  SetNAtt(Enemy^.NA, NAG_StoryData, NAS_UniqueID, SmokeEnemyID);
  AppendGear(Board^.Contents, Enemy);
  ActivateModel(Board, Enemy);
  Require(Enemy^.V = GV_Active, 'model activation did not change gameplay state');

  { A visibility change is also part of the map state and makes the
    round-trip assertion independent of pointer identity. }
  SetVisibility(Board, 2, 2, True);
  Require(TileVisible(Board, 2, 2), 'map state transition was not applied');

  SaveName := Save_Game_Directory + 'dmu-smoke.txt';
  Assign(SaveFile, SaveName);
  Rewrite(SaveFile);
  WriteCampaign(Campaign, SaveFile);
  Close(SaveFile);

  Assign(SaveFile, SaveName);
  Reset(SaveFile);
  LoadedCampaign := ReadCampaign(SaveFile);
  Close(SaveFile);
  Require(LoadedCampaign <> Nil, 'campaign reload failed');
  DeleteFile(SaveName);

  LoadedBoard := FindGameBoard(
    LoadedCampaign,
    NAttValue(LoadedCampaign^.Source^.NA, NAG_SaveFileData, NAS_CurrentGB));
  Require(LoadedBoard <> Nil, 'reloaded current board is missing');
  LoadedEnemy := SeekGearByIDTag(
    LoadedBoard^.Contents, NAG_StoryData, NAS_UniqueID, SmokeEnemyID);
  Require(LoadedEnemy <> Nil, 'reloaded gameplay object is missing');
  Require(LoadedEnemy^.V = GV_Active, 'activated model state was not reloaded');
  Require(TileVisible(LoadedBoard, 2, 2), 'reloaded map state is missing');
  SaveScreenshot(GetEnvironmentVariable('DMU_SMOKE_SCREENSHOT'),
                 LoadedBoard, LoadedEnemy);

  DisposeCampaign(Campaign);
  DisposeCampaign(LoadedCampaign);
  WriteLn(SmokeMarker);
end.
