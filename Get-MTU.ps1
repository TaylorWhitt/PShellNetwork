# PShellNetwork
# Powershell Scripts to assist with networking optomizations.
# This is my very first scripting experience that actually does something useful - go easy on me/suggestions welcome.

Function Get-MTU {
    
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
    -Idx
    Identifies the local interface to change within the -Set switch. If left blank, you will be prompted with your options.
	
	.Example
	 Find-MTU www.google.com
        Will conduct a series of Do-Not-Fragment ping requests to "www.google.com" until a Maximum Transmission Unit is found, and output 
the result to the host. This does not account for the additional frame header which is an additional 24 or 28 bits depending on VLAN settings.
     .Example
     Find-MTU 8.8.8.8 -Set -ShowSteps
Will conduct a series of Do-Not-Fragment ping requests target 8.8.8.8 until a Maximum Transmission Unit is found.
Once found, will promt the user to select which interface is being used and will change the interface's MTU settings accordingly.
This will account for the additional frame header and detects VLAN settings. Each step will be written to the console.
**NOTE** "-Set" requires administrator privledges to implement network interface changes.
#>
    
    Param(
        [Parameter(Mandatory=$True,
                   Position=1,
                   HelpMessage='Server to ping')]
        [string]$Address,
        [Parameter(Mandatory=$False,
                   ParameterSetName='Set',
                   HelpMessage='Local interface index number.')]
        [int]$Idx,
        [Parameter(Mandatory=$False,
                   ParameterSetName='Set',
                   HelpMessage='Toggle to change the interface')]
        [switch]$Set,
        [int]$Timeout = "500",
        [int]$MaxMTU = "35840"
    ) #Param

    BEGIN {
    $PingObject = New-Object System.Net.NetworkInformation.Ping
    $PingOptions = New-Object System.Net.NetworkInformation.PingOptions
    [byte[]]$ByteBuffer = ,0xAC * $MaxMTU
    [void][int]$MTUSize
    [void][int]$Difference 
    [int]$Difference = [math]::Abs($MaxMTU)
    }

    PROCESS {
        Write-Verbose "Testing connection to $Address..."
        $TestPing = $PingObject.Send($Address,$Timeout,$($ByteBuffer[1]))
        if ($TestPing.status.ToString() -ne 'Success') {
            $TestPing.status.ToString()
            Write-Host "The address specified was not reachable. Please provide a reachable hostname or IP address, or try again. `nYou Provided: $Address"
            Break
        } #If

        if ($Set) {

            if ($Idx -ne $Null) {
                $Interface = $Idx
            } else {
                & netsh.exe interface ipv4 show interfaces |Out-Null
                $Interface = Read-Host 'Input which interface (Idx number) you would like to change'
            }

        & netsh.exe interface ipv4 set interface "interface=$Interface" "mtu=$MaxMTU"
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Insufficient credentials, or an invalid interface was provided.  Please try again."
                BREAK
            } #If
        } # If

        while ($Difference -gt 1) {

            Write-Verbose "Trying Size: $MTUSize"
            $TestPing = $PingObject.Send($Address,$Timeout,$($ByteBuffer[1..$MTUSize]),$PingOptions)
            $Ping     = $PingObject.Send($Address,$Timeout,$($ByteBuffer[1]))
            $Difference = [math]::Ceiling($Difference / 2 )
            if ($TestPing.status.ToString() -eq 'Success') {
                Write-Verbose "Success"
                $MTUSize += $Difference

            } else {
                if ($Ping.Status.ToString() -eq 'Success') {
                Write-Verbose "Failure"
                $MTUSize -= $Difference
                } else {
                Write-Verbose "Suspect packet drop, trying again."
                $Difference = [math]::Ceiling($Difference * 2 )
                } #If/Else
            } #If/Else
    
        } #While

        while ($Difference -eq 1 -and $Count -ne 2) {

        $TestPing = $PingObject.Send($Address,$Timeout,$($ByteBuffer[1..$MTUSize]),$PingOptions)
                
            if ($TestPing.status.ToString() -eq 'Success') {
            $MTUSize ++
            $Count ++
            Write-Verbose "Incrementing MTUSize: $MTUSize"

            } else { 

            $MTUSize -= 2 
            $Count = 0
            Write-Verbose "Failure, Count=$Count `nIncrementing MTUSize: $MTUSize"

            } #If/Else

        } #While

        $MTUSize -= 1
        Write-Verbose "Incrementing MTUSize: $MTUSize"
        $24MTUSize = $MTUSize + 24  # Add 24 bytes for packet header that is not included in ping size (payload) parameters.  (Payload+Header=MTU)
        $28MTUSize = $MTUSize + 28  # If the computer uses a VLAN, add 4 bytes for packet header.
            Write-Verbose "`n`n Optimal payload size of $MTUSize was found for the address: $Address `n The MTU size below should be <= $28MTUSize, depending on local VLAN options `n" 

        # Change internet adapter MTU settings.
        
        if ($Set) {

            Write-Verbose "Setting Local interface to: $24MTUSize to account for packet header"
            & netsh.exe interface ipv4 set interface "$Interface" "mtu=$24MTUSize" | Out-Null
        Write-Verbose "Testing with interface MTU set to detect VLAN settings."
        $TestPing = $PingObject.Send($Address,$Timeout,$($ByteBuffer[1..$MTUSize]),$PingOptions)
              
            if ($TestPing.status.ToString() -ne 'Success') {
                Write-Verbose "VLAN detected, setting MTU to: $28MTUSize"
                & netsh.exe interface ipv4 set interface "$Interface" "mtu=$28MTUSize" | Out-Null
                return ($24MTUSize)
            } else {
                Write-Verbose "VLAN not detected"
                return ($28MTUSize)
            }#If


        } else {
        return ($28MTUSize)
        } #If/Else
    } #Process
    END {}
} #Function
