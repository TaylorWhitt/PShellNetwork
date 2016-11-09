#Work in progress, requires executable switches for silent install and importing of Get-File, Get-InstalledApps.  Want to expand for multiple file and related switch parameters, and detection of current version of software.
Function Install-3rdPartyApplication {
[CmdletBinding()]
Param(
[Parameter(Mandatory = $False,ValueFromPipeline = $True)]
[string[]]$PatchFile = (Get-File),
[string]$Arguments,
$ComputerNames = @('localhost'),
$UserName = $env:USERNAME,
[bool]$UninstallFirst = $False,
$UninstallName
)
$file = $PatchFile.Split('\')
$filename = $file[($file.count - 1)]
Remove-Variable file
ForEach ($Computer in $ComputerNames) {   
    Foreach ($file in $filename) { 
    $AppInfo = Get-InstalledApps -NameRegex $UninstallName -computers $Computer
        if ($Uninstallstring -and $uninstallFirst) {
            ForEach ($Uninstallstring in $AppInfo.uninstallstring) {
            $Uninstallstring
            Invoke-WmiMethod -Class win32_process -ComputerName $Computer -Name create -ArgumentList  "$Uninstallstring"
            }
        }
    }
    $Destination = "\\$Computer\C`$\Users\$UserName\Desktop"
#Step 2, copy files over.
    
    Copy-Item $PatchFile -Destination "$Destination" -PassThru -Force

#Step 3, Install.
    $installprocess = Invoke-WmiMethod -Class win32_process -ComputerName $Computer -Name create -ArgumentList  "$Destination\$file $Arguments"
    $Id = $installprocess.ProcessId
    While (Get-process -ComputerName $Computer | where {$_.Id -EQ "$Id"})
    {Sleep 10}
    Get-Item -Path "$Destination\$file" | Remove-item -force -Verbose
}

}
