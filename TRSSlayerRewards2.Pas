{$INCLUDE_ONCE Wasplib/osrs.simba}
type
  ERSSlayerRewardsButtons  = enum(UNLOCK, EXTEND, BUY, TASKS, COSMETICS);
  ERSTaskButtons           = enum(CANCEL, BLOCK , VIEW_LIST, CONFIRMATION);
  ERSInterfaces            = enum(MAIN);

  TSlayerRewardsInterface = record
    Buttons         : Array [ERSSlayerRewardsButtons] of TRSButton;
    TaskButtons     : Array [ERSTaskButtons] of TRSButton;
    InterfaceSetup  : Array [ERSInterfaces] of TRSInterface;
    Scroll          : TRSScrollBar;
    Title           : TRSInterfaceTitle;
  end;

  TRSSlayerRewards = record
   SlayerInterface : TSlayerRewardsInterface;
  end;

(*
TRSSlayerRewards._SetupStaticInterfaces
---------------------------------------
```
procedure TRSSlayerRewards._SetupStaticInterfaces()
```
This sets the bounds and colors for interface and buttons.
*)
procedure TRSSlayerRewards._SetupStaticInterfaces();
var
  interfaceBox : TBox;
  buttonBox    : TBox;
  btnColors    : TRSButtonEnabledColorArray;
  taskColors   : TRSButtonEnabledColorArray;
  titleBox     : TBox := GrandExchange.Title.Bounds;
  exitBox      : TBox := Bank.Title.CloseButton;
  isVisible    : Boolean;
begin
  //Sets up our interface TBoxes
  interfaceBox.X1 := GrandExchange.Bounds.X1;
  interfaceBox.X2 := GrandExchange.Bounds.X2 + 4;
  interfaceBox.Y1 := GrandExchange.Bounds.Y1 - 10;
  interfaceBox.Y2 := GrandExchange.Bounds.Y2 + 10;
  self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds := interfaceBox;
  //Sets up scroll area's and bounds
  self.SlayerInterface.Scroll.Area.X1 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.X1 + 5;
  self.SlayerInterface.Scroll.Area.Y1 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.Y1 + 55;
  self.SlayerInterface.Scroll.Area.X2 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.X2 - 30;
  self.SlayerInterface.Scroll.Area.Y2 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.Y2 - 25;
  self.SlayerInterface.Scroll.Setup(True);

  self.SlayerInterface.Scroll.Bounds.X1 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.X1 + 458;
  self.SlayerInterface.Scroll.Bounds.Y1 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.Y1 + 75;
  self.SlayerInterface.Scroll.Bounds.X2 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.X2 - 9;
  self.SlayerInterface.Scroll.Bounds.Y2 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.Y2 - 30;

  self.SlayerInterface.Scroll.Up := self.SlayerInterface.Scroll.Up.Offset([2 , 4]);
  self.SlayerInterface.Scroll.Down := self.SlayerInterface.Scroll.Down.Offset([2 , 15]);
  //Buttons and title bounds setting
  titleBox.Y1 := titleBox.Y1 - 23;
  titleBox.Y2 := titleBox.Y2 + 15;
  self.SlayerInterface.Title.Setup(titleBox);

  exitBox.X2 := exitBox.X2 + 3;
  exitBox.Y2 := exitBox.Y2 + 3;
  self.SlayerInterface.Title.CloseButton := exitBox;

  buttonBox.X1 := GrandExchange.Bounds.X1 +272;
  buttonBox.X2 := GrandExchange.Bounds.X2 -145;
  buttonBox.Y1 := GrandExchange.Bounds.Y1 +25;
  buttonBox.Y2 := GrandExchange.Bounds.Y2 -255;
  //Creates new button objects
  btnColors := [[$0F1043, 0], [$23269F, 0.227]];
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.COSMETICS] := new TRSButton(buttonBox,btnColors);
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.BUY] := new TRSButton(buttonBox.Offset([-131 , 0]),btnColors);
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.TASKS] := new TRSButton(buttonBox.Offset([-66 , 0]),btnColors);
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.EXTEND] := new TRSButton(buttonBox.Offset([-198 , 0]),btnColors);
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.UNLOCK] := new TRSButton(buttonBox.Offset([-265 , 0]),btnColors);

  self.SlayerInterface.TaskButtons[ERSTaskButtons.CANCEL] := new TRSButton(buttonBox.Offset([-50 , +70]),btnColors);
  self.SlayerInterface.TaskButtons[ERSTaskButtons.BLOCK] := new TRSButton(buttonBox.Offset([+10 , +70]),btnColors);
  self.SlayerInterface.TaskButtons[ERSTaskButtons.CONFIRMATION] := new TRSButton(buttonBox.Offset([-5 , +205]),btnColors);
end;

(*
TRSSlayerRewards.IsScreenOpen
-----------------------------
```
function TRSSlayerRewards.IsScreenOpen(): Boolean
```
Returns if slayer screen is open.
*)
function TRSSlayerRewards.IsScreenOpen() : Boolean;
begin
  Result := self.SlayerInterface.Title.IsOpen();
end;

(*
TRSSlayerRewards.CloseScreen
----------------------------
```
function TRSSlayerRewards.CloseScreen(): Boolean
```
Closes interface screen.
*)
function TRSSlayerRewards.CloseScreen() : Boolean;
begin
  Result := self.SlayerInterface.Title.Close(False);
end;

(*
TRSSlayerRewards.OpenTab
------------------------
```
function TRSSlayerRewards.OpenTab(tab : ERSSlayerRewardsButtons): Boolean
```
Example:
```Pascal
{$INCLUDE_ONCE Wasplib/osrs.simba}
begin
  SlayerRewards.OpenTab(ERSSlayerRewardsButtons.TASKS);
end;
*)
function TRSSlayerRewards.OpenTab(tab : ERSSlayerRewardsButtons): Boolean;
begin
   if self.SlayerInterface.Buttons[tab].Enabled then
   Exit(True);

   self.SlayerInterface.Buttons[tab].Click(EMouseButton.LEFT);
   self.SlayerInterface.Buttons[tab].WaitEnabled(200,1400);

   if self.SlayerInterface.Buttons[tab].Enabled then
   Result := True;
end;

(*
TRSSlayerRewards._ConfirmationHandler
-------------------------------------
```
function TRSSlayerRewards._ConfirmationHandler(): Boolean
```
Handles the confirmation screen when blocking or cancelling a task.
*)
function TRSSlayerRewards._ConfirmationHandler() : Boolean;
begin
  self.SlayerInterface.TaskButtons[ERSTaskButtons.CONFIRMATION].Click(EMouseButton.LEFT);
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.TASKS].WaitEnabled(200 , 3000);
  Result := True;
end;

(*
TRSSlayerRewards.AlterTask
--------------------------
```
function TRSSlayerRewards.AlterTask(modifier : ERSTaskButtons): Boolean
```
This handles blocking or cancelling a task. Use ERSTaskButton.CANCEL or ERSTaskButton.BLOCK.

Example
```Pascal
{$INCLUDE_ONCE Wasplib/osrs.simba}
begin
  SlayerRewards._SetupStaticInterfaces();
  SlayerRewards.AlterTask(ERSTaskButtons.CANCEL);
end;```
*)
function TRSSlayerRewards.AlterTask(modifier : ERSTaskButtons) : Boolean;
begin
  if not self.IsScreenOpen() then
  begin
   WriteLn GetDebugLn('SlayerRewards Screen Not Open');
   Exit();
  end;

  if not self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.TASKS].Enabled then
  self.OpenTab(ERSSlayerRewardsButtons.TASKS);

  if self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.TASKS].Enabled then
  begin
    self.SlayerInterface.TaskButtons[modifier].Click(EMouseButton.LEFT);
    not self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.TASKS].WaitEnabled(200 , 3000);
    self._ConfirmationHandler();
    Result := True;
  end;
end;

var
  SlayerRewards : TRSSlayerRewards;
begin
  SlayerRewards._SetupStaticInterfaces();
end;

//List of common degub functions and procedures;
  //SlayerRewards.SlayerInterface.Scroll.Scroll(4 ,True);
  //SlayerRewards.SetupDynamicInterfaces();
  //WriteLn SlayerRewards.IsSlayerRewardsScreenOpen();
  //WriteLn SlayerRewards.CloseSlayerRewardsScreen();
  //WriteLn SlayerRewards.SlayerInterface.Title.GetTitle();
  //WriteLn SlayerRewards.OpenTab(ERSSlayerRewardsButtons.TASKS);
  //WriteLn SlayerRewards.SlayerInterface.Scroll.IsVisible();
  //WriteLn SlayerRewards.AlterTask(ERSTaskButtons.CANCEL);      
