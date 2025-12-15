{$I Wasplib/osrs.simba}
type
  EStates=enum
  (
    WALK_TO_BANK
  );

  TSteal=record
    ObjArray:TRSObjectArray;
    EntArray:TRSEntityArray;
    Points: TPointArray;
    Items:TRSItemArray;
  end;

procedure TSteal.Init;
begin
  Map.Setup([ERSChunk.ARDOUGNE]);
  WriteLn Map.Position;

  self.Points.SetLength(6);
  self.Points[0]:=[10676,37190];//Bakers Stall SafeSpot Point
  self.Points[1]:=[10616,37298];//Bank Point

  self.ObjArray.SetLength(6);
  self.ObjArray[0]:= TRSObject.Create(@Map.Walker,[2,2,10],[self.Points[0].Offset(-6,0)],['Bakers stall']);//BankerStall

  self.EntArray.SetLength(6);
  self.EntArray[0]:= TRSEntity.Create(@Map.Walker,[1,1,6],40,[self.Points[0].Offset(-24,8)],['Guard'],[ERSMiniMapDot.NPC]);//Guard Ent
  self.EntArray[0].Finder.Colors+= [$2A358B, 4, EColorSpace.RGB, [1.000, 1.000, 1.000]];//Guards Colors.

  self.EntArray[1]:= TRSEntity.Create(@Map.Walker,[1,1,6],85,[self.Points[0].Offset(-24,8)],['Knight of ardougne'],[ERSMiniMapDot.NPC]);//Knight ent
  self.EntArray[1].Finder.Colors +=[$EF2A93, 3, EColorSpace.HSL, [1.000, 1.000, 1.000]];

  self.Items.SetLength(6);
  self.Items[0]:= 'Cake';
  self.Items[1]:= 'Bread';
  self.Items[2]:= 'Chocolate slice';
  self.Items[3]:= '2/3 cake';
  self.Items[4]:= 'Slice of cake';

  //showontarget(self.EntArray[1]);
end;
function TSteal.IsStunned:Boolean;
var
  tmp: T2DPointArray;
  msColor: TColorFinder;
begin
  Sleep(400,600);
  msColor.Colors += ColorTolerance($2AE2EF, 7, EColorSpace.RGB, [1.000, 1.000, 1.000]);
  result:= msColor.Find(tmp,[MainScreen.PlayerBox]);
end;

function TSteal.ShouldSteal:Boolean;
begin
  if Inventory.Items.Count(self.Items)<3 then
  result:=True;
end;

procedure TSteal.EatFood(food:TRSItemArray);
var
  slots:TIntegerArray;
  slot,attempts:Integer;
begin
  for attempts:= 1 to 100 do
  begin
    slots:= Inventory.Items.IndicesOf(food);
    for slot in slots do
    begin
      Inventory.Items.Interact(slot,'Eat');
      if MiniMap.GetHPPercent > 95 then
      exit;
    end;
  end;
end;

function TSteal.StealFromStall(stallObj:TRSObject;drop:Boolean):Boolean;
var
  slots:TIntegerArray;
  slot:Integer;
begin
  while Inventory.Slots.CountEmpty > 3 do
  begin
    if not Map.Walker.InRange(self.Points[0],0) then
    Map.Walker.WebWalk(self.Points[0],0,0,False);

    Inventory.Open;
    result:= stallObj.Interact(['Steal-from'],1);
    Sleep(1200,1450);
  end;
  if drop=True then
  begin
    slots:= Inventory.Items.IndicesOf(self.Items);
    for slot in slots do
    begin
      Inventory.Items.Interact(slot,'Drop');
    end;
  end;
end;

procedure TSteal.StealFromNPC(npc:TRSEntityArray;num:Integer);
var
  int: Integer;
  npcClass:TRSEntity;
  tmp: T2DPointArray;
begin
  for int:= 1 to 20000 do
  begin
    if self.ShouldSteal=True then//Checks to see if we have enough food.
    begin
      self.StealFromStall(self.ObjArray[0],False);//if not enough food; then start stealfromstall procedure
    end;

    npcClass:= npc[num];//creates our NPC obj from our array parameter.
    Sleep(10,35);
    npcClass.WalkInteract(['Pickpocket'],1);
    Sleep(400,600);

    if XPBar.EarnedXP then  //checks xp bar for drop
    Continue else  //if we gain xp we continue;
    SleepUntil((self.IsStunned=False),5,10000);//if we dont gain xp, we suspect we are stunned and do another check.

    if (Inventory.Items.ReadStack('Coin pouch'))>0 then
    Inventory.Items.Interact('Coin pouch','Open-all');//clears coin pouches. Have to set so low for rouge coin pouches in new slots.

    while MiniMap.GetHPPercent<60 do  //if our health drop belows 60% we eat up to 95%
    begin
     self.EatFood(self.Items);
    end;
  end;
end;

var
  Steal:TSteal;
begin
  Steal.Init;
  Steal.StealFromNPC(Steal.EntArray,0);
end;    
