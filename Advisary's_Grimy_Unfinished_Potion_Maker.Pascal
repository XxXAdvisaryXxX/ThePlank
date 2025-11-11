{
-------------Makes Unfinished Potions With Grimy Herbs----------
Items Needed: Grimy Herbs, Vials of Water

Instructions for changing herb type.. Scroll down to the green /////// box in THerb.Init.
  -Read the instructions there. It's simple as changing two words.

*Works at GE (Crowded GE's can cause glitches not recommended)
*Varrok west bank. (Sometimes if you in stalls next to doors, it wants to open the door)
*Varrok East Bank (Best Place to run in my opinion)
 }
{$I Wasplib/osrs.simba}
//{$I TRSHerblore.simba}
const
  MAX_RUNTIME_MINUTES = 360;
type
//Enum used in assign states function. Youll never need to change these.
 EKwuarmStates= enum(
 OPEN_BANK_AND_DEPOSIT,
 WITHDRAW_ITEMS_CLOSE_BANK,
 CLEAN_COMBINE
 );
 THerb = record
    Actions, MaxTime, MaxActions, MaxLevel: UInt64; //Used for future forms.
    FormSetting: Boolean; //used for future forms
    TargetGHerb,TargetCHerb,Unf:TRSItem;//used for storing herb and potion TRSitem information below.
    TargetArray:TRSItemArray;  //Used for a specific function within TRSHerblore
  end;
{***********CHANGE HERBS BELOW*************}
procedure THerb.Init;
begin
 Map.Setup([ERSChunk.VARROCK]);
////////////// //////////////////////// Change The Names Here To desired herb
 self.TargetGHerb:='Grimy dwarf weed';// Make sure you follow the format with uppercase and lowercase.
 self.TargetCHerb:='Dwarf weed';      // The first letter of every herb will be upper or lower case. Pay close attention
///////////////////////////////////////
 self.TargetArray:= [self.TargetGHerb];
 self.Unf:= (self.TargetCHerb+'potion (unf)');
end;

function THerb.IsItemDepleted(Item:TRSItem):boolean;//Returns true if inventory item is depleted. Helper function
begin
  if Inventory.Items.Count(Item)<1 then
  result:=true;
    if result=false then
    writeln 'Item Count Is Still Above Zero';
end;

procedure THerb.CleanHerbs(Herb:TRSItemArray); //helper function that cleans herbs.
 var
  slot: Integer;
  slots: TIntegerArray;
begin
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
  sleepuntil((self.IsItemDepleted(Herb)=True),3000,10000);
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
      Bank.Withdraw (h,True,True,True);
      Bank.Withdraw (v,True,True,True);
      exit;
    end;
end;

procedure THerb.OpenBank;//opens bank and makes sure things are withdrawn properly.
begin
  Bank.open;
  Sleepuntil ((bank.IsOpen),50,2000);
  Bank.DepositInventory;
    If Inventory.Items.Contains(self.Unf) then
    Bank.DepositInventory;
end;

procedure THerb.BankTransaction; //Completes the banking transactions.
begin
  self.WithdrawForUnfinished(self.TargetGHerb,True);
  Bank.Close(False);
  Sleepuntil ((not Bank.Isopen),25,1500);
end;

procedure THerb.CleanandCombine; //Cleans and combines herbs ingame.
begin
  self.CleanHerbs(self.TargetArray);
  self.MakeUnfinished(self.TargetCHerb);
end;

function THerb.AssignStates:EKwuarmStates; //Assigns Enums For THerb.MainRun
begin
  if Inventory.Items.Contains ('Vial of water') and Inventory.Items.Contains (self.TargetGHerb) then
  exit(EKwuarmStates.CLEAN_COMBINE);
    if Inventory.Items.Count (self.Unf)=14 then
    exit (EKwuarmStates.OPEN_BANK_AND_DEPOSIT);
      If Bank.IsOpen then
      exit (EKwuarmStates.WITHDRAW_ITEMS_CLOSE_BANK);
end;


procedure THerb.MainRun; //Uses previous function to link states to 1 to 1 actions.
  var
  action: EKwuarmStates;

begin
 while GetTimeRunning < (MAX_RUNTIME_MINUTES * ONE_MINUTE) do

  begin
    action := Self.AssignStates;
    WriteLn(action);
    case action of
      EKwuarmStates.CLEAN_COMBINE:self.CleanandCombine;
      EKwuarmStates.OPEN_BANK_AND_DEPOSIT:self.OpenBank;
      EKwuarmStates.WITHDRAW_ITEMS_CLOSE_BANK:self.BankTransaction;
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
  run.init;
  run.MainRun;
end.
