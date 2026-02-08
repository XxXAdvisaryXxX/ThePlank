{$INCLUDE_ONCE Wasplib/osrs.simba}
const
  MASTER                : TStringArray =['Nieve'];
  SLAYER_WORN_EQUIPMENT : TStringArray = ['Slayer helmet (i)' , 'Slayer helmet'];
  SLAYER_EQUIPMENT      : TStringArray = ['Enchanted gem'];

type
  TTaskInfo = record
    AmountLeft    : Int64;
    Monster       : String;
    TaskInARow    : Int64;
    CurrentPoints : Int64;
  end;

  TTaskRecipe = record
    Monster         : TRSEntity;
    SlayerEquipment : TRSItemArray;
    KillShot        : Boolean;
    Cannon          : Boolean;
    Guthans         : Boolean;
    Map             : TRSMapChunkArray;
    ItemTeleports   : TRSItemArray;
    MagicTeleport   : ERSSpell;
    Potions         : Boolean;
    FairyRing       : Boolean;
  end;

  ERSSlayerButtons = enum(UNLOCK, EXTEND, BUY, TASKS, COSMETICS , CLOSE);
  ERSSlayerTaskButtons = enum(CANCEL, BLOCK , VIEW_LIST);

  TSlayerRewards = record
    Buttons         : Array [ERSSlayerButtons] of TRSButton;
    TaskButtons     : Array [ERSSlayerTaskButtons] of TRSButton;
    InterfaceSetup  : TRSInterface;
    SlotSetup       : TRSSlotInterface;
    IconDTM         : Array of TDTM;
    Scroll          : TRSScrollBar;
  end;

  TRSSlayer = record
   Task             : TTaskInfo;
   RewardsInterface : TSlayerRewards;
   MonsterRecipes   : Array of TTaskRecipe;
  end;

procedure TRSSlayer.SetupInterfaces();
var
  interfaceBox : TBox;
  buttonBox    : TBox;
  btnColors    : TRSButtonEnabledColorArray;
begin
  interfaceBox.X1 := GrandExchange.Bounds.X1;
  interfaceBox.X2 := GrandExchange.Bounds.X2 + 4;
  interfaceBox.Y1 := GrandExchange.Bounds.Y1 - 10;
  interfaceBox.Y2 := GrandExchange.Bounds.Y2 + 10;

  self.RewardsInterface.InterfaceSetup.Bounds := interfaceBox;

  buttonBox.X1 := GrandExchange.Bounds.X1 +272;
  buttonBox.X2 := GrandExchange.Bounds.X2 -145;
  buttonBox.Y1 := GrandExchange.Bounds.Y1 +25;
  buttonBox.Y2 := GrandExchange.Bounds.Y2 -255;

  btnColors := [[$0F1043, 0], [$23269F, 0.227]];
  self.RewardsInterface.Buttons[ERSSlayerButtons.COSMETICS] := new TRSButton(buttonBox,btnColors);
  self.RewardsInterface.Buttons[ERSSlayerButtons.BUY] := new TRSButton(buttonBox.Offset([-131 , 0]),btnColors);
  self.RewardsInterface.Buttons[ERSSlayerButtons.TASKS] := new TRSButton(buttonBox.Offset([-66 , 0]),btnColors);
  self.RewardsInterface.Buttons[ERSSlayerButtons.EXTEND] := new TRSButton(buttonBox.Offset([-198 , 0]),btnColors);
  self.RewardsInterface.Buttons[ERSSlayerButtons.UNLOCK] := new TRSButton(buttonBox.Offset([-265 , 0]),btnColors);

  //ShowOnTarget(self.RewardsInterface.Buttons[ERSSlayerButtons.UNLOCK].Bounds);
end;

(*
TRSSlayer.OpenTab
-----------------
```
function TRSSlayer.OpenTab(tab : ERSSlayerButtons): Boolean
```
Responsible for interacting with Slayer Reweards Interface. Use ERSSlayerButton to open the correct tab.

Example
```Pascal
Slayer.SetupInterfaces();
Slayer.OpenTab(ERSSlayerButtons.BUY);```
*)
function TRSSlayer.OpenTab(tab : ERSSlayerButtons): Boolean;
begin
   self.RewardsInterface.Buttons[tab].Click(EMouseButton.LEFT);
   self.RewardsInterface.Buttons[tab].WaitEnabled(200,1400);
   if self.RewardsInterface.Buttons[tab].Enabled then
   Result := True;
end;

(*
TRSSlayer._SetupChatTabs
------------------------
```
procedure TRSSlayer._SetupChatTabs()
```
Procedure responsible for Making sure chatbox is setup properly to read chat prompts. Automatically gets called with TRSSlayer.GetTaskInformation();
*)
procedure TRSSlayer._SetupChatTabs();
var
  chatTabs : TRSChatTabs;
begin
  chatTabs.SetupInterface();
  chatTabs.Open(ERSChatTab.ALL);
  chatTabs.ChangeState(ERSChatTab.GAME , ERSChatTabState.FILTERED);
  chatTabs.ChangeState(ERSChatTab.PUB , ERSChatTabState.HIDE);
  chatTabs.ChangeState(ERSChatTab.PRIV , ERSChatTabState.DISABLED);
  chatTabs.ChangeState(ERSChatTab.CHANNEL , ERSChatTabState.DISABLED);
  chatTabs.ChangeState(ERSChatTab.CLAN , ERSChatTabState.DISABLED);
  chatTabs.ChangeState(ERSChatTab.TRADE , ERSChatTabState.DISABLED);
end;

(*
TRSSlayer._PromptChat
---------------------
```
function TRSSlayer._PromptChat(): Boolean
```
Helper function to get Slayer information into the chatbox to read and process. Gets called automatically by TRSSlayer.GetTaskInformation
*)
function TRSSlayer._PromptChat() : Boolean;
begin
  self._SetupChatTabs();
  if not Inventory.Items.Contains('Enchanted gem') then
  begin
    GameTabs.Open(ERSGameTab.EQUIPMENT,);
    GameTabs.WaitOpen(ERSGameTab.EQUIPMENT,200,2000);
    Result := Equipment.Items.Interact('Slayer helmet (i)' , 'Check');
    Sleep(600);
    Exit;
  end;
  Inventory.Items.Interact('Enchanted gem' , 'Check');
  Sleep(600);
end;

(*
TRSSlayer.GetTaskInformation
----------------------------
```
function TRSSlayer.GetTaskInformation(): TTaskInfo
```
This function is responsible for getting task information. Checks gem or slayer helmet. Stores Data to TRSSlayer.Task.
Example:

```Pascal
{$I Wasplib/osrs.simba}

begin
  Slayer.GetTaskInformation();
  WriteLn Slayer.Task.Monster;
end;
*)
function TRSSlayer.GetTaskInformation(): TTaskInfo;
var
  tmpString : String;
begin
  self._PromptChat();

  tmpString := Chat.GetMessage(6).Between('only ',' more');

  if (tmpString = '') then  // Check to make sure our OCR actual has string before trying to convert to integer(causes out of range errors)
  begin
    WriteLn GetDebugLn('Nothing to read - Retrying',False);
    Exit;
  end;
  Result.AmountLeft :=  tmpString.ToInt();

  tmpString := Chat.GetMessage(7).Between('completed ',' tasks');
  Result.TaskInARow :=  tmpString.ToInt();

  tmpString := Chat.GetMessage(7).Between('of ',' points');
  Result.CurrentPoints :=  tmpString.ToInt();

  Result.Monster := Chat.GetMessage(6).Between('kill ',';').Capitalize();
  Self.Task.Monster := Result.Monster;
end;

var
  Slayer : TRSSlayer;
begin
  //Slayer.GetTaskInformation();
  //WriteLn Slayer.Task.Monster;
  Slayer.SetupInterfaces();
  Slayer.OpenTab(ERSSlayerButtons.BUY);
end;
