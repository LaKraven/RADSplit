unit RADSplit.Components.Main;

interface

{$I ..\Common\RADSplit.inc}

uses
  Classes, ToolsAPI, DockForm, SysUtils,
  {$IFDEF DELPHIXE2}
    Vcl.Buttons, Vcl.Controls, Vcl.Forms;
  {$ELSE}
    Buttons, Controls, Forms;
  {$ENDIF}

type
  TRADSplitButton = class(TSpeedButton)
  private
    FDockKilling: Boolean;
    FEditorKilling: Boolean;
    FForm: TDockableForm;
    FWindow: INTAEditWindow;
    procedure ButtonClick(Sender: TObject);
    procedure DockFormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
  published
    property DockForm: TDockableForm read FForm write FForm;
    property EditWindow: INTAEditWindow read FWindow write FWindow;
  end;

implementation

{ TRADSplitButton }

procedure TRADSplitButton.ButtonClick(Sender: TObject);
begin
  Hide;
  FForm := TDockableForm.Create(Application);
  FForm.Caption := 'RADSplit Dockable Editor Window';
  FForm.Width := FWindow.Form.Width;
  FForm.Height := FWindow.Form.Height;
  FForm.Top := FWindow.Form.Top;
  FForm.Left := FWindow.Form.Left;
  FForm.OnClose := DockFormClose;
  FForm.Show;
  {$IFDEF DELPHI2009}
    FWindow.Form.SetParentComponent(FForm);
  {$ELSE}
    FWindow.Form.Parent := FForm;
  {$ENDIF}
  FWindow.Form.BorderStyle := bsNone;
  FWindow.Form.Align := alClient;

  TForm(FWindow.Form).OnClose := FormClose;
//  TForm(FWindow.Form).OnCloseQuery := FormCloseQuery;
end;

constructor TRADSplitButton.Create(Owner: TComponent);
begin
  inherited;
  FWindow := nil;
  FForm := nil;
  OnClick := ButtonClick;

  FDockKilling := False;
  FEditorKilling := False;
end;

destructor TRADSplitButton.Destroy;
begin
  inherited;
end;

procedure TRADSplitButton.DockFormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FEditorKilling then
    Exit;

  if FWindow <> nil then
    if FWindow.Form <> nil then
    begin
//      FWindow.Form.SetParentComponent(Application);
      FWindow.Form.Close;
    end;
  FWindow := nil;
end;

procedure TRADSplitButton.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FDockKilling then
    Exit;
  if FForm <> nil then
    FForm.Free;

  FWindow := nil;
end;

procedure TRADSplitButton.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FWindow <> nil then
    if FWindow.Form <> nil then
      {$IFDEF DELPHI2009}
        FWindow.Form.SetParentComponent(Application);
      {$ELSE}
        FWindow.Form.Parent := TWinControl(Application);
      {$ENDIF}

  CanClose := True;
end;

end.
