{
-------------Makes Unfinished Potions From Grimy Herbs----------
Items Needed: Grimy Herbs, Vials of Water

Default Values: Will Enter Restock Phase when grimy herbs in bank fall below 500.
  Will buy 4k herbs at a time. This can be changed below in THerb.Init. Check comments. Will also sell any unfinished potions.

Instructions for changing herb type.. Scroll down to the /////// box in THerb.Init.
  -Read the instructions there. It's simple as changing two words.

*Works at GE (Crowded GE's can cause glitches not recommended)
*Varrok west bank. (Sometimes if you in stalls next to doors, it wants to open the door)
*Varrok East Bank (Best Place to run in my opinion)
 }
{$I Wasplib/osrs.simba}
const
  MAX_RUNTIME_MINUTES = 360;
type
//Enum used in assign states function. Youll never need to change these.
  EPotionStates= enum(
    OPEN_BANK_AND_DEPOSIT,
    WITHDRAW_ITEMS_CLOSE_BANK,
    CLEAN_COMBINE,
    RESTOCK
  );

  ERestockStates= enum(
    BUY_HERBS,
    BUY_VIALS,
    SELL_POTIONS,
    WALK_TO_GE
  );
 THerb = record
    Actions, MaxTime, MaxActions, MaxLevel: UInt64; //Used for future forms.
    FormSetting: Boolean; //used for future forms
    TargetGHerb,TargetCHerb,Unf,NotedUnf:TRSItem;//used for storing herb and potion TRSitem information below.
    TargetArray:TRSItemArray;  //Used for a specific function within TRSHerblore
    BankPoint,GEPoint:TPoint;
    BankCountCache:TIntegerArray;
      Restock:Record
        BuyHerbQuant,BuyVialQuant,BuyPrice,SellPrice:Integer;
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

  Result := (hi+100);
end;
{***********CHANGE HERBS BELOW*************}
procedure THerb.Init;
begin
  Map.Setup([ERSChunk.VARROCK]);
////////////// //////////////////////// Change The Names Here To desired herb
{Here}  self.TargetGHerb:='Grimy torstol';// Make sure you follow the format with uppercase and lowercase. Change the words inside the quotes and leave the semicolons.
{Here}  self.TargetCHerb:='Torstol';      // The first letter of every herb will be upper or lower case. Pay close attention
///////////////////////////////////////////
  self.TargetArray:= [self.TargetGHerb];
  self.Unf:= (self.TargetCHerb+' potion (unf)');
  self.NotedUnf:=('noted '+self.TargetCHerb+' potion (unf)');

  self.Restock.UnfinishedBankItem:= new TRSBankItem(self.unf, -1);
  self.Restock.UnfinishedBankItem.Noted:=True;

  self.Restock.BuyVialQuant:= 6000;
{Here}self.Restock.BuyHerbQuant :=4000; //Change This to the number of Grimy Herbs wish to buy.

  self.Restock.SellPrice :=Itemdata.GetPrice(self.Unf);   //How Much To Sell Unfinished For
  self.Restock.BuyPrice := Itemdata.GetPrice(self.TargetGHerb);//How Much To Buy Grimy Herbs For

  self.Restock.Clerk:= TRSObject.Create (@Map.Walker, [3,3,7], [[8560,36478]], ['Grand exchange booth']);
  self.Restock.Clerk.Finder.Colors+= [$6C8796, 2, EColorSpace.RGB, [1.000, 1.000, 1.000]];

  self.GEPoint:= [8560,36490];
  self.BankPoint:=[8916,36750];
end;

//////////////////////HELPER FUNCTIONS AND PROCEDURES\\\\\\\\\\\\\\\\\\\\\\\\\\\
procedure THerb.Collect;
begin
  CollectionBox.Open;
  Sleep(300,450);
  CollectionBox.CollectToBank;
  Sleep(350,550);
  Keyboard.KeyPress(EKeyCode.ESCAPE);
end;

function THerb.BankCount:TIntegerArray;
begin
  Result+= Bank.Items.ReadStack(self.TargetGHerb);
  Result+= Bank.Items.ReadStack(self.Unf);
  Result+= Bank.Items.ReadStack ('Vial of water');
  self.BankCountCache:= Result;
end;

function THerb.IsItemDepleted(Item:TRSItem):boolean;//Returns true if inventory item is depleted. Helper function
begin
  if Inventory.Items.Count(Item)<1 then
  result:=true;
    if result=false then
    Writeln 'Waiting For Unfinished Potions';
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
      amount:=14;
      h:= new TRSBankItem(Herb,Amount);
      v:= new TRSBankItem(Vial,Amount);
      self.BankCount;
      Bank.Withdraw (h,True,True,True);
      Bank.Withdraw (v,True,True,True);
      exit;
    end;
end;

procedure THerb.OpenBank;//opens bank and makes sure things are withdrawn properly.
begin
  if not Map.Walker.Inrange(Self.BankPoint,20) then Map.Walker.Webwalk(self.BankPoint,4,0,False);
  Bank.open(True);
  Sleepuntil ((bank.IsOpen),50,2000);
  Self.BankCount;
  Bank.DepositInventory;
  Sleep(40,80);
    If Inventory.Items.Contains(self.Unf) then
    Bank.DepositInventory;
end;

procedure THerb.BankTransaction; //Completes the banking transactions.
begin
  self.WithdrawForUnfinished(self.TargetGHerb,True);
  Bank.Close(False);
  sleep (80,100);
  Sleepuntil ((not Bank.Isopen),25,2000);
end;

procedure THerb.CleanandCombine; //Cleans and combines herbs ingame.
begin
  self.CleanHerbs(self.TargetArray);
  self.MakeUnfinished(self.TargetCHerb);
end;
/////////////////////////////GE RELATED HELPER FUNCTIONS\\\\\\\\\\\\\\
procedure THerb.OrderHerbs;
var
  i:Integer;
begin
  if Bank.IsOpen then Bank.Close(False);

  self.Restock.Clerk.Click(True,5);
  sleepuntil((GrandExchange.Isopen=True),100,4000);
  if not GrandExchange.isopen then exit else;
  i:= GrandExchange.IndexOfEmptySlot;
  begin
    GrandExchange.Slots[i].Buy();
    Sleep(5000,7000);
    GrandExchangeoffer.CreateBuyOffer(self.TargetGHerb,self.Restock.BuyPrice,self.Restock.BuyHerbQuant);
    Sleep(5000,6000);
    self.Collect;
    Bank.Open;
    self.BankCount;
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
  Bank.Open;
  Sleepuntil ((bank.IsOpen),50,8000);
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
      GrandExchange.Close(False);
      Bank.Open;
      self.BankCount;
    end;
  end;
end;

procedure THerb.CacheCount;
var
h:TRSBankItem;
amount: Integer;
begin
  amount:=1;
  h:= new TRSBankItem(self.TargetGHerb,Amount);
  Bank.Open(True);
  Bank.Withdraw (h,True,True,True);
  self.BankCount;
  Bank.Close(False);
  Writeln self.BankCountCache[0];
end;

////////////////////////////////ASSIGN STATES SECTION///////////////////////////////////////////////
function THerb.AssignRestockStates:ERestockStates;
begin
  if self.BankCountCache[1]>500 then exit(ERestockStates.SELL_POTIONS);
    if self.BankCountCache[0]<500 then exit(ERestockStates.BUY_HERBS);
      if self.BankCountCache[2]<500 then exit (ERestockStates.BUY_VIALS);
        if not Map.Walker.InRange(self.GEPoint,30) then exit(ERestockStates.WALK_TO_GE);
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
    end;
    Antiban.DoAntiban;
  end;
end;

function THerb.AssignPotionStates:EPotionStates; //Assigns Enums For THerb.MainRun
begin
  if Inventory.Items.Contains ('Vial of water') and Inventory.Items.Contains (self.TargetGHerb) then
  exit(EPotionStates.CLEAN_COMBINE);
      if Bank.IsOpen then
      exit (EPotionStates.WITHDRAW_ITEMS_CLOSE_BANK);
        if Inventory.Items.Count (self.Unf)=14 then
        exit (EPotionStates.OPEN_BANK_AND_DEPOSIT);
          if (self.BankCountCache[0]<500) then
          exit(EPotionStates.RESTOCK);
end;


procedure THerb.MainRun; //Uses previous function to link states to 1 to 1 actions.
  var
  action: EPotionStates;

begin
  while GetTimeRunning < (MAX_RUNTIME_MINUTES * ONE_MINUTE) do

  begin
    action := Self.AssignPotionStates;
    WriteLn(action);
      case action of
        EPotionStates.CLEAN_COMBINE:self.CleanandCombine;
        EPotionStates.OPEN_BANK_AND_DEPOSIT:self.OpenBank;
        EPotionStates.WITHDRAW_ITEMS_CLOSE_BANK:self.BankTransaction;
        EPotionStates.RESTOCK: self.RestockRun;
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
  run.CacheCount;
  run.MainRun;
end.

                                                       
