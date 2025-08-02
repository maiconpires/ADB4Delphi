unit ADB4Delphi.Wizard;

interface

uses
  ToolsAPI,
  Vcl.Dialogs,
  Vcl.Menus,
  DeskUtil,
  System.Classes,
  ADB4Delphi.Form;

type
  TSOADB4DelphiWizard = class(TNotifierObject, IOTAWizard)
  protected
    procedure OnMenuClick(Sender: TObject);
    function GetIDString: String;
    function GetName: String;
    function GetState: TWizardState;

    {Launch the AddIn}
    procedure Execute;

  public
    constructor Create;
//    class function New: IOTAWizard;
    destructor Destroy; override;
  end;
implementation

{ TSOADB4DelphiWizard }

constructor TSOADB4DelphiWizard.Create;
var
  DelphiMenu: TMainMenu;
  itemMenu: TMenuItem;
//  itemExecute: TMenuItem;
begin
  // BorlandIDEService - instancia de toda IDE
  // INTAService da acesso a menu e toolbar
  DelphiMenu:=(BorlandIDEServices as INTAServices).MainMenu;
  itemMenu := DelphiMenu.Items.Find('Android ADB');

  if itemMenu = nil then begin
    itemMenu := TMenuItem.Create(Nil);
    itemMenu.Caption := 'Android ADB';
    itemMenu.OnClick := OnMenuClick;
    DelphiMenu.Items.Add(itemMenu);
  end;

//  ItemExecute := TMenuItem.Create(itemMenu);
//  ItemExecute.Caption := 'Android Debug Bridge';
//  itemExecute.ShortCut := scAlt + scShift + ord('A');
//  ItemExecute.OnClick := OnMenuClick;
//  itemMenu.Add(ItemExecute);
end;

destructor TSOADB4DelphiWizard.Destroy;
var
  DelphiMenu: TMainMenu;
  itemMenu: TMenuItem;
begin
  DelphiMenu:=(BorlandIDEServices as INTAServices).MainMenu;
  ItemMenu := DelphiMenu.Items.Find('Android ADB');
  if itemMenu <> nil then
    ItemMenu.Free;

  inherited;
end;

procedure TSOADB4DelphiWizard.Execute;
begin
  Showmessage('SOiS ADB4Delphi');
end;

function TSOADB4DelphiWizard.GetIDString: String;
begin
  Result := Self.ClassName;
end;

function TSOADB4DelphiWizard.GetName: String;
begin
  Result := Self.ClassName;
end;

function TSOADB4DelphiWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

//class function TSOADB4DelphiWizard.New: IOTAWizard;
//begin
//  Result := Self.Create;
//end;

procedure TSOADB4DelphiWizard.OnMenuClick(Sender: TObject);
begin
  if not Assigned(ADB4DelphiForm) then
    Exit;

  ShowDockableForm(ADB4DelphiForm);
  FocusWindow(ADB4DelphiForm);
end;

end.
