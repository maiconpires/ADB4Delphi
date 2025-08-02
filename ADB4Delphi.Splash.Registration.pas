unit ADB4Delphi.Splash.Registration;

interface

uses Winapi.Windows;

var
  bmSplashScreen: HBITMAP;

implementation

uses ToolsAPI, System.SysUtils, Vcl.Dialogs;

resourcestring
  resPackageName = 'Android Debug Bridge for Delphi';
  resLicense = 'MIT License';

initialization
  bmSplashScreen := LoadBitmap(HInstance, 'SOiSISPlash');
  (SplashScreenServices as IOTASplashScreenServices).AddPluginBitmap(resPackageName, bmSplashScreen);

end.
