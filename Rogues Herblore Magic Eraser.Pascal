{$I SRL-T/osr.simba}
{$I WaspLib/osr.simba}
const
  GRIMY_HERB_NAMES: TStringArray = [
    'Grimy guam leaf',
    'Grimy marrentill',
    'Grimy tarromin',
    'Grimy harralander',
    'Grimy ranarr weed',
    'Grimy toadflax',
    'Grimy irit leaf',
    'Grimy avantoe',
    'Grimy kwuarm',
    'Grimy snapdragon',
    'Grimy cadantine',
    'Grimy lantadyme',
    'Grimy dwarf weed',
    'Grimy torstol'
  ];

  CLEAN_HERB_NAMES: TStringArray = [
    'Guam leaf',
    'Marrentill',
    'Tarromin',
    'Harralander',
    'Ranarr weed',
    'Toadflax',
    'Irit leaf',
    'Avantoe',
    'Kwuarm',
    'Snapdragon',
    'Cadantine',
    'Lantadyme',
    'Dwarf weed',
    'Torstol'
  ];

  UNF_POTION_NAMES: TStringArray = [
    'Guam potion (unf)',
    'Marrentill potion (unf)',
    'Tarromin potion (unf)',
    'Harralander potion (unf)',
    'Ranarr potion (unf)',
    'Toadflax potion (unf)',
    'Irit potion (unf)',
    'Avantoe potion (unf)',
    'Kwuarm potion (unf)',
    'Snapdragon potion (unf)',
    'Cadantine potion (unf)',
    'Lantadyme potion (unf)',
    'Dwarf weed potion (unf)',
    'Torstol potion (unf)'
  ];
type
  ELocation = (
    GRAND_EXCHANGE);

  EStates = (
    OPEN_BANK,
    CLEAN_HERBS,
    MAKE_POTION,
    WITHDRAW_ITEMS,
    CLOSE_BANK);

  TRSRecipe = record
   CleanItem     : TRSItem;
   VialItem      : TRSItem;
   GrimyItem     : TRSItem;
   UnfItem       : TRSItem;
   CleanBankItem : TRSBankItem;
   VialBankItem  : TRSBankItem;
   GrimyBankItem : TRSBankItem;
   UnfBankItem   : TRSBankItem;
  end;

  TRSClean = record
   StartingXP           : UInt64;
   ShouldMakeUnfinished : Boolean;
   Recipe               : TRSRecipe;
  end;
var
  Bot : TRSClean;
procedure TRSClean.SetupBankItems();
var
  amount : Integer;
begin
  amount := 28;

  if Bot.ShouldMakeUnfinished then
  amount := 14;
  Bank.CachedQuantity := amount;

  Bot.Recipe.VialItem := 'Vial of water';
  Bot.Recipe.VialBankItem := self.Recipe.VialBankItem.Setup('Vial of water' , amount , True);

  Bot.Recipe.CleanBankItem := self.Recipe.CleanBankItem.Setup(Bot.Recipe.CleanItem , amount , True);
  Bot.Recipe.GrimyBankItem := self.Recipe.GrimyBankItem.Setup(Bot.Recipe.GrimyItem , amount , True);
  Bot.Recipe.UnfBankItem := self.Recipe.UnfBankItem.Setup(Bot.Recipe.UnfItem , amount , True);
end;

procedure TRSClean.Init();
begin
  Bot.SetupBankItems();

  if not RSClient.IsLoggedIn() then
  Login.LoginPlayer();

  self.StartingXP := XPBar.Read();
  WriteLn ('Starting XP : ', self.StartingXP);

  Map.SetupChunk(Chunk([49,54,49,54], 0));
end;

function TRSClean.CleanHerbs : Boolean;
var
  slots : TIntegerArray;
  slot  : Integer;
begin
  Inventory.FindItem(Bot.Recipe.GrimyItem, slots);
  for slot in slots do
  begin
    Inventory.Items.InteractSlot(slot , 'Clean');
    XPBar.WaitXP();
  end;
end;

function TRSClean.MakePotions: Boolean;
var
  slot : Integer;
begin
  Bot.CleanHerbs();
  Inventory.FindItem('Vial of water' , slot);
  Inventory.ClickItem(Bot.Recipe.CleanItem , 'Use');
  Wait(600);
  Inventory.Items.InteractSlot(slot , ' -> Vial of water');
  WaitUntil(Make.IsOpen(), 200, 1200);
  KeyBoard.PressKey(KEYBOARD_NUMBERS[1]);
  WaitUntil((Inventory.Items.Count(Bot.Recipe.UnfItem) = 14), 200 , 10000);
end;

function TRSClean.Withdraw() : Boolean;
begin
  GrandExchange.OpenBank();
  WriteLn Bot.ShouldMakeUnfinished;
  WriteLn Bot.Recipe.GrimyBankItem;
  WriteLn Bank.CachedQuantity;
  if not Bot.ShouldMakeUnfinished then
  begin
   Bank.WithdrawItem(Bot.Recipe.GrimyBankItem , False);
  end;

  if Bot.ShouldMakeUnfinished then
  begin
    Bank.WithdrawItem(Bot.Recipe.GrimyItem , False);
    Bank.WithdrawItem('Vial of water' , False);
  end;
end;

type
  TMyScriptForm = record(TScriptForm)
    Box        : TLabeledCheckBox;
    GrimyCombo : TLabeledComboBox;
    CleanCombo : TLabeledComboBox;
    UnfCombo   : TLabeledComboBox;
    GrimyHerbs : UInt64;
    CleanHerbs : UInt64;
    UnfPots    : UInt64;
  end;
procedure TMyScriptForm.StartScript(sender: TObject); override;
begin
  inherited(); 
  If Box.IsChecked() then
  Bot.ShouldMakeUnfinished := True;

  Bot.Recipe.GrimyItem := GrimyCombo.getText();

  Bot.Recipe.CleanItem := CleanCombo.GetText();

  Bot.Recipe.UnfItem := UnfCombo.GetText();
end;

procedure TMyScriptForm.Run(); override;
var
  tab: TTabSheet;
  tmp : String;
begin
  Self.Setup('Rogues Herb Cleaning Magic Eraser');
  Self.Start.setOnClick(@Self.StartScript);

  Self.AddTab('Script Settings');
  tab := Self.Tabs[High(Self.Tabs)];

  Self.CreateAccountManager(tab);

  Box.Create(tab,'Make into Unfinished??','If checked, will clean and create Unfinsihed',[10,300],[1,1]);

  GrimyCombo.Create(tab,'Choose Grimy Herb ','Choose Your Grimy Herb' ,[10,175],[225,35], True);
  for GrimyHerbs := Low(GRIMY_HERB_NAMES) to High(GRIMY_HERB_NAMES) do
  begin
    GrimyCombo.AddItem(GRIMY_HERB_NAMES[GrimyHerbs]);
  end;

  CleanCombo.Create(tab,'Choose Clean Herb ','Choose Clean Herb' ,[10,225],[225,35], True);
  for CleanHerbs := Low(CLEAN_HERB_NAMES) to High(CLEAN_HERB_NAMES) do
  begin
    CleanCombo.AddItem(CLEAN_HERB_NAMES[CleanHerbs]);
  end;

  UnfCombo.Create(tab,'Choose Unfinished Potion ','Dont have to choose if not making UNF Pots' ,[10,325],[225,35], True);
  for UnfPots := Low(UNF_POTION_NAMES) to High(UNF_POTION_NAMES) do
  begin
    UnfCombo.AddItem(UNF_POTION_NAMES[UnfPots]);
  end;

  Self.CreateAntibanManager();
  Self.CreateWaspLibSettings();

  inherited();
end;
var
  MyScriptForm: TMyScriptForm;


begin
 MyScriptForm.Run();
 Bot.Init();
 Bot.Withdraw();
end;   
