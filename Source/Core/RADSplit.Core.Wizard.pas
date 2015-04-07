unit RADSplit.Core.Wizard;

interface

{$I ..\Common\RADSplit.inc}

uses
  Classes, SysUtils, DockForm, DeskUtil, DeskForm,
  {$IFDEF DELPHIXE2}
    VCL.Controls, VCL.Forms, Vcl.ExtCtrls,
  {$ELSE}
    Controls, Forms, ExtCtrls,
  {$ENDIF}
  ToolsAPI;

function InitWizard(const AIDEServices: IBorlandIDEServices; ARegister: TWizardRegisterProc; var ATerminate: TWizardTerminateProc): Boolean; stdcall;
procedure UninitWizard;

exports
  InitWizard name WizardEntryPoint;

implementation

type
  TRADSplitForm = class(TDockableForm)
  private
    FEditWindow: INTAEditWindow;
    procedure DoDockDrop(Sender: TObject; Source: TDragDockObject; X, Y: Integer);
  public
    procedure RegisterDockable;
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent; AEditWindow: INTAEditWindow); reintroduce; overload;
    destructor Destroy; override;
  end;

  TRADSplitWindow = class(TPersistent)
  private
    FDockable: TRADSplitForm;
    FEditWindow: INTAEditWindow;
  public
    constructor Create(const AEditWindow: INTAEditWindow);
    destructor Destroy; override;

    procedure AfterConstruction; override;
  published
    property EditWindow: INTAEditWindow read FEditWindow write FEditWindow;
  end;
  TRADSplitWindowArray = Array of TRADSplitWindow;

  TRADSplitNotifier = class(TInterfacedObject, INTAEditServicesNotifier)
  private
    FRADSplitWindows: TRADSplitWindowArray;
    procedure MakeDockable(const EditWindow: INTAEditWindow);
    procedure RemoveDockable(const EditWindow: INTAEditWindow);
  protected
    {$REGION 'IOTANotifier'}
      procedure AfterSave;
      procedure BeforeSave;
      procedure Destroyed;
      procedure Modified;
    {$ENDREGION}
    {$REGION 'INTAEditServicesNotifier'}
      procedure WindowShow(const EditWindow: INTAEditWindow; Show, LoadedFromDesktop: Boolean);
      procedure WindowNotification(const EditWindow: INTAEditWindow; Operation: TOperation);
      procedure WindowActivated(const EditWindow: INTAEditWindow);
      procedure WindowCommand(const EditWindow: INTAEditWindow; Command, Param: Integer; var Handled: Boolean);
      procedure EditorViewActivated(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
      procedure EditorViewModified(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
      procedure DockFormVisibleChanged(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
      procedure DockFormUpdated(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
      procedure DockFormRefresh(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
    {$ENDREGION}
  public
    destructor Destroy; override;
  end;

var
  LNotifier: Integer = -1;

function InitWizard(const AIDEServices: IBorlandIDEServices; ARegister: TWizardRegisterProc; var ATerminate: TWizardTerminateProc): Boolean;
begin
  LNotifier := (AIDEServices as IOTAEditorServices).AddNotifier(TRADSplitNotifier.Create);
  ATerminate := UninitWizard;
  Result := LNotifier > -1;
end;

procedure UninitWizard;
begin
  if LNotifier > -1 then
  begin
    (BorlandIDEServices as IOTAEditorServices).RemoveNotifier(LNotifier);
    LNotifier := -1;
  end;
end;

{ TRADSplitForm }

constructor TRADSplitForm.Create(AOwner: TComponent);
begin
  inherited;
  DoubleBuffered := True;
  DeskSection := 'RADSplit';
  AutoSave := True;

  SaveStateNecessary := True;
end;

procedure TRADSplitForm.DoDockDrop(Sender: TObject; Source: TDragDockObject; X, Y: Integer);
begin
  FEditWindow.Form.Refresh;
  FEditWindow.Form.Repaint;
end;

constructor TRADSplitForm.Create(AOwner: TComponent; AEditWindow: INTAEditWindow);
begin
  inherited Create(AOwner);
//  SetParentComponent(AOwner);
  Name := AEditWindow.Form.Name + '_RADSplit';
  Caption := 'RADSplit Dockable Editor';
  AEditWindow.Form.DoubleBuffered := True;
  DoubleBuffered := True;
  OnDockDrop := DoDockDrop;

  Width := AEditWindow.Form.Width;
  Height := AEditWindow.Form.Height;
  Top := AEditWindow.Form.Top;
  Left := AEditWindow.Form.Left;
//  RegisterDockable;
  FEditWindow := AEditWindow;
  AEditWindow.Form.Dock(Self, Rect(0, 0, 20, 20));
  AEditWindow.Form.BorderStyle := bsNone;
  AEditWindow.Form.Align := alClient;
end;

destructor TRADSplitForm.Destroy;
begin
  FEditWindow.Form.Align := alNone;
  FEditWindow.Form.Free;
  SaveStateNecessary := True;
  inherited;
end;

procedure TRADSplitForm.RegisterDockable;
begin
  RegisterDesktopFormClass(TRADSplitForm, 'RADSplit', Name);
  if (@RegisterFieldAddress <> nil) then
    RegisterFieldAddress(Name, @Self);
end;

{ TRADSplitWindow }

procedure TRADSplitWindow.AfterConstruction;
begin
  inherited;
  FDockable := TRADSplitForm.Create(FEditWindow.Form.GetParentComponent, FEditWindow);
  FDockable.Show;
end;

constructor TRADSplitWindow.Create(const AEditWindow: INTAEditWindow);
begin
  inherited Create;
  FEditWindow := AEditWindow;
end;

destructor TRADSplitWindow.Destroy;
begin
  FEditWindow.Form.Dock(nil, Rect(0, 0, Screen.Width, Screen.Height));
  FDockable.Free;
  inherited;
end;

{ TEditorSplitter }

procedure TRADSplitNotifier.MakeDockable(const EditWindow: INTAEditWindow);
var
  LIndex: Integer;
begin
  if EditWindow.Form.Parent = nil then
  begin
    LIndex := Length(FRADSplitWindows);
    SetLength(FRADSplitWindows, LIndex + 1);
    FRADSplitWindows[LIndex] := TRADSplitWindow.Create(EditWindow);
  end;
end;

procedure TRADSplitNotifier.RemoveDockable(const EditWindow: INTAEditWindow);
var
 LCount, I, LIndex: Integer;
begin
  LIndex := -1;
  for I := Low(FRADSplitWindows) to High(FRADSplitWindows) do
    if FRADSplitWindows[I].FEditWindow.Form = EditWindow.Form then
    begin
      LIndex := I;
      Break;
    end;

  if LIndex = -1 then
    Exit;
  FRADSplitWindows[LIndex].Free;

  LCount := Length(FRADSplitWindows);
  if (LIndex < 0) or (LIndex > LCount - 1) then
    Exit;
  if (LIndex < (LCount - 1)) then
    for I := LIndex to LCount - 2 do
      FRADSplitWindows[I] := FRADSplitWindows[I + 1];
  SetLength(FRADSplitWindows, LCount - 1);
end;

procedure TRADSplitNotifier.AfterSave;
begin

end;

procedure TRADSplitNotifier.BeforeSave;
begin

end;

destructor TRADSplitNotifier.Destroy;
var
  I: Integer;
begin
  for I := Low(FRADSplitWindows) to High(FRADSplitWindows) do
    FRADSplitWindows[I].Free;
  inherited;
end;

procedure TRADSplitNotifier.Destroyed;
begin

end;

procedure TRADSplitNotifier.DockFormRefresh(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
begin

end;

procedure TRADSplitNotifier.DockFormUpdated(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
begin

end;

procedure TRADSplitNotifier.DockFormVisibleChanged(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
begin

end;

procedure TRADSplitNotifier.EditorViewActivated(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
begin

end;

procedure TRADSplitNotifier.EditorViewModified(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
begin

end;

procedure TRADSplitNotifier.Modified;
begin

end;

procedure TRADSplitNotifier.WindowActivated(const EditWindow: INTAEditWindow);
begin

end;

procedure TRADSplitNotifier.WindowCommand(const EditWindow: INTAEditWindow; Command, Param: Integer; var Handled: Boolean);
begin
  Handled := False;
end;

procedure TRADSplitNotifier.WindowNotification(const EditWindow: INTAEditWindow; Operation: TOperation);
begin
  if (EditWindow.Form.Parent <> nil) or (EditWindow.Form.Name = 'EditWindow_0') then
    Exit;

  case Operation of
    opInsert: MakeDockable(EditWindow);
    opRemove: RemoveDockable(EditWindow);
  end;
end;

procedure TRADSplitNotifier.WindowShow(const EditWindow: INTAEditWindow; Show, LoadedFromDesktop: Boolean);
begin

end;

initialization
  LNotifier := (BorlandIDEServices as IOTAEditorServices).AddNotifier(TRADSplitNotifier.Create);
finalization
  UninitWizard;

end.
