# Windows PHP Manager
Simple tiny PowerShell script to download new PHP versions on Windows Server.

Downloads a new/specified PHP copy, and replicates the settings of the previous
version.Can also be used to maintain a fixed directory with adjustable PHP
versions.

## Example usage
`./upgrade-php.ps1 -Version 7.4`

Downloads the latest patch of PHP 7.4 into the set directory. If a previous
patch of 7.4 exists, it will pull across settings and extensions.

`./upgrade-php.ps1 -Version 7.4.2 -Symlink -Destination C:/PHP`

When run in an administration-level prompt, this downloads PHP 7.4.2 into the
set directory. If 7.4.1 or older exists, it will pull across settings and
extensions. Symlink will also create (or overwrite) a 'current' directory with a
hardlink to this version.