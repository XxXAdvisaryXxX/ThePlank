{$I Wasplib/osrs.simba}
type
  EActions=enum
  (
    MINE_ROCK,
    BANK_OR_DROP,
    HANDLE_BANK,
    CLOSE_BANK
  );

  TMine=record
    IronRocks,CoalRocks,AddyRocks,MithRocks,RuneRocks,AmmyRocks,TargetRocks:TRSObjectArray;
    BankObj: TRSObject;
    Points: TPointArray;
  end;

procedure TMine.Init;
begin
  Map.Setup([Chunk(Box(46,152,47,151), 0)]);

  self.Points.SetLength(6);
  self.Points[0]:= [12116,11550];//Eastern Iron Spot
  self.Points[1]:= [12084,11546]; //Western Iron Spot
  self.Points[2]:= [12212,11546]; //Rune Rock Spot
  self.Points[3]:= [12052,11558]; //Standing at Bank Chest
  self.Points[4]:= [12084,11546]; //Amethyst South Pit
  self.Points[5]:= [12084,11546]; //Middle Point Between Bank and Rune Rocks

  self.BankObj:= TRSObject.Create(@Map.Walker,[1,1,3],[self.Points[3].offset(-4,0)],['Bank chest']); //Creates BankChest Object

  self.AddyRocks:= TRSObjectArray.Create(ObjectsJSON.GetByName('Adamantite rocks'));
  self.IronRocks:= TRSObjectArray.Create(ObjectsJSON.GetByName('Iron rocks'));
  self.CoalRocks:= TRSObjectArray.Create(ObjectsJSON.GetByName('Coal rocks'));
  self.MithRocks:= TRSObjectArray.Create(ObjectsJSON.GetByName('Mithril rocks'));
  self.RuneRocks:= TRSObjectArray.Create(ObjectsJSON.GetByName('Runite rocks'));
  self.AmmyRocks:= TRSObjectArray.Create(ObjectsJSON.GetByName('Amethyst crystals'));

  self.TargetRocks:= self.IronRocks;
end;

procedure TMine.MineRock(rockObj:TRSObjectArray;anchorPoint:TPoint;range:Integer);//To Call rockObj use self.AmmyRocks or whatever from init.
var                                                                               //use self.Points[0-6] to call anchorPoint. Put Range at 0 for iron. 25 for everything else
  index: Integer;
begin
  index:= rockObj.ClosestIndex(Map.Position.Offset(((Random(-4,4))),28)); //offsets our TPoint due South. To stop From unwanted clicks in F2P Mining Guild

  rockObj[index].Size:=[1,1,2];//Corrects the size
  rockObj[index].Finder.Colors += [$60735E, 2, EColorSpace.HSL, [1.000, 1.000, 1.000]];//Addy Rock Color. Rewrites shitty cache color.
  rockObj[index].Finder.Colors += [$2D3D3D, 1, EColorSpace.HSL, [1.000, 1.000, 1.000]];//Coal Rock Color. Rewrites shitty cache color.
  rockObj[index].Finder.Colors += [$7B5A59, 2, EColorSpace.HSL, [1.000, 1.000, 1.000]];//Mithril Rock Color. Rewrites shitty cache color.
  rockObj[index].Finder.Colors += [$2D3B59, 1, EColorSpace.HSL, [1.000, 1.000, 1.000]];//Iron Rock Color. Rewrites shitty cache color.
  Biometrics.Sleep(10,45,ERandomDir.MEAN); //A tiny biometrics sleep. I like to do these after loading several things.

  if not Map.Walker.Inrange(anchorPoint,range) then
  Map.Walker.WebWalk(anchorPoint,range,0.50,False); //Walks us to our anchorPoint. Mainly used for Iron spots.
  rockObj[index].WalkClick(True,6); //clicks on our closest object twice. If false it finds the next object automatically.
end;

procedure TMine.FullInventory(drop:Boolean); //setting this to true will open bank. False will drop.
var
  slot: Integer;
  slots:TIntegerArray;
begin
  if drop=false then
  begin
    Bank.Open(self.BankObj);
    SleepUntil((Bank.IsOpen = True),200,10000);
    WriteLn 'Bank Should Be Open';
  end;

  if drop=true then
  slots:= (Inventory.Items.IndicesOf(['Iron ore']));
  for slot in slots do
  begin
    Inventory.ShiftDrop(slots,3);
    WriteLn 'Dropped All Ore';
  end;
end;

procedure TMine.HandleBankScreen;
begin
  Bank.DepositInventory;
end;

var
  SmashThatShit:TMine;
begin
  SmashThatShit.Init;
  SmashThatShit.MineRock(SmashThatShit.TargetRocks,SmashThatShit.Points[1],0); //This will walk us to west iron spot and snap us to the spot
  SmashThatShit.FullInventory(False); //Will Open bank.
  SmashThatShit.HandleBankScreen; //Deposits Inventory
end;   
