# PShellNetwork
# Powershell Scripts to assist with networking optomizations.
# This is my very first script I worked on.  It has come all the way from using PING.exe!

Function Get-MTU {
    
    <#
    .Synopsis
	Will conduct a series of ping requests to a target host with DF bit set.
    .Description
	Will conduct a series of ping requests to a target host with DF bit set.
    -Set 
    Will perform netsh commands and prompt the user to change the interface specified to optimal settings.
    *Requires elevated privledges*
    -Idx
    Identifies the local interface to change within the -Set switch. If left blank, you will be prompted with your options.
    -MaxMTU
    Limits the highest number of bytes in the packet to test for (default 1544)
    -Timeout
    Changes the timeout parameter in miliseconds of the ping packet (default 2000)
	
	.Example
	 Get-MTU www.google.com
        Will conduct a series of Do-Not-Fragment ping requests to "www.google.com" until a Maximum Transmission Unit is found, and output 
the result to the host.  If the value is that of the interface used, it may not represent the maximum value.
     .Example
     Get-MTU 8.8.8.8 -Set
After prompting which interface (Idx) will be set and changes the max value to $MaxMTU, will conduct a series of Do-Not-Fragment ping requests target 8.8.8.8 until a Maximum Transmission Unit is found.
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
        [int]$Timeout = "2000",
        [int]$MaxMTU = "1544",
        [switch]$Retry
    ) #Param

    BEGIN {
    $PingObject = New-Object System.Net.NetworkInformation.Ping
    $PingOptions = New-Object System.Net.NetworkInformation.PingOptions
    [byte[]]$ByteBuffer = ,0xff * $MaxMTU
    [void][int]$MTUSize
    [void][int]$Difference 
    [int]$Difference = $MaxMTU
    }

    PROCESS {

        Write-Verbose "Testing connection to $Address..."
        $TestPing = $PingObject.Send($Address,$Timeout,$($ByteBuffer[1]))
        if ($TestPing.status.ToString() -ne 'Success') {
            Write-Verbose "The address specified was not reachable. Please provide a reachable hostname or IP address, or try again. `nYou Provided: $Address"
            return {Target Unreachable}
        } #If

        if ($Set) {
            #Temporary fix to odd bug where if MaxMTU was set below Interface capability, it would continue past the value (I suppose due to internal fragmentation).
            $MaxMTU += 28
            if ($Idx) {
                $Interface = $Idx
            } else {
                & netsh.exe interface ipv4 show interfaces 
                $Interface = Read-Host 'Input which interface (Idx number) you would like to change'
            }
            & netsh.exe interface ipv4 set interface "interface=$Interface" "mtu=$MaxMTU" | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Insufficient credentials, or an invalid interface was provided.  Please try again.  Continuing to find MTU with current settings..."
                $Set = $Null
            } #If
        } # If
        $MTUSize = 0
        $DifferenceCount = 0
        $LastLatency = $Timeout
        while (($Difference -gt 1 -or $TestPing.Status.Tostring() -eq 'Success' -or $DifferenceCount -le 1) -and $MTUSize -lt ($MaxMTU - 24)) {
            Write-Verbose "Trying Size: $MTUSize"
            $TestPing = $PingObject.Send($Address,$Timeout,$($ByteBuffer[1..$MTUSize]),$PingOptions)
            if ($Difference -eq 1) { $DifferenceCount += 1 
            } else { $Difference = [math]::Ceiling($Difference / 2 ) 
            } #If/Else
            if ($TestPing.status.ToString() -eq 'Success') {
                Write-Verbose "Success"
                $MTUSize += $Difference
                $LastLatency = ($TestPing.RoundtripTime + 15)
            } else {
                if ($Retry) {
                $TestPing = $PingObject.Send($Address,$LastLatency,$($ByteBuffer[1..$MTUSize]),$PingOptions)
                }
                if ($TestPing.Status.ToString() -ne 'Success') {
                Write-Verbose "Failure"
                $MTUSize -= $Difference
                } else {
                Write-Verbose "Suspect packet drop, trying again."
                $Difference = [math]::Ceiling($Difference * 2 )
                } #If/Else
            } #If/Else

        } #While

        
        $28MTUSize = $MTUSize + 28  # Add room for header information.  (Payload+Header=MTU)
        Write-Verbose "`n`n Optimal payload size of $MTUSize was found for the address: $Address `n The MTU size below should be <= $28MTUSize"

        # Change internet adapter MTU settings.
        
        if ($Set) {

            Write-Verbose "Setting Local interface to: $28MTUSize to account for packet header."
            & netsh.exe interface ipv4 set interface "$Interface" "mtu=$28MTUSize" | Out-Null

        } #If
        Return ($28MTUSize)
    } #Process
    END {}
} #Function
