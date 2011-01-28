; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{65409F25-DA03-453F-8713-7E4BA9BD253F}
AppName=DiaporamaCenter
AppVersion=1.0.1
;AppVerName=DiaporamaCenter 1.0.1
AppPublisher=Matheric Tomson (matheric.tomson@gmail.com)
AppPublisherURL=http://code.google.com/p/diaporamacenter/
AppSupportURL=http://code.google.com/p/diaporamacenter/
AppUpdatesURL=http://code.google.com/p/diaporamacenter/
DefaultDirName={pf}\DiaporamaCenter
DefaultGroupName=DiaporamaCenter
OutputDir=E:\Dev\Sources\Diaporama\DiaporamaCenter\trunk\bin\setup
OutputBaseFilename=DiaporamaCenter_1.0.1_Setup
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Types]
Name: "full"; Description: "Binaries and samples"
Name: "binaries"; Description: "Binaries only"

[Components]
Name: "program"; Description: "Program Files"; Types: full binaries; Flags: fixed
Name: "samples"; Description: "Sample files"; Types: full;

[Files]
; program
Source: "E:\Dev\Sources\Diaporama\DiaporamaCenter\trunk\bin\release\DiaporamaCenter.exe"; DestDir: "{app}"; Components: program; Flags: ignoreversion
Source: "E:\Dev\Sources\Diaporama\DiaporamaCenter\trunk\setup\rtl120.bpl"; DestDir: "{app}"; Components: program; Flags: ignoreversion
Source: "E:\Dev\Sources\Diaporama\DiaporamaCenter\trunk\setup\vcl120.bpl"; DestDir: "{app}"; Components: program; Flags: ignoreversion
Source: "E:\Dev\Sources\Diaporama\DiaporamaCenter\trunk\3rd\msxml.msi"; DestDir: "{tmp}"; Components: program; Flags: ignoreversion
Source: "E:\Dev\Sources\Diaporama\DiaporamaCenter\trunk\lib\release\CPortLib12.bpl"; DestDir: "{app}"; Components: program; Flags: ignoreversion
Source: "E:\Dev\Sources\Diaporama\DiaporamaCenter\trunk\data\DiaporamaCenter.xml"; Components: program; DestDir: "{app}"; Flags: ignoreversion

;samples
Source: "E:\Dev\Sources\Diaporama\DiaporamaCenter\trunk\data\FantasticEstateAgency\*"; Components: samples; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\DiaporamaCenter"; Filename: "{app}\DiaporamaCenter.exe"
Name: "{group}\{cm:UninstallProgram,DiaporamaCenter}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\DiaporamaCenter"; Filename: "{app}\DiaporamaCenter.exe"; Tasks: desktopicon

[Run]
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\msxml.msi"""
Filename: "{app}\DiaporamaCenter.exe"; Description: "{cm:LaunchProgram,DiaporamaCenter}"; Flags: nowait postinstall skipifsilent

