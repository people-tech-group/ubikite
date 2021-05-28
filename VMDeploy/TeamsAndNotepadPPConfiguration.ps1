<#
.SYNOPSIS
This script install Microsoft teamsapp
.DESCRIPTION
This script is used configure the TeamsApp setup configuration.
#>
param(	
	[Parameter(mandatory = $false)]
    [string]$IsTeamsAppandNotepadPPSetup
)
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
	# If install teamsapp
	if ($IsTeamsAppandNotepadPPSetup -eq "true") {
	# Add registery of microsoft teams inside sessionhost
    REG add "HKLM\SOFTWARE\Microsoft\Teams" /v IsWVDEnvironment /t REG_DWORD /d 1 /f
    $TeamsInstaller = "https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.4461/Teams_windows_x64.msi"
    $WebRTC = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4vkL6"
    $MicrosoftViualCpp = "https://aka.ms/vs/16/release/vc_redist.x64.exe"
    $DestinationPath = "C:\TeamsInstallers"
    New-Item -Path $DestinationPath -ItemType "directory"
    Invoke-WebRequest -Uri $TeamsInstaller -OutFile $DestinationPath\Teams_windows_x64-01.msi
    $TeamAppInstallerPath = Get-ChildItem -LiteralPath $DestinationPath | Where-Object {$_.Name -match "Teams_windows*"} | select FullName
    msiexec /i $TeamAppInstallerPath.FullName /l*v c:\TeamsInstallers\Teams.log ALLUSER=1 ALLUSERS=1
    Invoke-WebRequest -Uri $MicrosoftViualCpp -OutFile $DestinationPath\vc_redist.x64.exe
    Invoke-WebRequest -Uri $WebRTC -OutFile $DestinationPath\MsRdcWebRTCSvc_HostSetup_0.11.0_x64.msi
    Invoke-Expression -Command "cmd.exe /c 'c:\TeamsInstallers\vc_redist.x64.exe' /quiet /norestart"
    Invoke-Expression -Command "cmd.exe /c 'c:\TeamsInstallers\MsRdcWebRTCSvc_HostSetup_0.11.0_x64.msi' /quiet /norestart"
	

Start-Sleep -Seconds 10

#Install Notepad++
Invoke-WebRequest -Uri 'https://notepad-plus-plus.org/repository/7.x/7.7.1/npp.7.7.1.Installer.x64.exe' -OutFile 'c:\temp\notepadplusplus.exe'
Invoke-Expression -Command 'c:\temp\notepadplusplus.exe /S'

}