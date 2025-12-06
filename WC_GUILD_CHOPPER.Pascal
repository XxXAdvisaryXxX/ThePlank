{$I Wasplib/osrs.simba}
{
WoodChopping Guild
-----OverView------
Banks or Drops Logs at WoodCutting Guild. Simple script.
-----Things Supported---
Special Attack
Maples,Yews,Willow
AntiBan
-----Things Not Supported Yet-----
WoodBags
BirdNest Looting
RedWoods,Magics
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
  EChopperStates=Enum //Chopper States. Used in function GetNextAction and Run.
  (////////////
    CHOP_LOGS,
    OPEN_BANK_DROP,
    DEPOSIT,
    CLOSE_BANK
  );///////////

  TCuttingGuild=Record
    BottomPlot,YewPoint,MagicPoint,Ladder,Bank:TPoint;   //Some are unused; but will be added later.
    Willows,Yews,Maples,Magics,UserTree: TRSObjectArray;
    BankObj:TRSObject;
    ToDrop:Boolean;
  end;

procedure TCuttingGuild.Init;
begin
  Map.Setup([Chunk(Box(24,55,26,54), 0)]); //sets up our map and walker.
  self.BottomPlot:=[6500,36430];  //These 3 Just set TPoints Manually for walker spots.
  self.MagicPoint:=[6316,36478];
  self.YewPoint:=[6376,36474];

  self.Willows:= TRSObjectArray.Create(ObjectsJSON.GetByName('Willow tree'));  //These 4 just setup objectarrays for every tree type.
  self.Yews:= TRSObjectArray.Create(ObjectsJSON.GetByName('Yew tree'));        //can do the same with single objects
  self.Maples:= TRSObjectArray.Create(ObjectsJSON.GetByName('Maple tree'));
  self.Magics:= TRSObjectArray.Create(ObjectsJSON.GetByName('Magic tree'));

  self.BankObj:= TRSObject.Create(@Map.Walker,[1,1,1],[[6368,36530]],['Bank chest']); //Manually creates bankobj.
  self.BankObj.Finder.Colors+= [$235E75, 1, EColorSpace.HSL, [1.000, 1.000, 1.000]];  //sets our color
  self.BankObj.Finder.Transformer.Grow := 2; //  grows our color out.

  Inventory.Open;
 //////User Controls
  self.ToDrop:=True;  //<<<<<<True Drops Logs, False Banks Them.
  self.UserTree:= self.Willows; //<<<<Delete The 'Willows' Text To the left(Leaving self.) Replace with Maples,Yews,Magics or Willows
end;

procedure TCuttingGuild.WalkTo(point:TPoint); //helper function used to walk around.
begin
  if not Map.Walker.InRange(point,28) then
  Map.Walker.WebWalk(point,4,1,False);
end;

procedure TCuttingGuild.Spec; //see's if spec is available
begin
 If Minimap.HasSpecial then
 Minimap.Toggle (ERSMinimapOrb.SPECIAL);
end;

procedure TCuttingGuild.ShouldSpec;//engages spec
begin
  If Minimap.GetPercent(ERSMiniMapOrb.SPECIAL)=100 then
  self.Spec;
  SleepUntil ((Minimap.GetPercent(ERSMiniMapOrb.SPECIAL)=0),200,2000);
end;

function TCuttingGuild.Spec100: Boolean; //See's if our spec is full or not
begin
  If Minimap.GetPercent(ERSMiniMapOrb.SPECIAL)=100 then
  result:=True;
end;

procedure TCuttingGuild.OpenBank; //Opens bank obviously.
begin
  Bank.Open(self.BankObj);
  SleepUntil ((Bank.IsOpen=True),200,4000);
end;

procedure TCuttingGuild.DepositAll; //deposits all items. Has a check to make sure bank is open and items get deposited.
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

function TCuttingGuild.IsChopping:Boolean; //If our pixel shift is above 12% in playerbox; then we return true.
begin
  If (self._PercentPixelDiff ((Mainscreen.PlayerBox),500))>12 then
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
  Map.Walker.WebWalk(self.BottomPlot,0,0.10,False);  //Basically puts us by the willows and maples if needed.
  Sleep(20,40);

  If Minimap.HasSpecial=True and self.Spec100=True then
  self.ShouldSpec; //checks to see if our spec is availabe then activates

  Inventory.Open;
  myPoint:=Map.Position;
  offsetPoint:= myPoint.Offset((random(-50,50)),(random(-40,40)));

  index:= objArray.ClosestIndex(offsetPoint);
  closestTree:= objArray[index].Coordinates;

  objArray[index].Finder.Colors +=[$2D5C52, 1, EColorSpace.HSL, [1.000, 1.000, 1.000]]; //yew
  objArray[index].Finder.Colors +=[$1F594F, 1, EColorSpace.HSL, [1.000, 1.000, 1.000]]; //Willow
  objArray[index].Finder.Colors +=[$003967, 2, EColorSpace.HSL, [1.000, 1.000, 1.000]]; //Maple
  objArray[index].Finder.Colors +=[$214E47, 2, EColorSpace.HSL, [1.000, 1.000, 1.000]]; //magic
  objArray[index].Finder.Transformer.Grow := 2;
  Sleep(20,60);

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
  Sleep(40,100);

  if Bank.IsOpen and (Inventory.Slots.CountEmpty = 0) then
  Exit (EChopperStates.DEPOSIT);
  Sleep(40,100);

  if (Inventory.Slots.CountEmpty = 0) and not Bank.IsOpen then
  Exit (EChopperStates.OPEN_BANK_DROP);
  Sleep(40,100);

  if (Inventory.Slots.CountEmpty<1) and not Bank.IsOpen then
  Exit (EChopperStates.CHOP_LOGS);
  Sleep(40,100);

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

  self.Setup('WC Guild');

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
