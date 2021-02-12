<#
.SYNOPSIS
FS Logix Configuration, TeamsApp setup, User session shadowing configuration
.DESCRIPTION
This script is used configure the fs logix, TeamsApp setup, user session shadowing configuration.
#>
param(
    [Parameter(mandatory = $false)]
    [string]$StorageAccountKey,

    [Parameter(mandatory = $false)]
    [string]$FileShareURL,

    [Parameter(mandatory = $false)]
    [string]$sharedLocationPath,


    [Parameter(mandatory = $false)]
    [string]$IsTeamsAppSetup,

    [Parameter(mandatory = $false)]
    [string]$IsUserSessionShadow,

    [Parameter(mandatory = $false)]
    [string]$ShadowSessionMSTSCOption,

    [Parameter(mandatory = $false)]
    [string]$ShadowSessionMSRA,

    [Parameter(mandatory = $false)]
    [string]$ShadowSessionMSRAOption

)

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false	
if ($FileShareURL) {
    #Static values
    $fslogixDownloadURI = "https://download.microsoft.com/download/5/8/4/58482cbd-4072-4e26-9015-aa4bbe56c52e/FSLogix_Apps_2.9.7205.27375.zip"
    $OutFile = "C:\FSLogix.zip"
    $DestinationPath = "C:\FSLogixInstallers"
    New-Item -Path $DestinationPath -ItemType "directory"
    if ($StorageAccountKey) {
        $StorageAccount = $FileShareURL.Split(".").Trim("\\")[0]
        New-Item -Path "C:\UbikitePSL" -ItemType "directory"
@"
param(
[Parameter(mandatory = `$True)]
[array]`$SignInNames
)
`$DriveInfo = Get-PSDrive -Name b -ErrorAction SilentlyContinue
if(`$DriveInfo -eq `$null){
net use b: $FileShareURL $StorageAccountKey /user:Azure\$StorageAccount
}
foreach(`$SignInName in `$SignInNames){
cmd /c "icacls b: /grant `${`$SignInName}:(f)"
}
"@ | Out-File "C:\UbikitePSL\FSGrantingToUser.ps1"
}

    Invoke-WebRequest -Uri $fslogixDownloadURI -OutFile $OutFile
    Expand-Archive -Path $OutFile -DestinationPath $DestinationPath
    Invoke-Expression -Command "cmd.exe /c C:\FSLogixInstallers\x64\Release\FSLogixAppsSetup.exe /quiet"
    $FSRegistry = Get-Item -Path "HKLM:\Software\FSLogix"
    if ($FSRegistry) {
        New-Item -Path "HKLM:\Software\FSLogix" -Name "Profiles" -Force
        $registryPath = "HKLM:\Software\FSLogix\Profiles"
        New-ItemProperty -Path $registryPath -Name "Enabled" -Value 1 -PropertyType "DWORD" -Force | Out-Null
        New-ItemProperty -Path $registryPath -Name "VHDLocations" -Value $FileShareURL -PropertyType "Multistring" -Force | Out-Null
    }
}


if ($IsUserSessionShadow -eq "true") {
    $GpDownloadURI = "https://raw.githubusercontent.com/people-tech-group/ubikite/master/Add%20Sessionhosts%20to%20hostpool/DSC/GroupPolicies.zip"
    $OutFile = "C:\GroupPolicies.zip"
    $DestinationPath = "C:\GroupPolicies"
    New-Item -Path $DestinationPath -ItemType "directory"
    Invoke-WebRequest -Uri $GpDownloadURI -OutFile $OutFile
    Expand-Archive -Path $OutFile -DestinationPath $DestinationPath
    If ($ShadowSessionMSRA -eq "true") {
        # Activate Remote Assistance (automated)
        REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 1 /f
        # Configure firewall policies on your WVD
        netsh firewall set service type = remotedesktop mode = enable
        # Enable Group Policies for MSRA
        if ($ShadowSessionMSRAOption -eq "Allow helpers to remotely control the computer") {
            Copy-Item -Path "C:\GroupPolicies\MSRA\Allow helpers to remotely control the computer\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
            gpupdate /force
            secedit.exe /configure /db secedit.sdb /cfg C:\GroupPolicies\MSRA\secconfig.cfg /areas SECURITYPOLICY
        }
        if ($ShadowSessionMSRAOption -eq "Allow helpers to only view the computer") {
            Copy-Item -Path "C:\GroupPolicies\MSRA\Allow helpers to only view the computer\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
            gpupdate /force
            secedit.exe /configure /db secedit.sdb /cfg C:\GroupPolicies\MSRA\secconfig.cfg /areas SECURITYPOLICY
        }
        # Enable security policies
        
        
    }
    else {
        #Enabling firewall rules
        netsh firewall set service type = remotedesktop mode = enable
        # Enable group policies for MSTSC user session shadow
        if ($ShadowSessionMSTSCOption -eq "No remote control allowed") {
            Copy-Item -Path "C:\GroupPolicies\MSTSC\No remote control allowed\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
            gpupdate /force
        }  
        if ($ShadowSessionMSTSCOption -eq "Full Control with users permission") {
            Copy-Item -Path "C:\GroupPolicies\MSTSC\Full Control with users permission\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
            gpupdate /force
        }  
        if ($ShadowSessionMSTSCOption -eq "Full Control without users permission") {
            Copy-Item -Path "C:\GroupPolicies\MSTSC\Full Control without users permission\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
            gpupdate /force
        } 
        if ($ShadowSessionMSTSCOption -eq "View Session with users permission") {
            Copy-Item -Path "C:\GroupPolicies\MSTSC\View Session with users permission\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
            gpupdate /force
        } 
        if ($ShadowSessionMSTSCOption -eq "View Session without users permission") {
            Copy-Item -Path "C:\GroupPolicies\MSTSC\View Session without users permission\*" -Destination "C:\Windows\System32\GroupPolicy" -Force -Recurse -Verbose
            gpupdate /force
        } 
    }
}

if ($IsTeamsAppSetup -eq "true") {
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
    Invoke-Expression -Command "cmd.exe /c 'c:\TeamsInstallers\vc_redist.x64.exe' /quiet"
    Invoke-Expression -Command "cmd.exe /c 'c:\TeamsInstallers\MsRdcWebRTCSvc_HostSetup_0.11.0_x64.msi' /quiet"
}