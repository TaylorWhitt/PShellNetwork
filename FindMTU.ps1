# PShellNetwork
# Powershell Scripts to assist with networking optomizations.
# This is my very first scripting experience that actually does something useful - go easy on me/suggestions welcome.
# I still need error handling and detection for low MTU settings.

Function Find-MTU {
    
    <#
    .Synopsis
		Will conduct a series of ping requests to a target host with DF bit set.
	.Description
		Will conduct a series of ping requests to a target host with DF bit set.

		-Set 
Will perform netsh commands and prompt the user to change the interface specified to optimal settings.
*Requires elevated privledges*

  -ShowSteps 
  Will write messages to the console to walk the user through the steps being performed within the function.
	.Example
	 Find-MTU www.google.com
        Will conduct a series of Do-Not-Fragment ping requests to "www.google.com" until a Maximum Transmission Unit is found, and output 
the result to the host. This does not account for the additional frame header which is an additional 24 or 28 bits depending on VLAN settings.
     .Example
     Find-MTU 8.8.8.8 -Set -ShowSteps
Will conduct a series of Do-Not-Fragment ping requests target 8.8.8.8 until a Maximum Transmission Unit is found.
Once found, will promt the user to select which interface is being used and will change the interface's MTU settings accordingly.
It will account for the additional frame header and detects for VLAN settings. Each step will be written to the console as a Gee-Wiz.

**NOTE** "-Set" requires administrator privledges to implement network interface changes.
#>
    
    Param(
        [Parameter(Mandatory=$True,
                   Position=1,
                   HelpMessage='Server to ping')]
        [string]$Address,
        [switch]$Set,
        [switch]$ShowSteps
    ) #Param

    BEGIN {}

    PROCESS {

    [int]$MaxMTU = 1536
    [int]$MinMTU = $Null
    [int]$MTUSize = $Null
    [bool]$MTUMaxFound = $false
    [int]$Difference = [math]::Truncate(($MaxMTU - $MinMTU) / 2)
    [int]$Numberofsteps = 0
    [int]$Count = 0

    while ($Difference -gt 1) {
        $Numberofsteps ++
        if ($Showsteps) {
        Write-Host "Trying Size: $MTUSize
        "
        Write-Host "Incrementing steps: $Numberofsteps"
        }

        ping -f $Address -l $MTUSize -n 1 | out-null
        
    
            if ($LASTEXITCODE -eq 0) {
                if ($ShowSteps) {
                    Write-Host "Splitting difference (round down): $Difference"
                } #If
                $MTUSize += $Difference
                $Difference = [math]::Truncate($Difference / 2 )        
            
            if ($ShowSteps) {
                    Write-Host "Difference: $Difference"
            } #If

            } else {
                if ($ShowSteps) {
                    Write-Host "Splitting difference: $Difference"
                } #If
                $MTUSize -= $Difference
                $Difference = [math]::Truncate($Difference / 2 )

            } #If/Else
    
        } #While

    while ($Difference -eq 1 -and $Count -ne 2) {

        ping -f $Address -l $MTUSize -n 1 | out-null
        $Numberofsteps ++
        if ($ShowSteps) {
            Write-Host "Incrementing steps: $Numberofsteps"
        } #If

            if ($LASTEXITCODE -eq 0) {
                
            $MTUSize ++
            $Count ++
                if ($ShowSteps) {
                    Write-Host "Incrementing MTUSize: $MTUSize
                    Incrementing Count: $Count"
                } #If

            } else { 

            $MTUSize -= 2 
            $Count = 0
            if ($ShowSteps) {
                Write-Host "Incrementing MTUSize: $MTUSize
                Failure, Count=$Count"
                } #If
            } #If/Else

        } #While

    $MTUSize -= 1

    if ($ShowSteps) {
        Write-Host "Incrementing MTUSize: $MTUSize"
    } #If
    Write-Host "Optimal MTU size of $MTUSize was found in $Numberofsteps steps."
        
    # Change internet adapter MTU settings.
        
    if ($Set) {

    $24MTUSize = $MTUSize + 24  # Add 24 bits for frame header that is not included in ping size (payload) parameters.  (Payload+Header=MTU)
    $28MTUSize = $MTUSize + 28  # If the computer uses a VLAN, add 4 extra bits to frame header.

    netsh interface ipv4 show interfaces


    $Interface = Read-Host 'Input which interface (Idx number) you would like to change'
    if ($ShowSteps) {
                Write-Host "Setting Local interface to: $24MTUSize to account for frame header"
    } #If
    Try {netsh interface ipv4 set interface "$Interface" "mtu=$24MTUSize"} #Try
    catch {} #Catch
        
    ping -f $Address -l $MTUSize -n 1 | out-null | Wait-Event

        if ($LASTEXITCODE -ne 0) {
            if ($ShowSteps) {
                Write-Host "VLAN detected, setting MTU to: $28MTUSize"
            } #If
        netsh interface ipv4 set interface "$Interface" "mtu=$28MTUSize"
        } #If
    Write-Host '
    Current Configuration:
    '
    netsh interface ipv4 show interfaces


    } #If

    } #Process

    END {}

} #Function
