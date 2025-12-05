{$I Wasplib/osrs.simba}
{
WoodChopping Guild
-----OverView------
Banks or Drops Logs at WoodCutting Guild. Simple script.
-----Things Supported---
Special Attack
Maples,Yews,Magics,Willow
AntiBan
-----Things Not Supported Yet-----
WoodBags
BirdNest Looting
RedWoods
------Settings-----
Go Down TCuttingGuild.Init and check the bottom of the code.
You Will Need TO Enter True or False. True Drops. False Banks.
You Will Need To Enter The Type of Tree You Wish To cut. More detailed instructions below.
----DEFAULT SETTINGS----
Will Chop Willows and Drop Them if not altered.
}
const
  MAX_RUNTIME_MINUTES = 360;
type
  EChopperStates=Enum
  (////////////
    CHOP_LOGS,
    OPEN_BANK_DROP,
    DEPOSIT,
    CLOSE_BANK
  );///////////

  TCuttingGuild=Record
    BottomPlot,TopPlot,Ladder,Bank:TPoint;
    Willows,Yews,Maples,Magics,UserTree: TRSObjectArray;
    BankObj:TRSObject;
    ToDrop:Boolean;
  end;

procedure TCuttingGuild.Init;
begin
  Map.Setup([Chunk(Box(24,55,26,54), 0)]);
  Writeln Map.Position;
  self.BottomPlot:=[6500,36430];

  self.Willows:= TRSObjectArray.Create(ObjectsJSON.GetByName('Willow tree'));
  self.Yews:= TRSObjectArray.Create(ObjectsJSON.GetByName('Yew tree'));
  self.Maples:= TRSObjectArray.Create(ObjectsJSON.GetByName('Maple tree'));
  self.Magics:= TRSObjectArray.Create(ObjectsJSON.GetByName('Magic tree'));

  self.BankObj:= TRSObject.Create(@Map.Walker,[1,1,1],[[6368,36530]],['Bank chest']);
  self.BankObj.Finder.Colors+= [$235E75, 1, EColorSpace.HSL, [1.000, 1.000, 1.000]];
  self.BankObj.Finder.Transformer.Grow := 2;

  Inventory.Open;
 //////User Controls
  self.ToDrop:=True;  //<<<<<<True Drops Logs, False Banks Them.
  self.UserTree:= self.Willows; //<<<<Delete The 'Willows' Text To the left(Leaving self.) Replace with Maples,Yews,Magics or Willows
end;

procedure TCuttingGuild.Spec; //see's if spec is available
begin
 If Minimap.HasSpecial then
 minimap.Toggle (ERSMinimapOrb.SPECIAL);
end;

procedure TCuttingGuild.ShouldSpec;//engages spec
begin
  If Minimap.GetPercent(ERSMinimaporb.SPECIAL)=100 then
  self.Spec;
  SleepUntil ((Minimap.GetPercent(ERSMinimaporb.SPECIAL)=0),200,2000);
end;

function TCuttingGuild.Spec100: Boolean;
begin
  If Minimap.GetPercent(ERSMinimaporb.SPECIAL)=100 then
  result:=True;
end;

procedure TCuttingGuild.OpenBank;
begin
  Bank.Open(self.BankObj);
  SleepUntil ((Bank.IsOpen=True),200,4000);
end;

procedure TCuttingGuild.DepositAll;
begin
  if not Bank.IsOpen then Exit;
  Bank.DepositInventory;
  if (Inventory.Slots.CountEmpty<1) then Exit;
end;

function TCuttingGuild._PercentPixelDiff(Area: TBox; WaitTime: Int32): Int32;   //writes pixel shift in %
var
  tLen,sLen: Int32;
begin
  tLen := TPointArray.CreateFromBox(Area, True).Length;
  sLen := Target.GetPixelDifference(WaitTime, Area).Length;
  result := Round((sLen/tLen)*100);
end;

function TCuttingGuild.IsChopping:Boolean;
begin
  If (self._PercentPixelDiff ((mainscreen.PlayerBox),500))>12 then
  result:=True;
end;

procedure TCuttingGuild.ChopTree(objArray:TRSObjectArray);
var
  closestTree: TPointArray;
  index: Integer;
  myPoint,offsetPoint:TPoint;
begin
  if Inventory.IsFull then exit;

  if self.UserTree.Equals(self.Maples) or self.UserTree.Equals(self.Willows) and not Map.Walker.Inrange(self.BottomPlot,50) then
  Map.Walker.WebWalk(self.BottomPlot,0,0.10,False);

  If Minimap.HasSpecial=True and self.Spec100=True then
  self.ShouldSpec;

  Inventory.Open;
  myPoint:=Map.Position;
  offsetPoint:= myPoint.Offset((random(-50,50)),(random(-10,10)));

  index:= objArray.ClosestIndex(offsetPoint);
  closestTree:= objArray[index].Coordinates;

  objArray[index].Finder.Colors +=[$2D5C52, 1, EColorSpace.HSL, [1.000, 1.000, 1.000]]; //yew
  objArray[index].Finder.Colors +=[$1F594F, 1, EColorSpace.HSL, [1.000, 1.000, 1.000]]; //Willow
  objArray[index].Finder.Colors +=[$003967, 2, EColorSpace.HSL, [1.000, 1.000, 1.000]]; //Maple
  objArray[index].Finder.Colors +=[$82B2B5, 2, EColorSpace.HSL, [1.000, 1.000, 1.000]]; //magic

  objArray[index].Interact(['Chop down'],2);

  SleepUntil(self.IsChopping=False,1200,25000);
end;

procedure TCuttingGuild.WhenInventoryIsFull(drop:Boolean);
var
  slot: Integer;
  slots:TIntegerArray;
begin
  if drop=false then
  self.OpenBank;

  if drop=true then
  slots:= (Inventory.Items.IndicesOf(['Maple logs','Willow logs','Yew logs']));
  for slot in slots do
  begin
    Inventory.ShiftDrop(slots,3);
  end;
end;

function TCuttingGuild.GetNextAction:EChopperStates;
begin
  writeln Inventory.Slots.CountEmpty;
  if Bank.IsOpen and (Inventory.Slots.CountEmpty > 27) then
  Exit (EChopperStates.CLOSE_BANK);

  if Bank.IsOpen and (Inventory.Slots.CountEmpty = 0) then
  Exit (EChopperStates.DEPOSIT);

  if (Inventory.Slots.CountEmpty = 0) and not Bank.IsOpen then
  Exit (EChopperStates.OPEN_BANK_DROP);

  if (Inventory.Slots.CountEmpty<1) and not Bank.IsOpen then
  Exit (EChopperStates.CHOP_LOGS);

  if false then Exit;
end;

procedure TCuttingGuild.Run;
var
  action: EChopperStates;
begin
  while GetTimeRunning < (MAX_RUNTIME_MINUTES * ONE_MINUTE) do
  begin
    action := Self.GetNextAction;
    WriteLn(action);
    case action of
      EChopperStates.CHOP_LOGS: self.ChopTree(self.UserTree);
      EChopperStates.OPEN_BANK_DROP: self.WhenInventoryIsFull(self.ToDrop);
      EChopperStates.DEPOSIT: self.DepositAll;
      ECHopperStates.CLOSE_BANK: Bank.Close(False);
    end;
    AntiBan.DoAntiban;
  end;
end;

var
  TemplateConfig: TConfigJSON;

procedure TScriptForm.Init();
begin
  TemplateConfig.Setup('scripts' + PATH_SEP + 'my-script-name');

  self.Setup('WC GUild');

  self.CreateAntibanTab();
  self.Run();
end;

var
  CuttingGuild:TCuttingGuild;
  Form: TScriptForm;
begin
  Form.Init;
  CuttingGuild.Init;
  CuttingGuild.Run;
end;
       
