unit ADB4Delphi.Register;

interface

uses
  ToolsAPI,
  DeskUtil,
  DockToolForm,
  System.SysUtils,
  System.Types,
  ADB4Delphi.Wizard,
  ADB4Delphi.Form;

procedure Register;
procedure DockFormRegisterADB4Delphi;
procedure DockFormUnregisterADB4Delphi;

implementation

procedure Register;
begin
  RegisterPackageWizard(TSOADB4DelphiWizard.Create);
  DockFormRegisterADB4Delphi;
end;

procedure DockFormRegisterADB4Delphi;
var
  IDETheme: IOTAIDEThemingServices250;
begin
  IDETheme := (BorlandIDEServices as IOTAIDEThemingServices250);
  IDETheme.RegisterFormClass(TADB4DelphiForm);
  if not Assigned(ADB4DelphiForm) then
    ADB4DelphiForm := TADB4DelphiForm.Create(nil);
  if @RegisterFieldAddress <> nil then
    RegisterFieldAddress(ADB4DelphiForm.Name, @ADB4DelphiForm);
end;

procedure DockFormUnregisterADB4Delphi;
begin
  if Assigned(ADB4DelphiForm) then begin
    if @UnregisterFieldAddress <> nil then
      UnregisterFieldAddress(@ADB4DelphiForm);
    FreeAndNil(ADB4DelphiForm);
  end;
end;

initialization

finalization
  DockFormUnregisterADB4Delphi;

end.
