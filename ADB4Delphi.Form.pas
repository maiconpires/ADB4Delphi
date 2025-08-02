unit ADB4Delphi.Form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DockForm; // TDockableForm

type
  TADB4DelphiForm = class(TDockableForm)
    cmbDispositivos: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    btnConectar: TButton;
    btnRefresh: TButton;
    procedure btnConectarClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure RefreshDevices;
  end;

var
  ADB4DelphiForm: TADB4DelphiForm;
  ADB: String;
  ListDevices, ListModels, ListBrands, ListIPs: TStringList;


implementation

{$R *.dfm}

uses System.IOUtils, Xml.XMLDoc, Xml.XMLIntf, System.Generics.Collections, System.RegularExpressions;

function ExecutarComandoESaida(const Comando: string): string;
var
  SecurityAttr: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Buffer: array[0..255] of AnsiChar;
  BytesRead: DWORD;
  Saida: TStringStream;
begin
  Result := '';
  Saida := TStringStream.Create('', TEncoding.ANSI);
  try
    ZeroMemory(@SecurityAttr, SizeOf(SecurityAttr));
    SecurityAttr.nLength := SizeOf(SecurityAttr);
    SecurityAttr.bInheritHandle := True;
    SecurityAttr.lpSecurityDescriptor := nil;

    if not CreatePipe(ReadPipe, WritePipe, @SecurityAttr, 0) then
      RaiseLastOSError;

    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartupInfo.hStdOutput := WritePipe;
    StartupInfo.hStdError := WritePipe;
    StartupInfo.wShowWindow := SW_HIDE;

    if not CreateProcess(nil, PChar(Comando), nil, nil, True, 0, nil, nil, StartupInfo, ProcessInfo) then
    begin
      CloseHandle(ReadPipe);
      CloseHandle(WritePipe);
      RaiseLastOSError;
    end;

    CloseHandle(WritePipe);

    repeat
      FillChar(Buffer, SizeOf(Buffer), 0);
      ReadFile(ReadPipe, Buffer, SizeOf(Buffer) - 1, BytesRead, nil);
      if BytesRead > 0 then
        Saida.Write(Buffer, BytesRead);
    until BytesRead = 0;

    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);

    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
    CloseHandle(ReadPipe);

    Result := Saida.DataString;
  finally
    Saida.Free;
  end;
end;

function GetLatestSDKProperties: TDictionary<string, string>;
var
  BaseDir, VersionDir: string;
  SubDirs: TArray<string>;
  MaxVersion: Double;
  MaxVersionStr: string;
  DirName: string;
  SDKFiles: TArray<string>;
  FileName, NameOnly: string;
  XMLDoc: IXMLDocument;
  ProjectNode, PropertyGroupNode, ChildNode: IXMLNode;
  i, j: Integer;
  Ve: Double;

  function MatchesPattern(const FileName, Suffix: string): Boolean;
  begin
    Result := FileName.StartsWith('AndroidSDK', True) and
              FileName.EndsWith(Suffix, True);
  end;

  function TryFindSDKFile(const Folder, Suffix: string; out SDKFile: string): Boolean;
  var
    AllFiles: TArray<string>;
    F: string;
  begin
    Result := False;
    SDKFile := '';
    AllFiles := TDirectory.GetFiles(Folder, '*.sdk', TSearchOption.soTopDirectoryOnly);
    for F in AllFiles do
    begin
      if MatchesPattern(ExtractFileName(F), Suffix) then
      begin
        SDKFile := F;
        Exit(True);
      end;
    end;
  end;

begin
  Result := TDictionary<string, string>.Create;

  BaseDir := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) + 'Embarcadero\BDS\';

  if not TDirectory.Exists(BaseDir) then
    Exit;

  MaxVersion := -1;
  MaxVersionStr := '';
  SubDirs := TDirectory.GetDirectories(BaseDir);
  for DirName in SubDirs do
  begin
    VersionDir := ExtractFileName(DirName);
    VersionDir := VersionDir.Replace('.',',');
    if TryStrToFloat(VersionDir, Ve) then begin
      if Ve>MaxVersion then begin
        MaxVersion := Ve;
        MaxVersionStr := VersionDir.Replace(',','.');
      end;
    end;
  end;

  if MaxVersionStr = '' then
    raise Exception.Create('NOT FOUND: '+IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) + 'Embarcadero\BDS\[VERSION]');

  VersionDir := IncludeTrailingPathDelimiter(BaseDir + MaxVersionStr);

  if not TryFindSDKFile(VersionDir, '_64bit.sdk', FileName) then
    if not TryFindSDKFile(VersionDir, '_32bit.sdk', FileName) then
      raise Exception.Create('Android SDK not found!');

  XMLDoc := TXMLDocument.Create(nil);
  try
    XMLDoc.LoadFromFile(FileName);
    XMLDoc.Active := True;

    ProjectNode := XMLDoc.DocumentElement;
    if Assigned(ProjectNode) and SameText(ProjectNode.NodeName, 'Project') then
    begin
      for i := 0 to ProjectNode.ChildNodes.Count - 1 do
      begin
        PropertyGroupNode := ProjectNode.ChildNodes[i];
        if SameText(PropertyGroupNode.NodeName, 'PropertyGroup') then
        begin
          for j := 0 to PropertyGroupNode.ChildNodes.Count - 1 do
          begin
            ChildNode := PropertyGroupNode.ChildNodes[j];
            Result.AddOrSetValue(ChildNode.NodeName, Trim(ChildNode.Text));
          end;
          Exit; // lê apenas o primeiro <PropertyGroup>
        end;
      end;
    end;
  except
    Result.Clear;
  end;
end;

function ExtrairIPs(const Texto: string): TStringList;
var
  Match: TMatch;
  Regex: TRegEx;
begin
  Result := TStringList.Create;
  Result.Sorted := False;
  Result.Duplicates := dupIgnore;

  // Expressão para capturar apenas os IPs do tipo: inet x.x.x.x/yy
  Regex := TRegEx.Create('inet\s+(\d{1,3}(?:\.\d{1,3}){3})/\d+');

  Match := Regex.Match(Texto);
  while Match.Success do
  begin
    Result.Add(Match.Groups[1].Value); // Apenas o IP, sem a máscara
    Match := Match.NextMatch;
  end;
end;

procedure TADB4DelphiForm.btnConectarClick(Sender: TObject);
var
  Output: string;
  IP: String;
begin
  if LowerCase(TButton(Sender).Caption) = 'connect' then begin
    TButton(Sender).Caption := 'Disconnect';

    IP := Copy(cmbDispositivos.Text, 0,Pos('@',cmbDispositivos.Text)-1);
    Output := ExecutarComandoESaida(Format('cmd /C %s %s %d',[ADB, 'tcpip', 5555]));
    Output := ExecutarComandoESaida(Format('cmd /C %s %s %s:%d',[ADB, 'connect', ip, 5555]));

  end
  else begin
    TButton(Sender).Caption := 'Connect';

    IP := Copy(cmbDispositivos.Text, 0,Pos('@',cmbDispositivos.Text)-1);
    Output := ExecutarComandoESaida(Format('cmd /C %s %s %s:%d',[ADB, 'disconnect', ip, 5555]));
    Output := ExecutarComandoESaida(Format('cmd /C %s %s',[ADB, 'usb']));
  end;
  ShowMessage(Output);
end;

procedure TADB4DelphiForm.btnRefreshClick(Sender: TObject);
begin
  RefreshDevices;
end;

procedure TADB4DelphiForm.RefreshDevices;
var
 Props: TDictionary<string, string>;
 Pair: TPair<string, string>;
 Output: String;
 I: Integer;
begin
  Props := GetLatestSDKProperties;
  ListDevices := TStringList.Create;
  ListModels := TStringList.Create;
  ListBrands := TStringList.Create;
  ListIPs := TStringList.Create;
  try
    try
      if Props.TryGetValue('SDKAdbPath', ADB) then

      ListDevices.Text := ExecutarComandoESaida(Format('cmd /C %s %s',[ADB, 'devices']));
      ListDevices.Delete(0);
      for I := ListDevices.Count-1 downto 0 do begin
        ListDevices[I] := ListDevices[I].Replace('device','');
        if ListDevices[I].IsEmpty then
          ListDevices.Delete(I)
      end;

      ListModels.Text := ExecutarComandoESaida(Format('cmd /C %s %s %s %s',[ADB, 'shell', 'getprop', 'ro.product.model']));
      ListBrands.Text := ExecutarComandoESaida(Format('cmd /C %s %s %s %s',[ADB, 'shell', 'getprop', 'ro.product.brand']));

      Output := ExecutarComandoESaida(Format('cmd /C %s %s %s %s %s %s %s %s',[ADB, 'shell', 'ip', '-f', 'inet', 'addr', 'show', 'wlan0']));
      ListIPs := ExtrairIPs(Output);

      cmbDispositivos.Clear;
      for I := 0 to ListDevices.Count-1 do begin
        cmbDispositivos.Items.Add(Format('%s@%s [%s] (%s)',[ListIPs[I], ListModels[I], ListBrands[I], ListDevices[I].Trim()]));
      end;

      cmbDispositivos.ItemIndex := 0;
    except
      On E:Exception do begin
        Showmessage(E.Message);
      end;
    end;

  finally
    Props.Free;
    ListDevices.Free;
    ListModels.Free;
    ListBrands.Free;
    ListIPs.Free;
  end;
end;

end.
