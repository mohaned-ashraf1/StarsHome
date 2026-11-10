; ============================================================
; STARS HOMES ERP — Windows Installer Script (Inno Setup)
; يقوم بتجميع مثبت الويندوز الاحترافي STARS_HOMES_ERP_Setup.exe
; ============================================================

#define MyAppName "STARS HOMES ERP"
#define MyAppVersion "1.0.13"
#define MyAppPublisher "STARS HOMES Factory"
#define MyAppURL "https://github.com/mohaned-ashraf1/StarsHome"
#define MyAppExeName "stars_home.exe"

[Setup]
AppId={{D37B4394-1D9A-4E38-95BA-9F0A209865B8}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=.
OutputBaseFilename=STARS_HOMES_ERP_Setup
SetupIconFile=..\frontend\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
DisableDirPage=no
DisableProgramGroupPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
; Source files built by `flutter build windows --release`
Source: "..\frontend\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\frontend\windows\runner\resources\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion
; NOTE: Do not use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\app_icon.ico"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\data"

