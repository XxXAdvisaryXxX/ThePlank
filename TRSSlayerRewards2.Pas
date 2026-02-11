{$INCLUDE_ONCE Wasplib/osrs.simba}
type
  ERSSlayerRewardsButtons  = enum(UNLOCK, EXTEND, BUY, TASKS, COSMETICS);
  ERSTaskButtons           = enum(CANCEL, BLOCK , VIEW_LIST, CONFIRMATION);
  ERSInterfaces            = enum(MAIN);

  TRSSlayerRewards = record
    Buttons         : Array [ERSSlayerRewardsButtons] of TRSButton;
    TaskButtons     : Array [ERSTaskButtons] of TRSButton;
    InterfaceSetup  : Array [ERSInterfaces] of TRSInterface;
    Scroll          : TRSScrollBar;
    Title           : TRSInterfaceTitle;
  end;

procedure TRSSlayerRewards.SetupInterface();
var
  interfaceBox : TBox;
  buttonBox    : TBox;
  btnColors    : TRSButtonEnabledColorArray;
  taskColors   : TRSButtonEnabledColorArray;
  exitBox      : TBox;
begin
  case RSClient.Mode of
    ERSMode.FIXED: interfaceBox := MSInterface.CreateBounds([0, 2, 0, -1], 484, 304);
    ERSMode.RESIZABLE, ERSMode.MODERN_COMPACT, ERSMode.MODERN_WIDE:
    interfaceBox := MSInterface.CreateBounds([0, 1, 0, -2], 484, 304);
  end;

  //Sets up our interface TBoxes
  interfaceBox.X1 := interfaceBox.X1 - 3;
  interfaceBox.X2 := interfaceBox.X2 + 3;
  interfaceBox.Y1 := interfaceBox.Y1 - 12;
  interfaceBox.Y2 := interfaceBox.Y2 + 12;
  self.InterfaceSetup[ERSInterfaces.MAIN].Bounds := interfaceBox;
  //Sets up scroll area's and bounds
  self.Scroll.Area.X1 := self.InterfaceSetup[ERSInterfaces.MAIN].Bounds.X1 + 5;
  self.Scroll.Area.Y1 := self.InterfaceSetup[ERSInterfaces.MAIN].Bounds.Y1 + 55;
  self.Scroll.Area.X2 := self.InterfaceSetup[ERSInterfaces.MAIN].Bounds.X2 - 30;
  self.Scroll.Area.Y2 := self.InterfaceSetup[ERSInterfaces.MAIN].Bounds.Y2 - 25;
  self.Scroll.Setup(True);

  self.Scroll.Bounds.X1 := self.InterfaceSetup[ERSInterfaces.MAIN].Bounds.X1 + 458;
  self.Scroll.Bounds.Y1 := self.InterfaceSetup[ERSInterfaces.MAIN].Bounds.Y1 + 75;
  self.Scroll.Bounds.X2 := self.InterfaceSetup[ERSInterfaces.MAIN].Bounds.X2 - 9;
  self.Scroll.Bounds.Y2 := self.InterfaceSetup[ERSInterfaces.MAIN].Bounds.Y2 - 30;

  self.Scroll.Up := self.Scroll.Up.Offset([3 , 6]);
  self.Scroll.Down := self.Scroll.Down.Offset([2 , 15]);
  //Buttons and title bounds setting
  self.Title.Setup(interfaceBox);

  exitBox.X1 := interfaceBox.X1 + 460;
  exitBox.Y1 := interfaceBox.Y1 + 5;
  exitBox.X2 := interfaceBox.X2 - 5;
  exitBox.Y2 := interfaceBox.Y2 - 295;
  self.Title.CloseButton := exitBox;

  buttonBox.X1 := interfaceBox.X1 +280;
  buttonBox.X2 := interfaceBox.X2 -150;
  buttonBox.Y1 := interfaceBox.Y1 +35;
  buttonBox.Y2 := interfaceBox.Y2 -265;
  //Creates new button objects
  btnColors := [[$0F1043, 0], [$23269F, 0.227]];
  self.Buttons[ERSSlayerRewardsButtons.COSMETICS] := new TRSButton(buttonBox,btnColors);
  self.Buttons[ERSSlayerRewardsButtons.BUY] := new TRSButton(buttonBox.Offset([-131 , 0]),btnColors);
  self.Buttons[ERSSlayerRewardsButtons.TASKS] := new TRSButton(buttonBox.Offset([-66 , 0]),btnColors);
  self.Buttons[ERSSlayerRewardsButtons.EXTEND] := new TRSButton(buttonBox.Offset([-198 , 0]),btnColors);
  self.Buttons[ERSSlayerRewardsButtons.UNLOCK] := new TRSButton(buttonBox.Offset([-265 , 0]),btnColors);

  self.TaskButtons[ERSTaskButtons.CANCEL] := new TRSButton(buttonBox.Offset([-50 , +70]),btnColors);
  self.TaskButtons[ERSTaskButtons.BLOCK] := new TRSButton(buttonBox.Offset([+10 , +70]),btnColors);
  self.TaskButtons[ERSTaskButtons.CONFIRMATION] := new TRSButton(buttonBox.Offset([-5 , +205]),btnColors);
end;

function TRSSlayerRewards.IsScreenOpen() : Boolean;
begin
  Result := self.Title.IsOpen();
end;

function TRSSlayerRewards.CloseScreen() : Boolean;
begin
  Result := self.Title.Close(False);
end;

function TRSSlayerRewards.OpenTab(tab : ERSSlayerRewardsButtons): Boolean;
begin
   if self.Buttons[tab].Enabled then
   Exit(True);

   self.Buttons[tab].Click(EMouseButton.LEFT);
   self.Buttons[tab].WaitEnabled(200,1400);

   if self.Buttons[tab].Enabled then
   Result := True;
end;

function TRSSlayerRewards._ConfirmationHandler() : Boolean;
begin
  self.TaskButtons[ERSTaskButtons.CONFIRMATION].Click(EMouseButton.LEFT);
  Result := self.Buttons[ERSSlayerRewardsButtons.TASKS].WaitEnabled(200 , 3000);
end;

function TRSSlayerRewards._ModifyTask(modifier : ERSTaskButtons) : Boolean;
begin
  if not self.IsScreenOpen() then
  begin
   WriteLn GetDebugLn('SlayerRewards Screen Not Open');
   Exit();
  end;

  if not self.Buttons[ERSSlayerRewardsButtons.TASKS].Enabled then
  self.OpenTab(ERSSlayerRewardsButtons.TASKS);

  if self.Buttons[ERSSlayerRewardsButtons.TASKS].Enabled then
  begin
    self.TaskButtons[modifier].Click(EMouseButton.LEFT);
    not self.Buttons[ERSSlayerRewardsButtons.TASKS].WaitEnabled(200 , 3000);
    Result := self._ConfirmationHandler();
  end;
end;

function TRSSlayerRewards.BlockTask() : Boolean;
begin
  Result := self._ModifyTask(ERSTaskButtons.BLOCK);
end;

function TRSSlayerRewards.CancelTask() : Boolean;
begin
  Result := self._ModifyTask(ERSTaskButtons.CANCEL);
end;

var
  SlayerRewards : TRSSlayerRewards;
begin
  SlayerRewards.SetupInterface();
end;



