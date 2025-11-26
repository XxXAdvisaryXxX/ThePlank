{$INCLUDE_ONCE Wasplib/osrs.simba}
Type
  TRSLooter=Record
    DotMSPositions: TPointArray;
    DidRedClick: Boolean;
    LootPoint,LastLootMapPoint: TPoint;
    BlackList:TRSItemArray;
end;
(*
## Looter._FindAllPiles
```pascal
function TRSLooter._FindAllPiles:TPointArray
```
This function finds and sorts red dots by how close they are to us. It's an internal method that should never be called directly.
If for some reason you want the MainScreen Coords Array of Filtered Dots.. It gets cached in TRSLooter.DotMSPositions.

*)
function TRSLooter._FindAllPiles:TPointArray; //Finds and Sorts all red dots on minimap. Never
begin
  self.DotMSPositions:= MiniMap.GetDots(ERSMiniMapDot.ITEM).Sortfrom(Minimap.Center);
  result:= self.DotMSPositions;
end;
(*
## Looter._TakeClosestItem
```pascal
procedure TRSLooter._TakeClosestItem;
```
This procedure clicks the mainscreen drop pile. Also caches map Tpoints of looted pile.
Stored in TRSLooter.LastLootMapPoint

*)
procedure TRSLooter._TakeClosestItem;
begin
  with MainScreen.PlayerBox.Center do  //Sets our lootBox to RIP info from Playerbox.
  begin
    self.LootPoint:= [X, Y+10];  //makes the center of the lootBox lower down for better looting
  end;
  if self.DotMSPositions.Length<1 then exit
  else
    MainScreen.Interact(self.DotMSPositions[0],['']);  //Finds our Filtered MSPosition and hovers the spot
    SleepUntil(MiniMap.IsPlayerMoving=False,200,6000); //SleepUntil is mandatory so we dont ckick until we run to our dots.
    Mouse.Click(self.LootPoint,EMouseButton.RIGHT);  //Right clicks our dot.
    SleepUntil(ChooseOption.IsOpen=True,400,1600); //Just a buffer to make sure our choose option is up
    ChooseOption.Select('Take');
    self.DidRedClick:= MainScreen.RedClicked; //If we pick up an item it returns true and caches that boolean.
    self.LastLootMapPoint:=Map.Position;
end;

(*
## Looter._LootClosestPile
```pascal
procedure TRSLooter._LootClosestPile;
```
An extension of _LootClosestItem. It will check for new items if character redclicks the chooseoption screen.
This will never need to be called directly.

*)
procedure TRSLooter._LootClosestPile;
var
reTrigger1,reTrigger2,reTrigger3,reTrigger4,ReTrigger5: Boolean;
begin
  self._TakeClosestItem;
  if self.DidRedClick then
  begin
    Mouse.Click(self.LootPoint,EMouseButton.RIGHT);
    SleepUntil(ChooseOption.IsOpen=True,400,1600); //Just a buffer to make sure our choose option is up
    ChooseOption.Select('Take');
    reTrigger1:=MainScreen.RedClicked;
    Sleep(100,200);
  end;
  if reTrigger1=True then
  begin
    Sleep(200,325);
    Mouse.Click(self.LootPoint,EMouseButton.RIGHT);
    SleepUntil(ChooseOption.IsOpen=True,400,1600); //Just a buffer to make sure our choose option is up
    ChooseOption.Select('Take');
    reTrigger2:=MainScreen.RedClicked;
    sleep(160,240);
  end;
  if reTrigger2=True then
  begin
    Sleep(200,325);
    Mouse.Click(self.LootPoint,EMouseButton.RIGHT);
    SleepUntil(ChooseOption.IsOpen=True,400,1600); //Just a buffer to make sure our choose option is up
    ChooseOption.Select('Take');
    reTrigger3:=MainScreen.RedClicked;
    sleep(160,240);
  end;
   if reTrigger3=True then
  begin
    Sleep(200,325);
    Mouse.Click(self.LootPoint,EMouseButton.RIGHT);
    SleepUntil(ChooseOption.IsOpen=True,400,1600); //Just a buffer to make sure our choose option is up
    ChooseOption.Select('Take');
    reTrigger4:=MainScreen.RedClicked;
    sleep(160,240);
  end;
   if reTrigger4=True then
  begin
    Sleep(200,325);
    Mouse.Click(self.LootPoint,EMouseButton.RIGHT);
    SleepUntil(ChooseOption.IsOpen=True,400,1600); //Just a buffer to make sure our choose option is up
    ChooseOption.Select('Take');
    reTrigger5:=MainScreen.RedClicked;
    sleep(160,240);
  end;
   if reTrigger5=True then
  begin
    Sleep(200,325);
    Mouse.Click(self.LootPoint,EMouseButton.RIGHT);
    SleepUntil(ChooseOption.IsOpen=True,400,1600); //Just a buffer to make sure our choose option is up
    ChooseOption.Select('Take');
  end;
end;

(*
## Looter.SetupJunkList
```pascal
property TRSLooter.SetupJunkList;
```
Sets up an array of TRSItems that will be dropped after looter has picked them up.

Example:
```pascal
Looter.SetupJunkList:=['Bronze bar', 'Raw swordfish'];
```
*)
property TRSLooter.SetupJunkList(junkList:TRSItemArray);
begin
  self.BlackList:=junkList;
end;
(*
## Looter._DropJunk
```pascal
procedure TRSLooter._DropJunk;
```
A helper function that drops items after picking them up. Should never have to be called directly.

*)
procedure TRSLooter._DropJunk(junkList:TRSItemArray); //helper function that drops unwanted items after picking them up.
var
slot: Integer;
slots:TIntegerArray;
begin
  Inventory.Items.FindAll(junkList, slots);
  for slot in slots do
  begin
    Inventory.Slots.Interact(slot, 'Drop');
    Sleep(120, 200);
  end;
end;

(*
## Looter.WalkAndLoot
```pascal
procedure TRSLooter.WalkAndLoot;
```
Walks to closest red dot pile. Loots upto 5 items. Then drops items declared with TRSLooter.SetupJunkList

Example:
```pascal
Looter.SetupJunkList:=['Bronze bar', 'Raw swordfish'];
Looter.WalkAndLoot;
```
*)
procedure TRSLooter.WalkAndLoot;
begin
  self._FindAllPiles;
  self._LootClosestPile;
  self._DropJunk(self.BlackList);
end;

var
Looter: TRSLooter;
begin

end;                              
