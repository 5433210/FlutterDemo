[Setup]
; Specifies basic installer properties
AppName=字字珠玑
AppVersion=1.0.0
DefaultDirName={pf}\CharasGem
DefaultGroupName=字字珠玑
UninstallDisplayIcon={app}\charasgem.exe
Compression=lzma2
SolidCompression=yes
OutputDir=.\build\windows\installer
OutputBaseFilename=CharasGemInstaller
MinVersion=0,6.1
DisableDirPage=no
DisableProgramGroupPage=no
; Set the default language
LanguageDetectionMethod=locale

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
; Add Chinese (Simplified) language support
Name: "SimpChinese"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: ".\build\windows\x64\runner\Release\charasgem.exe"; DestDir: "{app}"; DestName: "charasgem.exe"; Flags: ignoreversion
Source: ".\build\windows\x64\runner\Release\data\*.*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: ".\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\字字珠玑"; Filename: "{app}\charasgem.exe"
Name: "{commondesktop}\字字珠玑"; Filename: "{app}\charasgem.exe"; Tasks: desktopicon

[Code]
var
  ErrorCode: Integer;

function NeedVCRedist(): Boolean;
begin
  // Check if the Visual C++ Redistributable is installed
  // You might need to adjust this based on the specific registry key
  Result := not RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssInstall) and NeedVCRedist then
  begin
    // Display the message box in Chinese if the selected language is Chinese
    if ActiveLanguage() = '$0804' then // $0804 is the LCID for Chinese (Simplified)
    begin
      if MsgBox('本程序需要 Visual C++ 运行库，是否现在下载？', mbConfirmation, MB_YESNO) = IDYES then
      begin
        // Open the download page in the user's browser
        ShellExec('open', 'https://aka.ms/vs/16/release/vc_redist.x64.exe', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
      end;
    end
    else
    begin
      if MsgBox('This application requires the Visual C++ Redistributable. Would you like to download it now?', mbConfirmation, MB_YESNO) = IDYES then
      begin
        // Open the download page in the user's browser
        ShellExec('open', 'https://aka.ms/vs/16/release/vc_redist.x64.exe', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
      end;
    end;
  end;
end;

[Run]
Filename: "{app}\charasgem.exe"; Description: "{cm:LaunchProgram,'charasgem.exe'}"; Flags: shellexec postinstall skipifdoesntexist

[UninstallDelete]
Type: files; Name: "{app}\*"
Type: dirifempty; Name: "{app}"
