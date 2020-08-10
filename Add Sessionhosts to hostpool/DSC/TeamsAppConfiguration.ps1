<#
.SYNOPSIS
Microsoft Teams Application setup
.DESCRIPTION
This script is used to setup Microsoft teams app in VDI environment.
#>

param(
[Parameter(mandatory = $True)]
[bool]$IsTeamsAppSetup
)

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
if($IsTeamsAppSetup){
# Add registery of microsoft teams inside sessionhost
REG add "HKLM\SOFTWARE\Microsoft\Teams" /v IsWVDEnvironment /t REG_DWORD /d 1 /f
$TeamsInstaller = "https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.4461/Teams_windows_x64.msi"
$WebRTC = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4vkL6"
$MicrosoftViualCpp = "https://aka.ms/vs/16/release/vc_redist.x64.exe"
$DestinationPath="C:\TeamsInstallers"
New-Item -Path $DestinationPath -ItemType "directory"
Invoke-WebRequest -Uri $TeamsInstaller -OutFile $DestinationPath\Teams_windows_x64-01.msi
msiexec /i c:\TeamsInstallers\Teams_windows_x64.msi /l*v c:\TeamsInstallers\Teams.log ALLUSER=1 ALLUSERS=1
Invoke-WebRequest -Uri $MicrosoftViualCpp -OutFile $DestinationPath\vc_redist.x64.exe
Invoke-WebRequest -Uri $WebRTC -OutFile $DestinationPath\MsRdcWebRTCSvc_HostSetup_0.11.0_x64.msi
Invoke-Expression -Command "cmd.exe /c 'c:\TeamsInstallers\vc_redist.x64.exe' /quiet"
Invoke-Expression -Command "cmd.exe /c 'c:\TeamsInstallers\MsRdcWebRTCSvc_HostSetup_0.11.0_x64.msi' /quiet"
}