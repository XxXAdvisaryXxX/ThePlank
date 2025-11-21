{
-------------Makes Unfinished Potions From Grimy Herbs----------
Items Needed: Grimy Herbs, Vials of Water

DEFAULT VALUES: CAN ALL BE CHANGED BELOW IN THERB.INIT

RESTOCK THRESHOLD: 500 (At 500 grimy herbs in bank, will restock);
BUY AMOUNT: 2,000 (Buys 2000 herbs for turning into unfinished potions)
HERB TYPE: Torstol (Can be changed below as well)

All 3 can be programmed super easily. Check the code below for more info.

Instructions for changing herb type.. Scroll down to the /////// box in THerb.Init.
  -Read the instructions there. It's simple as changing two words.

*Runs To GE to Buy Herbs.
*Runs To Varrok East Bank To Degrime and clean.
 }

{$I Wasplib/osrs.simba}
const
  MAX_RUNTIME_MINUTES = 360;
type
//Enum used in assign states function. Youll never need to change these.
  EPotionStates= enum(
    OPEN_BANK,
    DEPOSIT_POTIONS,
    HANDLE_BANK,
    CLOSE_BANK,
    CLEAN_COMBINE,
    RESTOCK
  );

  ERestockStates= enum(
    BUY_HERBS,
    //BUY_VIALS,
    SELL_POTIONS,
    WALK_TO_GE,
    EXIT_RESTOCK
  );
 THerb = record
    Actions, MaxTime, MaxActions, MaxLevel: UInt64; //Used for future forms.
    FormSetting: Boolean; //used for future forms
    TargetGHerb,TargetCHerb,Unf,NotedUnf:TRSItem;//used for storing herb and potion TRSitem information below.
    TargetArray:TRSItemArray;  //Used for a specific function within TRSHerblore
    BankPoint,GEPoint:TPoint;
    BankCountCache:TIntegerArray;
      Restock:Record
        BuyHerbQuant,BuyVialQuant,BuyPrice,SellPrice,ThreshHold:Integer;
        Clerk:TRSObject;
        UnfinishedBankItem:TRSBankItem;
      end;
  end;

 function TItemData.GetPrice(item: TRSItem): Integer; override; //lib override to insta buy herbs.
var
  id: String;
  json: TJSONItem;
  lo, hi: Integer;
begin
  id := Self.GetTradeableID(item);
  if id = '' then Exit;

  case item of
    '995', '996', '997', '998', '999',
    '1000', '1001', '1002', '1003', '1004': Exit(1);
  end;

  Self.Reload();
  if Self.Disabled then Exit;
  if not Self.PricesJSON.Item[0].GetObject(id, json) then Exit;

  hi := json.Item[0].AsInt; //"high" key
  lo := json.Item[2].AsInt; //"lo" key

  if lo = hi then Exit(lo);
  if lo = 0 then Exit(hi);
  if hi = 0 then Exit(lo);

  Result := (hi-5);  // this will buy herbs for 100gp above the lowest sell price in last 15 minutes
end;
/////////////////CHANGE HERBS AND THRESHOLDS BELOW\\\\\\\\\\\\\\\\\\\\\
procedure THerb.Init;
begin
//////////////////////////////////////// Change The Names Here To desired herb
  self.TargetGHerb:='Grimy torstol';// Make sure you follow the format with uppercase and lowercase.
  self.TargetCHerb:='Torstol';      // The first letter of every herb will be upper or lower case. Pay close attention
///////////////////////////////////////

  self.Restock.ThreshHold:=350; //Changes when you resupply. If threshold is 500, at 500 grimy herbs it restocks at ge.
  self.Restock.BuyHerbQuant :=2000; //Change This to the number of Grimy Herbs wish to buy.
  self.Restock.BuyVialQuant:= 6000; //not used atm. But will be in the future.

 ////////////////////////////////////////DO NOT CHANGE BELOW THIS\\\\\\\\\\\\\\\\\\\
  RSClient.EnableRealInput;
  Map.Setup([ERSChunk.VARROCK]);

  self.TargetArray:= [self.TargetGHerb];
  self.Unf:= (self.TargetCHerb+' potion (unf)');       ///These 3 are used to assign herb types to records for easy access
  self.NotedUnf:=('noted '+self.TargetCHerb+' potion (unf)');

  self.Restock.UnfinishedBankItem:= new TRSBankItem(self.unf, -1);    //used for handling the noted versions when selling potions.
  self.Restock.UnfinishedBankItem.Noted:=True;

  self.Restock.SellPrice :=Itemdata.GetPrice(self.Unf);   //How Much To Sell Unfinished For
  self.Restock.BuyPrice := Itemdata.GetPrice(self.TargetGHerb);//How Much To Buy Grimy Herbs For

  self.Restock.Clerk:= TRSObject.Create (@Map.Walker, [3,3,7], [[8560,36478]], ['Grand exchange booth']);
  self.Restock.Clerk.Finder.Colors+= [$6C8796, 2, EColorSpace.RGB, [1.000, 1.000, 1.000]];

  self.GEPoint:= [8560,36490];
  self.BankPoint:=[8916,36750];
end;

//////////////////////HELPER FUNCTIONS AND PROCEDURES\\\\\\\\\\\\\\\\\\\\\\\\\\\
procedure THerb.Collect;  //This is a helper function to collect herbs from the collection box
begin
  CollectionBox.Open;
  Sleep(300,450);
  CollectionBox.CollectToBank;
  Sleep(350,550);
  Keyboard.KeyPress(EKeyCode.ESCAPE);
end;

function THerb.BankCount:TIntegerArray; //Takes the count of items and caches the numbers in Record of THerb.BankCountCache
begin
  Result+= Bank.Items.ReadStack(self.TargetGHerb); //reads the target Grimy Herb count and caches it. Make sure bank is open.
  Result+= Bank.Items.ReadStack(self.Unf);      //  reads the amount of unfinished potions in the bank.
  Result+= Bank.Items.ReadStack ('Vial of water');
  self.BankCountCache:= Result;
end;

function THerb.IsItemDepleted(Item:TRSItem):boolean;//Returns true if inventory item is depleted. Used as a check when combining potions.
begin
  if Inventory.Items.Count(Item)<1 then
  result:=true;  //if true we combined the items.
    if result=false then
    Writeln 'Waiting For Unfinished Potions';  //We still waiting.
end;

procedure THerb.CleanHerbs(Herb:TRSItemArray); //helper function that cleans herbs.
 var
  slot: Integer;
  slots: TIntegerArray;
begin
  Writeln ('Cleaning Herb:'+self.TargetGHerb);
  Inventory.Items.FindAll(Herb, slots);
      for slot in slots do
      begin
        Inventory.Slots.Interact(slot, 'Clean');
        sleep(25,120);
      end;
end;

procedure THerb.MakeUnfinished(Herb:TRSItem);//combines herbs with vials of water!
var
vial:TRSItem;
begin
  vial:='Vial of water';
  Inventory.Combine(Herb,vial);
  sleep(1200,1402);
  Keyboard.KeyPress(EKeyCode.NUM_1);
  sleepuntil((self.IsItemDepleted(Herb)=True),5000,10000);
end;

procedure THerb.WithdrawForUnfinished(Herb:TRSItem;Vials:Boolean);//Specialized procedure that will withdraw either 28 herbs or 14 vials and 14 herbs if 2nd parameter is true.
var
h,v:TRSBankItem;
vial:TRSItem;
amount: Integer;
begin
  vial:='Vial of water';
  While Vials=False do

  begin
    amount:=28;
    h:= new TRSBankItem(Herb,Amount);
    Bank.Withdraw (h,True,True,True);
    exit;
  end;
    While Vials=True do

    begin
      if inventory.Items.Contains(self.TargetCHerb) then Bank.DepositInventory;
      sleepuntil (Bank.IsOpen=True,200,2000);
      amount:=14;
      h:= new TRSBankItem(Herb,Amount);
      v:= new TRSBankItem(Vial,Amount);
      Bank.Withdraw (h,True,True,True);
      Bank.Withdraw (v,True,True,True);
      writeln self.BankCount;
      exit;
    end;
end;

procedure THerb.OpenBank;//opens bank and makes sure things are withdrawn properly.
begin
  if not Map.Walker.Inrange(Self.BankPoint,35) then Map.Walker.WebWalk(self.BankPoint,4,0,False);

  Sleep (1000,2000);
  Bank.open(True);
  Sleepuntil ((Bank.IsOpen),50,2000);
  if Inventory.Items.ContainsAny([self.TargetGHerb,self.TargetCHerb, 'Vial of water']) then Bank.DepositInventory;
    if bank.isopen then writeln self.BankCount
    else exit;
end;

procedure THerb.Deposit;
begin
  if not Bank.IsOpen then exit;
  Bank.DepositInventory;

  if Bank.IsOpen and (Inventory.Items.Contains(self.Unf)) then
  Bank.DepositInventory;   //Double checks and makes sure items properly deposited.
end;

procedure THerb.CloseBank; //Closes the bank and caches the counts.
begin
  if Bank.Isopen then writeln self.BankCount;
  Bank.Close(False);
  Sleepuntil ((not Bank.Isopen),25,2000);
end;

procedure THerb.CleanandCombine; //Cleans and combines herbs ingame.
begin
  self.CleanHerbs(self.TargetArray);
  self.MakeUnfinished(self.TargetCHerb);
end;
/////////////////////////////GE RELATED HELPER FUNCTIONS\\\\\\\\\\\\\\
function TRSGrandExchangeOffer.CreateBuyOffer(itemName: String; price, quantity: Integer = -1) : Boolean;Override;
begin
  if not Self.IsOpen() then Exit;
  if (Self.OfferInterface <> EGEOfferInterface.SETUP) or (Self.OfferType <> EGEOfferType.BUY) then Exit;

  if not GrandExchangeChat.WaitOpen(2000, 250) then Exit;
  if not GrandExchangeChat.SearchText[itemName] then Exit;
  if not GrandExchangeChat.Click(itemName) then Exit;
  if not SleepUntil(Self.Item.ToLower() = itemName.ToLower(), 250, 6000) then Exit;

  if (quantity <> -1) and not Self.Quantity[quantity] then Exit;
  if (price <> -1) and not Self.Price[price] then Exit;

  Result := Self.Confirm();
end;

procedure THerb.OrderHerbs;  //This procedure handles the ordering of herbs.
var
  i:Integer;
begin
  Minimap.CompassDegrees := 360;  //helps with finding the bank.
  if not Map.Walker.Inrange(self.GEPoint,25) then self.WalkToGE; //checks to make sure we at ge. if not it walks there.
  if Bank.IsOpen then Bank.Close(False);  //this is a check. Sometimes player walks to ge with full inventory and must deposit. The deposit action doesnt close the bank sometimes

  self.Restock.Clerk.Interact (['Exchange'],5);    //clicks clerk
  sleepuntil((GrandExchange.Isopen=True),100,4000);    //makes sure ge is open
  if not GrandExchange.isopen then exit else;  //emergency exit incase the ge isnt open
  i:= GrandExchange.IndexOfEmptySlot;  //Finds the first empty open slot in G.E  and stores it in i var
  begin
    GrandExchange.Slots[i].Buy(); //clicks the i slot buy interface
    Sleep(5000,7000);  //slow delay for any lag.
    GrandExchangeoffer.CreateBuyOffer(self.TargetGHerb,self.Restock.BuyPrice,self.Restock.BuyHerbQuant); //puts in order for herbs.
    Sleep(5000,6000);
    self.BankCountCache[0]:= (self.BanKCountCache[0]+self.Restock.BuyHerbQuant); //Makes sure the cached number of unfinished doesnt get messed with when state changes.
    self.Collect;
    Bank.Open;
      if Bank.Isopen then writeln self.BankCount
      else exit;
    Bank.Close;
  end;
end;

procedure THerb.WalkToGE;
begin
  Map.Walker.Webwalk(self.GEPoint);
end;

procedure THerb.WalkToBankBooth;
begin
  Map.Walker.Webwalk(self.BankPoint);
end;

procedure THerb.SellUnfinished;
var
  i:Integer;
begin
  Minimap.CompassDegrees := 360;
  Bank.Open;
  Sleepuntil ((bank.IsOpen),50,8000);
  Bank.DepositInventory;
    if bank.isopen then writeln self.BankCount
    else exit;

  Bank.Withdraw(self.Restock.UnfinishedBankItem,True,True,True);
  Bank.Close(False);
  Sleep (400,600);
  begin
    self.Restock.Clerk.Click(True,5);
    sleepuntil((GrandExchange.Isopen=True),100,4000);
    if not GrandExchange.isopen then exit else;
    i:= GrandExchange.IndexOfEmptySlot;
    begin
      GrandExchange.Slots[i].Sell();
      Inventory.Items.Interact (self.NotedUnf,'Offer');
      Sleep(2000,4000);
      GrandExchangeOffer.Price[self.Restock.SellPrice-250];
      Sleep(3000,4000);
      GrandExchangeOffer.Confirm;
      Sleep(4000,5000);
      self.BankCountCache[1]:= (self.BanKCountCache[1]-self.BanKCountCache[1]);
      GrandExchange.Close(False);
      Sleep(5000,6000);
      Bank.Open;
      Sleep(4000,5000);
        if not bank.isopen then
        writeln self.BankCount else
        exit;

      Sleep(5000,7000);
    end;
  end;
end;

procedure THerb.ExitStock;
begin
  self.OpenBank;
  self.BankCountCache[1]:=(self.Restock.ThreshHold+25);
end;

procedure THerb.CacheCount;//First Procedure used when starting script. Gets a proper  inventory count before continuing.
var
h:TRSBankItem;
amount: Integer;
begin
  amount:=1;
  h:= new TRSBankItem(self.TargetGHerb,Amount);
  Bank.Open(True);
  Bank.DepositInventory;
  Bank.Withdraw (h,True,True,True);
    if bank.isopen then self.BankCount
    else exit;
  Bank.DepositInventory;

  Bank.Close(False);
  Writeln self.BankCountCache[0];
end;

////////////////////////////////ASSIGN STATES SECTION///////////////////////////////////////////////
function THerb.AssignRestockStates:ERestockStates;
begin
  if self.BankCountCache[0]=-1 then exit; //Exits if cache is wrong

    if not Map.Walker.InRange(self.GEPoint,20) and (self.BankCountCache[0]<self.Restock.ThreshHold)
    then exit(ERestockStates.WALK_TO_GE);

      if (self.BankCountCache[1]>1) and (self.BankCountCache[0]<self.Restock.ThreshHold)
      then exit(ERestockStates.SELL_POTIONS);

        if (self.BankCountCache[0]<self.Restock.ThreshHold) and (self.BankCountCache[1]<self.Restock.ThreshHold)
        and Map.Walker.InRange(self.GEPoint,50)
        then exit(ERestockStates.BUY_HERBS);

            if (self.BankCountCache[0]>self.Restock.ThreshHold) and (self.BankCountCache[1]<self.Restock.ThreshHold)
            and not (Map.Walker.Inrange(self.BankPoint,25))
            then exit(ERestockStates.EXIT_RESTOCK);
end;

procedure THerb.RestockRun;
  var
  action:ERestockStates;
begin
  while GetTimeRunning < (MAX_RUNTIME_MINUTES * ONE_MINUTE) do

  begin
    action := Self.AssignRestockStates;
    WriteLn(action);
    case action of
      ERestockStates.WALK_TO_GE: self.WalkToGE;
      ERestockStates.SELL_POTIONS: self.SellUnfinished;
      ERestockStates.BUY_HERBS: self.OrderHerbs;
      ERestockStates.EXIT_RESTOCK: exit;
    end;
    Antiban.DoAntiban;
  end;
end;

function THerb.AssignPotionStates:EPotionStates; //Assigns Enums For THerb.MainRun
begin
  if (self.BankCountCache[0]<self.Restock.ThreshHold) and (self.BankCountCache[1]<self.Restock.ThreshHold)
  then exit(EPotionStates.RESTOCK);

    if Bank.IsOpen and (Inventory.Items.Contains (self.TargetGHerb)) and (Inventory.Items.Contains ('Vial of water'))
    then exit (EPotionStates.CLOSE_BANK);

      if Inventory.Items.Contains ('Vial of water') and Inventory.Items.Contains (self.TargetGHerb)
      then exit(EPotionStates.CLEAN_COMBINE);

        if self.IsItemDepleted(self.TargetCHerb) and Inventory.Items.Contains (self.Unf) and not Bank.IsOpen
        then exit(EPotionStates.OPEN_BANK);

          if Bank.IsOpen and Inventory.Items.Contains (self.Unf)
          then exit (EPotionStates.DEPOSIT_POTIONS);

            if Bank.IsOpen and not Inventory.Items.Contains (self.Unf) and Map.Walker.Inrange(self.BankPoint,25)
            then exit (EPotionStates.HANDLE_BANK);

              if Bank.IsOpen and (Inventory.Items.Contains (self.TargetGHerb)) and (Inventory.Items.Contains ('Vial of water'))
              then exit (EPotionStates.CLOSE_BANK);
end;


procedure THerb.MainRun; //Uses previous function to link states to 1 to 1 actions.
  var
  action: EPotionStates;

begin
 self.CacheCount; //Intiantes The Opening Cache Sequence.
  while GetTimeRunning < (MAX_RUNTIME_MINUTES * ONE_MINUTE) do

  begin
    action := Self.AssignPotionStates;
    WriteLn(action);
      case action of
        EPotionStates.CLEAN_COMBINE:self.CleanandCombine;
        EPotionStates.OPEN_BANK:self.OpenBank;
        EPotionStates.HANDLE_BANK:self.WithdrawForUnfinished(self.TargetGHerb,True);
        EPotionStates.RESTOCK: self.RestockRun;
        EPotionStates.CLOSE_BANK:self.CloseBank;
        EPotionStates.DEPOSIT_POTIONS: self.Deposit;
      end;
      Antiban.DoAntiban;
    end;
end;
///////////////////////////////////FORM STUFF\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
Var
  TemplateForm: TScriptForm;
  TemplateConfig: TConfigJSON;

procedure TScriptForm.Init();
begin
  TemplateConfig.Setup('scripts' + PATH_SEP + 'my-script-name');

  Self.Setup('DEGRIME AND MAKE UNFINISHED POTIONS');

  Self.CreateAntibanTab();
  Self.Run();
end;
//////Final Run Loop
 var
 run:THerb;
begin
  TemplateForm.Init();
  run.Init;
  run.MainRun;
end.

                                           
