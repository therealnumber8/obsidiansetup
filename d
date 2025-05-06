<#
.SYNOPSIS
    Offline installer/upgrade for Microsoft Integration Runtime (IR).
    Uses a locally provided MSI instead of downloading from the Internet.

.EXAMPLE
    .\Install-IntegrationRuntime.ps1 -InstallerPath "C:\Installers\IntegrationRuntime_5.4.7954.2.msi"
    .\Install-IntegrationRuntime.ps1 -InstallerPath ".\IR.msi" -AllowDowngrade true -ServicePassword "P@ssw0rd!"
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $InstallerPath,

    [Parameter(Mandatory = $false)]
    [string] $Version,

    [Parameter(Mandatory = $false)]
    [string] $AllowDowngrade,

    [Parameter(Mandatory = $false)]
    [string] $ServicePassword
)

$ErrorActionPreference = 'Stop'
$ProductName        = 'Microsoft Integration Runtime'
$SupportedVersion   = [System.Version]::new('5.4.7793.1')

#region Utility functions
function Write-InfoMsg([string] $msg)  { Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')][Info]  $msg" }
function Write-ErrorMsg([string] $msg) { Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')][Error] $msg" -ForegroundColor Red }

function Get-RegistryKeyValue ([string] $Path) {
    [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,
                                               [Microsoft.Win32.RegistryView]::Registry64).OpenSubKey($Path)
}

function Get-IntegrationRuntimeIdentityNumber {
    Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' |
        Where-Object { $_.GetValue('DisplayName') -in "$ProductName","$ProductName Preview" } |
        Select-Object -ExpandProperty Name -First 1 | Split-Path -Leaf
}

function Get-CmdFilePath {
    $key = Get-RegistryKeyValue 'Software\Microsoft\DataTransfer\DataManagementGateway\ConfigurationManager'
    $path = $key.GetValue('DiacmdPath')
    if ([string]::IsNullOrWhiteSpace($path)) { throw 'Cannot find CLI executable file.' }
    (Split-Path -Parent $path) + '\dmgcmd.exe'
}

function Get-IntegrationRuntimeServiceAccount {
    (Get-WmiObject win32_service | Where-Object { $_.Name -eq 'DIAHostService' }).StartName
}

function Backup-IRConfig ([string] $installPath) {
    Write-InfoMsg 'Backing up configuration files...'
    Start-Process (Get-CmdFilePath) "-ucf `"$installPath`" store" -NoNewWindow -Wait -PassThru |
        Where-Object ExitCode -ne 0 | ForEach-Object { throw "Backup failed, exit code $_" }
}

function Restore-IRConfig ([string] $installPath) {
    Write-InfoMsg 'Restoring configuration files...'
    Start-Process (Get-CmdFilePath) "-ucf `"$installPath`" recover true" -NoNewWindow -Wait -PassThru |
        Where-Object ExitCode -ne 0 | ForEach-Object { throw "Restore failed, exit code $_" }
}

function Set-IRServiceAccount ([string] $account, [string] $password) {
    Write-InfoMsg 'Setting service account...'
    Start-Process (Get-CmdFilePath) "-ssa $account $password" -NoNewWindow -Wait -PassThru |
        Where-Object ExitCode -ne 0 | ForEach-Object { throw "Set service account failed, exit code $_" }
}

function Install-IntegrationRuntime ([string] $msi, [string] $installPath, [bool] $skipServiceStart) {
    Write-InfoMsg 'Installing Integration Runtime...'
    $args = @(
        '/i', "`"$msi`"",
        '/quiet'
    )
    if ($installPath)       { $args += "INSTALLLOCATION=`"$installPath`"" }
    if ($skipServiceStart)  { $args += 'SKIPSTARTSERVICE=Yes' }

    Start-Process 'msiexec.exe' $args -NoNewWindow -Wait -PassThru |
        Where-Object ExitCode -ne 0 | ForEach-Object { throw "Install failed, exit code $_" }
}

function Uninstall-IntegrationRuntime ([string] $identity) {
    Write-InfoMsg "Uninstalling existing $ProductName..."
    Start-Process 'msiexec.exe' "/x $identity /quiet KEEPDATA=1" -NoNewWindow -Wait -PassThru |
        Where-Object ExitCode -ne 0 | ForEach-Object { throw "Uninstall failed, exit code $_" }
}

function Get-VersionFromMsi ([string] $msiPath) {
    try {
        $installer = New-Object -ComObject WindowsInstaller.Installer
        $db        = $installer.GetType().InvokeMember('OpenDatabase','InvokeMethod',$null,$installer,@($msiPath,0))
        $view      = $db.GetType().InvokeMember('OpenView','InvokeMethod',$null,$db,('SELECT `Value` FROM `Property` WHERE `Property`=''ProductVersion'''))
        $view.GetType().InvokeMember('Execute','InvokeMethod',$null,$view,$null) | Out-Null
        $rec = $view.GetType().InvokeMember('Fetch','InvokeMethod',$null,$view,$null)
        $rec.GetType().InvokeMember('StringData','GetProperty',$null,$rec,1)
    } catch {
        throw "Cannot retrieve version from MSI: $($_.Exception.Message)"
    }
}
#endregion Utility functions

#region Privilege check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-ErrorMsg 'Run this script as Administrator!'
    exit 1001
}
#endregion Privilege check

#region Validate MSI and determine target version
if (-not (Test-Path -Path $InstallerPath -PathType Leaf)) {
    Write-ErrorMsg "Installer not found: $InstallerPath"
    exit 1002
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = Get-VersionFromMsi $InstallerPath
    Write-InfoMsg "Detected version $Version from MSI"
}

if (-not [System.Version]::TryParse($Version,[ref]([System.Version]$null))) {
    Write-ErrorMsg "Invalid version: $Version"
    exit 1003
}

if ([System.Version]$Version -lt $SupportedVersion) {
    Write-ErrorMsg "Installation of versions earlier than $SupportedVersion is unsupported."
    exit 1004
}

Write-InfoMsg "Target version to install: $Version"
#endregion Validate MSI and determine target version

#region Detect current install
$identity     = Get-IntegrationRuntimeIdentityNumber
$installed    = [bool]$identity

$currentVer   = if ($installed) {
    (Get-ItemProperty "registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$identity").DisplayVersion
}

$isDowngrade  = $installed -and ([System.Version]$Version -lt [System.Version]$currentVer)

if ($installed -and $Version -eq $currentVer) {
    Write-InfoMsg "Current $ProductName already at $Version – nothing to do."
    exit 0
}

if ($isDowngrade -and $AllowDowngrade -ne 'true') {
    Write-ErrorMsg 'Downgrade detected. Pass -AllowDowngrade true to proceed.'
    exit 1005
}
#endregion Detect current install

#region Service account handling
$serviceAccount = $null
if ($installed) {
    $svcAccount = Get-IntegrationRuntimeServiceAccount
    if ($svcAccount -ne 'NT SERVICE\DIAHostService') { $serviceAccount = $svcAccount }

    if ($serviceAccount -and $isDowngrade -and -not $ServicePassword) {
        Write-ErrorMsg "Provide -ServicePassword for service account '$serviceAccount' to downgrade."
        exit 1006
    }
}
#endregion Service account handling

#region Backup/uninstall if needed
$installedPath = if ($installed) {
    Split-Path -Parent -Parent -Parent (Get-CmdFilePath)
}

if ($installed -and $isDowngrade) {
    Backup-IRConfig -installPath (Join-Path $installedPath "$(([System.Version]$currentVer).Major).0")
    Uninstall-IntegrationRuntime $identity
}
#endregion Backup/uninstall if needed

#region Install
Install-IntegrationRuntime -msi $InstallerPath `
                           -installPath $installedPath `
                           -skipServiceStart ([bool]$serviceAccount)
#endregion Install

#region Restore config & account if downgraded
if ($isDowngrade) {
    try   { Restore-IRConfig (Join-Path $installedPath "$(([System.Version]$Version).Major).0") }
    catch { Write-ErrorMsg $_ }

    if ($serviceAccount) {
        try   { Set-IRServiceAccount $serviceAccount $ServicePassword }
        catch { Write-ErrorMsg $_ }
    }
}
#endregion Restore config & account if downgraded

Write-InfoMsg 'Installation completed.'
if (-not $installed) {
    Write-InfoMsg "Open $ProductName to register your node."
}

