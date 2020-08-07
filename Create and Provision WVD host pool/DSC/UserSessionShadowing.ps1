<#
.SYNOPSIS
User Session Shadowing setup
.DESCRIPTION
This script is used configure the User session shadow.
#>
param(
[Parameter(mandatory = $false)]
[bool]$IsUserSessionShadow,
[Parameter(mandatory = $false)]
[string]$ShadowSessionMSTSCOption,
[Parameter(mandatory = $false)]
[bool]$ShadowSessionMSRA,
[Parameter(mandatory = $false)]
[string]$ShadowSessionMSRAOption
)

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
# Check if user session shadow setup enable
if($IsUserSessionShadow){
$GpDownloadURI=""
$OutFile= "C:\GroupPolicies.zip"
$DestinationPath="C:\GroupPolicies"
New-Item -Path $DestinationPath -ItemType "directory"
Invoke-WebRequest -Uri $GpDownloadURI -OutFile $OutFile
Expand-Archive -Path $OutFile -DestinationPath $DestinationPath
If($ShadowSessionMSRA){
# Activate Remote Assistance (automated)
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 1 /f
# Configure firewall policies on your WVD
netsh firewall set service type = remotedesktop mode = enable
# Enable Group Policies for MSRA
if($ShadowSessionMSRAOption -eq "Allow helpers to remotely control the computer"){
    Copy-Item -Path "C:\GroupPolicies\MSRA\Allow helpers to remotely control the computer\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
    gpupdate /force
    secedit.exe /configure /db secedit.sdb /cfg C:\GroupPolicies\MSRA\secconfig.cfg /areas SECURITYPOLICY
}
if($ShadowSessionMSRAOption -eq "Allow helpers to only view the computer"){
    Copy-Item -Path "C:\GroupPolicies\MSRA\Allow helpers to only view the computer\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
    gpupdate /force
    secedit.exe /configure /db secedit.sdb /cfg C:\GroupPolicies\MSRA\secconfig.cfg /areas SECURITYPOLICY
}
# Enable security policies


} else {
#Enabling firewall rules
netsh firewall set service type = remotedesktop mode = enable
# Enable group policies for MSTSC user session shadow
 if($ShadowSessionMSTSCOption -eq "No remote control allowed") {
    Copy-Item -Path "C:\GroupPolicies\MSTSC\No remote control allowed\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
    gpupdate /force
 }  
 if($ShadowSessionMSTSCOption -eq "Full Control with users permission") {
    Copy-Item -Path "C:\GroupPolicies\MSTSC\Full Control with users permission\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
    gpupdate /force
    }  
    if($ShadowSessionMSTSCOption -eq "Full Control without users permission") {
        Copy-Item -Path "C:\GroupPolicies\MSTSC\Full Control without users permission\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
        gpupdate /force
    } 
    if($ShadowSessionMSTSCOption -eq "View Session with users permission") {
        Copy-Item -Path "C:\GroupPolicies\MSTSC\View Session with users permission\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
        gpupdate /force
    } 
    if($ShadowSessionMSTSCOption -eq "View Session without users permission") {
        Copy-Item -Path "C:\GroupPolicies\MSTSC\View Session without users permission\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
        gpupdate /force
    } 
}
}