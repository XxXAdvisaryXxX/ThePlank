{$INCLUDE_ONCE Wasplib/osrs.simba}
type
  ERSSlayerRewardsButtons  = enum(UNLOCK, EXTEND, BUY, TASKS, COSMETICS);
  ERSTaskButtons           = enum(CANCEL, BLOCK , VIEW_LIST);
  ERSInterfaces            = enum(MAIN, LEFT , RIGHT);

  TSlayerRewardsInterface = record
    Buttons         : Array [ERSSlayerRewardsButtons] of TRSButton;
    TaskButtons     : Array [ERSTaskButtons] of TRSButton;
    InterfaceSetup  : Array [ERSInterfaces] of TRSInterface;
    SlotSetup       : TRSSlotInterface;
    IconDTM         : Array of TDTM;
    Scroll          : TRSScrollBar;
    Title           : TRSInterfaceTitle;
  end;

  TRSSlayerRewards = record
   SlayerInterface : TSlayerRewardsInterface;
  end;

procedure TRSSlayerRewards._SetupStaticInterfaces();
var
  interfaceBox : TBox;
  buttonBox    : TBox;
  btnColors    : TRSButtonEnabledColorArray;
  taskColors   : TRSButtonEnabledColorArray;
  titleBox     : TBox := GrandExchange.Title.Bounds;
  exitBox      : TBox := Bank.Title.CloseButton;
begin
  interfaceBox.X1 := GrandExchange.Bounds.X1;
  interfaceBox.X2 := GrandExchange.Bounds.X2 + 4;
  interfaceBox.Y1 := GrandExchange.Bounds.Y1 - 10;
  interfaceBox.Y2 := GrandExchange.Bounds.Y2 + 10;
  self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds := interfaceBox;

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

  btnColors := [[$0F1043, 0], [$23269F, 0.227]];
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.COSMETICS] := new TRSButton(buttonBox,btnColors);
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.BUY] := new TRSButton(buttonBox.Offset([-131 , 0]),btnColors);
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.TASKS] := new TRSButton(buttonBox.Offset([-66 , 0]),btnColors);
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.EXTEND] := new TRSButton(buttonBox.Offset([-198 , 0]),btnColors);
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.UNLOCK] := new TRSButton(buttonBox.Offset([-265 , 0]),btnColors);

  self.SlayerInterface.TaskButtons[ERSTaskButtons.CANCEL] := new TRSButton(buttonBox.Offset([-50 , +70]),btnColors);
  self.SlayerInterface.TaskButtons[ERSTaskButtons.BLOCK] := new TRSButton(buttonBox.Offset([+10 , +70]),btnColors);
end;

procedure TRSSlayerRewards.SetupDynamicInterfaces();
var
  leftBox  : TBox;
  rightBox : TBox;
begin
  leftBox.X1 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.X1;
  leftBox.X2 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.X2 - 400;
  leftBox.Y1 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.Y1;
  leftBox.Y2 := self.SlayerInterface.InterfaceSetup[ERSInterfaces.MAIN].Bounds.Y2;

  rightBox := leftBox.Offset([225 , 0]);

  self.SlayerInterface.InterfaceSetup[ERSInterfaces.LEFT].Bounds := leftBox;
  self.SlayerInterface.InterfaceSetup[ERSInterfaces.RIGHT].Bounds := rightBox;

  ShowOnTarget(rightBox);
end;

function TRSSlayerRewards.IsSlayerRewardsScreenOpen() : Boolean;
begin
  Result := self.SlayerInterface.Title.IsOpen();
end;

function TRSSlayerRewards.CloseSlayerRewardsScreen() : Boolean;
begin
  Result := self.SlayerInterface.Title.Close(False);
end;

function TRSSlayerRewards.OpenTab(tab : ERSSlayerRewardsButtons): Boolean;
begin
   if self.SlayerInterface.Buttons[tab].Enabled then
   Exit(True);

   self.SlayerInterface.Buttons[tab].Click(EMouseButton.LEFT);
   self.SlayerInterface.Buttons[tab].WaitEnabled(200,1400);

   if self.SlayerInterface.Buttons[tab].Enabled then
   Result := True;
end;

function TRSSlayerRewards.CancelTask() : Boolean;
begin
  if not self.IsSlayerRewardsScreenOpen() then
  begin
   WriteLn('SlayerRewards Screen Not Open');
   Exit();
  end;

  if not self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.TASKS].Enabled then
  self.OpenTab(ERSSlayerRewardsButtons.TASKS);

  if not self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.TASKS].Enabled then
  self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.TASKS].Click(EMouseButton.LEFT);

  if self.SlayerInterface.Buttons[ERSSlayerRewardsButtons.TASKS].Enabled then
  begin
    self.SlayerInterface.TaskButtons[ERSTaskButtons.CANCEL].Click(EMouseButton.LEFT);
    Result := True;
  end;
end;

var
  SlayerRewards : TRSSlayerRewards;
begin
  SlayerRewards._SetupStaticInterfaces();
  SlayerRewards.SetupDynamicInterfaces();
 // WriteLn SlayerRewards.IsSlayerRewardsScreenOpen();
 // WriteLn SlayerRewards.CancelTask();
  //WriteLn SlayerRewards.CloseSlayerRewardsScreen();
  //WriteLn SlayerRewards.SlayerInterface.Title.GetTitle();
  //WriteLn SlayerRewards.OpenTab(ERSSlayerRewardsButtons.TASKS);
end;    
