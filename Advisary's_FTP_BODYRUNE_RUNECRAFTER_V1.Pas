{$I Wasplib/osrs.simba}

{
    ADVISARY'S FTP BODY RUNECRAFTER
********INSTRUCTIONS***********
#1- Equip Body Tiara, Withdraw 1 energy pot, And Fill Inventory With Pure Ess
#2- Start anywhere near Edgeville Bank.
#3 - Putting Pure Essence and Energy Potions (4) in top left slots of bank greatly improves effeciency.

************TIPS****************
Setting Up Antiban: Sometimes antiban will glitch the bot. I suggest only 1 or 2 tasks set to 3% varaince.

SETTINGS: Make sure to auto-toggle run between 5-15 energy. To do this: goto settings in RS. Click all settings.
            use the settings search and search for 'ENERGY'.. Click the enable button and set to 5-15. 

sleeps and breaks can be seasoned to taste.
}
const
  MAX_RUNTIME_MINUTES = 360;
Type
  EBodyStates=enum(
    BANKING_TRANSACTION,
    WALK_TO_AND_ENTER_RUINS,
    CRAFT_RUNES,
    EXIT_ALTER,
    WALK_TO_BANK,
    OPEN_BANK
  );
  EEnergyPotionStates=enum(
    CONSUMABLE,
    EMPTY
    );

  TBody=Record
    PEssence,REssence,Rune,Potion,Vial:TRSBankItem;
    BodyRune,PureEssence,EnergyPotion1,EnergyPotion2,EnergyPotion3,EnergyPotion4:TRSItem;
    BankBoothObj,RuinsObj,AlterObj,ExitObj:TRSObject;
    BankBoothPoint,RuinsPoint,AlterExit:TPoint;
    PotionArray,ExitArray:TRSItemArray;
    Form: TScriptForm;
    Tab: TLazTabSheet;
  end;

procedure TBody.MapInit;//inits map and tpoints
begin
  Map.Setup([Chunk(Box(46,55,50,52), 0)]);//Loads mainland map
  Map.Add([Chunk(Box(39,75,39,75), 0)]); //Loads Alter Area

  self.RuinsPoint:=[8124,36658];
  self.BankBoothPoint:=[8268,36466];
  self.AlterExit :=[5996,31066];
end;

procedure TBody.ObjectInit; //inits object information
begin
self.RuinsObj:= TRSObject.Create(@map.walker,[2,2,4],[[8116,36650]],['Enter Mysterious ruins']);
self.RuinsObj.Finder.Colors +=[$535D51, 1, EColorSpace.RGB, [1.000, 1.000, 1.000]];

self.AlterObj:= TRSObject.Create(@map.walker,[2,2,4],[[5996,31066]],['Craft-rune Alter']);
self.AlterObj.Finder.Colors +=[$41464A, 1, EColorSpace.RGB, [1.000, 1.000, 1.000]];

self.ExitObj:= TRSObject.Create(@map.walker,[1,1,3],[[5988,31098]],['Use Portal']);
self.ExitObj.Finder.Colors +=[$9F9DDB, 5, EColorSpace.RGB, [1.000, 1.000, 1.000]];

self.BankBoothObj:= TRSObject.Create(@map.walker,[1,1,4],[[8296,36458]],['Bank Bank booth']);
self.BankBoothObj.Track:= True;
self.BankBoothObj.Finder.Colors += [$5F6264, 0.000, EColorSpace.RGB, [1.000, 1.000, 1.000]];

//showontarget(self.ExitObj);
end;

procedure TBody.ItemsInit;  //Inits all the different items.
begin
 self.PEssence := new TRSBankItem('Pure essence', -1);
 self.REssence := new TRSBankItem('Rune essence', -1);
 self.Potion:= new TRSBankItem('Energy potion(4)', 1);
 self.Rune:= new TRSBankItem('Body rune', -1);
 self.Vial:= new TRSBankItem('Vial', 1);

 self.EnergyPotion1:= 'Energy potion(1)';
 self.EnergyPotion2:= 'Energy potion(2)';
 self.EnergyPotion3:= 'Energy potion(3)';
 self.EnergyPotion4:= 'Energy potion(4)';

 self.PotionArray:=[self.EnergyPotion1,self.EnergyPotion2,self.EnergyPotion3,self.EnergyPotion4];

 self.PureEssence:='Pure essence';

 self.ExitArray:=['Pure essence','Body rune'];
end;
procedure TBody.SetupAntiBan;  //sets up antiban form
begin
  self.Form.Setup();
  self.form.CreateAntibanTab();
  self.form.Run();
end;
procedure TBody.MainInit;  //main init file
begin
  self.MapInit;
  self.ObjectInit;
  self.ItemsInit;
end;
function TBody.ShouldDrinkEnergy:Boolean; //Helper function. Changing the number higher will consume more energy pots per trip
begin
  If minimap.GetLevel(ERSMinimapOrb.ENERGY) <75 then
  Result:=True;
end;

function TBody.GetEnergyPotionStates():EEnergyPotionStates;
begin
  If inventory.items.containsany(self.potionarray) then
  exit(EEnergyPotionStates.CONSUMABLE) else
  exit(EEnergyPotionStates.EMPTY);
end;

procedure TBody.DrinkPotion; //procedure that drinks the different energy pot.
begin
 If Inventory.Items.ContainsAny(self.potionarray) and self.ShouldDrinkEnergy=True then
  Inventory.Items.Click(self.EnergyPotion1) or
  Inventory.Items.Click(self.EnergyPotion2) or
  Inventory.Items.Click(self.EnergyPotion3) or
  Inventory.Items.Click(self.EnergyPotion4) else
  Exit;
 end;

procedure TBody.WalkToRuins; //Helper Procedure To Walk TO Ruins
begin
  Writeln 'Walking To Ruins';
  self.DrinkPotion;
  Map.Walker.Webwalk(self.RuinsPoint,4,0.90,false);
  Sleepuntil((Minimap.IsPlayerMoving=False),150,2000);
  Writeln 'Exiting WalkToRuins';
end;

procedure TBody.EnterRuins;//Enters The Ruins
begin
  self.DrinkPotion;
  Writeln 'Attempting To Enter Ruins';
  self.RuinsObj.Click(True,10);
  Sleepuntil ((Map.Walker.Inrange(self.AlterExit,150)),150,6000);
  writeln 'Exiting EnterRuins';
end;

procedure TBody.ExitAlter; //Exits The Body Alter
begin
  self.ExitObj.Click(True,10);
  Sleepuntil ((Map.Walker.Inrange(self.RuinsPoint,150)),150,6000);
end;

procedure TBody.CraftRunes;  //Crafts runes after entering mysterious ruins.
begin
  writeln 'Walking TO alter, Then Crafting';
  self.AlterObj.Click(True,10);
  Sleepuntil((Minimap.IsPlayerMoving=False),2000,10000);
end;

procedure TBody.WalkBackToBank;//walks back to the bank
begin
  SleepUntil((Map.Walker.Inrange(self.RuinsPoint,250)),1000,5000);
  self.DrinkPotion;
  Map.Walker.Webwalk(self.BankBoothPoint,4,0.90,False);
  SleepUntil((Minimap.IsPlayerMoving=False),250,10000);
  self.DrinkPotion;
  AntiBan.DoAntiban;
end;

procedure TBody.OpenBank;//opens bank after getting close to bank.
begin
Bank.Open(self.BankBoothObj,true);
sleepuntil((Bank.IsOpen=True),500,10000);
end;

procedure TBody.FindRuins; //walks from bank to ruins; then enters ruins. Combines two procedures from earlier
begin
 self.WalkToRuins;
 self.EnterRuins;
end;

procedure TBody.BankTransaction; //Navigates bank transactions.. Doesn't open bank, only closes
begin
  if Inventory.Items.Contains ('Vial') then
  Bank.Deposit(self.Vial,True);

  if not Inventory.Items.ContainsAny(Self.PotionArray) then
  Bank.Withdraw(self.Potion,True,True,True);

  Bank.Deposit(self.Rune,True);
  Bank.Withdraw(self.PEssence,True,True,True);
  Bank.Close(False);
  self.DrinkPotion;
end;

function TBody.AssignStates: EBodyStates; //Assigns criteria to determine states
begin
  If Inventory.Items.Contains('Pure essence') and map.walker.inrange(self.AlterExit,120) then
  exit(EBodyStates.CRAFT_RUNES);
    If Inventory.Items.Contains('Body rune') and map.walker.inrange(self.AlterExit,120) then
    exit(EBodyStates.EXIT_ALTER);
      If Bank.IsOpen and Inventory.Items.Contains ('Body rune') and map.walker.inrange(self.BankBoothPoint,4) then
      exit(EBodyStates.BANKING_TRANSACTION);
        If not Bank.IsOpen and Inventory.Items.Contains ('Pure essence') and not map.walker.inrange(self.AlterExit,120) then
        exit(EBodyStates.WALK_TO_AND_ENTER_RUINS);
          If not map.walker.inrange(self.BankBoothPoint,20) and Inventory.Items.Contains ('Body rune') and not Bank.IsOpen and not map.walker.inrange(self.AlterExit,120) then
          exit(EBodyStates.WALK_TO_BANK);
             If map.walker.inrange(self.BankBoothPoint,19) and Inventory.Items.Contains ('Body rune') and not Bank.IsOpen and not map.walker.inrange(self.AlterExit,120) then
             exit(EBodyStates.OPEN_BANK);
end;

procedure TBody.MainRun; //Uses previous function to link states to 1 to 1 actions.
  var
  action: EBodyStates;
begin
 while GetTimeRunning < (MAX_RUNTIME_MINUTES * ONE_MINUTE) do

  begin
    action := Self.AssignStates;
    WriteLn(action);
    case action of
      EBodyStates.WALK_TO_AND_ENTER_RUINS: self.FindRuins;
      EBodyStates.CRAFT_RUNES: self.CraftRunes;
      EBodyStates.EXIT_ALTER: self.ExitAlter;
      EBodyStates.WALK_TO_BANK:self.WalkBackToBank;
      EBodyStates.BANKING_TRANSACTION:self.BankTransaction;
      EBodyStates.OPEN_BANK:self.OpenBank;
    end;
  end;
end;


var
Run:TBody;
begin
  Run.SetupAntiBan;
  Run.MainInit;
  Run.MainRun;
end;  
