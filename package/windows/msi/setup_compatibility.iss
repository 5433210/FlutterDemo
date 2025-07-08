[Setup]
; Basic Information
AppId={{C82AF157-1234-5678-9ABC-DEF012345678}
AppName=CharAsGem
AppVersion=1.0.1
AppVerName=CharAsGem v1.0.1
AppPublisher=CharAsGem Team
AppPublisherURL=https://charasgem.com
AppSupportURL=https://charasgem.com/support
AppUpdatesURL=https://charasgem.com/updates
AppCopyright=Copyright (C) 2025 CharAsGem Team

; Default Installation Path
DefaultDirName={autopf}\CharAsGem
DefaultGroupName=CharAsGem
DisableProgramGroupPage=yes

; License and Information Pages
LicenseFile=license.txt
; InfoBeforeFile=readme.txt  ; Disabled - no info page before installation

; Output Settings
OutputDir=releases\\windows\\v1.0.1\\compatibility
OutputBaseFilename=CharAsGemInstaller_Legacy_v1.0.1
; SetupIconFile=assets\images\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; Permissions and Compatibility
PrivilegesRequired=admin
MinVersion=6.1.7600
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

; Uninstall Settings
UninstallDisplayIcon={app}\charasgem.exe
UninstallDisplayName=CharAsGem

; Certificate Signing (comment out to avoid errors if needed)
; SignTool=signtool
; SignedUninstaller=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1
Name: "associatefiles"; Description: "Associate .csg files"; GroupDescription: "File Associations"; Flags: unchecked

[Files]
; Main Application Files
Source: "..\..\..\build\windows\x64\runner\Release\charasgem.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; Font Files
Source: "..\..\..\assets\fonts\*"; DestDir: "{app}\assets\fonts"; Flags: ignoreversion recursesubdirs createallsubdirs

; Image Resources
Source: "..\..\..\assets\images\*"; DestDir: "{app}\assets\images"; Flags: ignoreversion recursesubdirs createallsubdirs

; Configuration File Templates (if exist)
; Source: "package\windows\msi\config\*"; DestDir: "{app}\config"; Flags: ignoreversion recursesubdirs createallsubdirs

; Documentation Files (if exist)
; Source: "package\windows\msi\docs\*"; DestDir: "{app}\docs"; Flags: ignoreversion recursesubdirs createallsubdirs

; Visual C++ Redistributable (if needed)
; Source: "redist\VC_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\CharAsGem"; Filename: "{app}\charasgem.exe"
Name: "{group}\{cm:UninstallProgram,CharAsGem}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\CharAsGem"; Filename: "{app}\charasgem.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\CharAsGem"; Filename: "{app}\charasgem.exe"; Tasks: quicklaunchicon

[Registry]
; File Associations
Root: HKCR; Subkey: ".csg"; ValueType: string; ValueName: ""; ValueData: "CharAsGemProject"; Flags: uninsdeletevalue; Tasks: associatefiles
Root: HKCR; Subkey: "CharAsGemProject"; ValueType: string; ValueName: ""; ValueData: "CharAsGem Project File"; Flags: uninsdeletekey; Tasks: associatefiles
Root: HKCR; Subkey: "CharAsGemProject\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\charasgem.exe,0"; Tasks: associatefiles
Root: HKCR; Subkey: "CharAsGemProject\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\charasgem.exe"" ""%1"""; Tasks: associatefiles

; Application Information
Root: HKLM; Subkey: "Software\CharAsGem"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\CharAsGem"; ValueType: string; ValueName: "Version"; ValueData: "1.0.1"; Flags: uninsdeletekey

[Run]
; Run after installation
Filename: "{app}\charasgem.exe"; Description: "{cm:LaunchProgram,CharAsGem}"; Flags: nowait postinstall skipifsilent

; Install Visual C++ Redistributable (if needed)
; Filename: "{tmp}\VC_redist.x64.exe"; Parameters: "/quiet"; StatusMsg: "Installing Visual C++ Redistributable..."; Check: NeedsVCRedist

[UninstallRun]
; Cleanup before uninstall
Filename: "{cmd}"; Parameters: "/c taskkill /f /im charasgem.exe"; Flags: runhidden; RunOnceId: "KillCharAsGem"

[Code]
// Check if Visual C++ Redistributable is needed
function NeedsVCRedist: Boolean;
begin
  Result := not RegKeyExists(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64');
end;

// Custom installation page and logic
function InitializeSetup(): Boolean;
begin
  Result := True;
  if not IsWin64 then
  begin
    MsgBox('This application requires 64-bit Windows operating system.', mbError, MB_OK);
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Custom post-installation actions
    // Example: Create initial configuration files
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    // Clean user data after uninstall (optional)
    if MsgBox('Delete user data and settings?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      DelTree(ExpandConstant('{userappdata}\CharAsGem'), True, True, True);
    end;
  end;
end;

