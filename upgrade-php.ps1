<#
.SYNOPSIS
Downloads a new/specified PHP copy.

.DESCRIPTION
Downloads a new/specified PHP copy, and replicates the settings of the previous version.
Can also be used to maintain a fixed directory with adjustable PHP versions.

.LINK
https://github.com/bredigital/win-php-manager

.NOTES
Version:        1.0
Author:         Casey Lambie, BRE Digital
Creation Date:  17/01/2020
License:        GPL-3.0

.EXAMPLE
./upgrade-php.ps1 -Version 7.4.1

Downloads PHP 7.4.1 into the set directory. If 7.4.0 exists, it will pull across settings
and extensions.
.EXAMPLE
./upgrade-php.ps1 -Version 7.4.2 -Symlink -Destination C:/PHP

When run in an administration-level prompt, this downloads PHP 7.4.2 into the set
directory. If 7.4.1 exists, it will pull across settings and extensions. Symlink will
also create (or overwrite) a 'current' directory with a hardlink to this version.
#>
param (
    [string]$version = '',
    [ValidateScript({Test-Path $_})][string]$destination = '.',
    [switch]$symlink = $false
)

# No PHP version specified? Let's find the latest release.
$majorVersion = 7;
if ( -not ( $version ) ) {
    try{
        $a = Invoke-RestMethod -Uri "https://www.php.net/releases/index.php?json&version=${majorVersion}&max=1"  -TimeoutSec 2;
        $version = $a.PSObject.Properties.Name;
        if ( $version -eq 'error' ) {
            Write-Host "No version specified. Bad response from PHP APIs (got '${version}'). Exiting.";
            return;
        }
    } catch {
        Write-Host "No version specified, and unable to parse PHP website for latest version. Exiting.";
        return;
    }
}

# If symlink is desired, check if running in an elevated prompt.
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$runningAsAdmin   = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator);
if( ( $symlink -eq $true ) -and ( $runningAsAdmin -eq $false ) ) {
    Write-Host "Symlinking the PHP version requires administrative prvilegess.";
    exit;
}

# Probe for existing version.
if( Test-Path -Path "${destination}\${version}" ) {
    Write-Host "Version ${version} already exists. Exiting.";
    return;
}

# Probe the PHP site (and archive) for desired PHP version.
Write-Host "Downloading PHP ${version} from windows.php.net.";
try {
    Invoke-WebRequest https://windows.php.net/downloads/releases/php-$version-nts-Win32-VC15-x64.zip -OutFile "${destination}\php.zip";
} catch {
    Write-Host "Not found in release. Looking in archives.";
    try {
        Invoke-WebRequest https://windows.php.net/downloads/releases/archives/php-$version-nts-Win32-VC15-x64.zip -OutFile "${destination}\php.zip";
    } catch {
        Write-Host "Not found in archive. Exiting.";
        return;
    }
}
Expand-Archive -Path "${destination}\php.zip" -DestinationPath "${destination}\${version}";
Remove-Item    -Path "${destination}\php.zip";

$versionSplit    = $version.split(".");
$versionSplit[2] = $versionSplit[2] - 1;
$previousVersion = $versionSplit -Join ".";

# Copy previous installation configuration and missing extensions.
if( Test-Path -Path "${destination}\${previousVersion}" ) {
    Write-Host "Coping configuration file from ${previousVersion}.";
    Copy-Item -Path "${destination}\${previousVersion}\php.ini" -Destination "${destination}\${version}\php.ini"

    $old_extpath = "${destination}\${previousVersion}\ext";
    $new_extpath = "${destination}\${version}\ext";
    Get-ChildItem $old_extpath -Filter *.dll |
    Foreach-Object {
        $filename = $_;
        if( -Not ( Test-Path -Path "${new_extpath}\${filename}" ) ) {
            Write-Host "Copying '${filename}' over to the new version.";
            Copy-Item -Path "${old_extpath}\${filename}" -Destination "${new_extpath}\${filename}"
        }
    }
} else {
    Write-Host "No previous version was found. Initating config with default production settings.";
    Copy-Item -Path "${destination}\${version}\php.ini-production" -Destination "${destination}\${version}\php.ini"
}

# Create/replace symlink to this version.
switch ( $symlink ) {
    $true {
        $abs = Resolve-Path $destination;
        New-Item -ItemType symboliclink -Path $abs -Name current -Value "${abs}\${version}" -Force | Out-Null;
        Write-Host "'current' directory now linked to ${version}.";
        break;
    }
    default { break; }
}
