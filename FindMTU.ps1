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

  -Idx
  Will select the local interface to change within the -Set switch. If left blank, you will be prompted with your options.
	.Example
	 Find-MTU www.google.com
        Will conduct a series of Do-Not-Fragment ping requests to "www.google.com" until a Maximum Transmission Unit is found, and output 
the result to the host. This does not account for the additional frame header which is an additional 24 or 28 bits depending on VLAN settings.
     .Example
     Find-MTU 8.8.8.8 -Set -ShowSteps
Will conduct a series of Do-Not-Fragment ping requests target 8.8.8.8 until a Maximum Transmission Unit is found.
Once found, will promt the user to select which interface is being used and will change the interface's MTU settings accordingly.
This will account for the additional frame header and detects VLAN settings. Each step will be written to the console as a Gee-Wiz.

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
        [switch]$ShowSteps
    ) #Param

    BEGIN {}

    PROCESS {

    [int]$MaxMTU = 1500
    [int]$MTUSize = $Null
    [int]$Difference = [math]::Truncate(($MaxMTU - $MinMTU) / 2)
    [int]$Numberofsteps = 0
    [int]$Count = 0

        & PING.EXE $Address -n 2 | Out-Null
        if ($LASTEXITCODE -ne 0) {
    Write-Host "The address specified was not reachable. Please provide a reachable hostname or IP address, or try again.
You Provided: $Address"
    Break
        } #If

        if ($Set) {



        if ($Idx -ne $Null) {
        $Interface = $Idx
        } else {
        & netsh.exe interface ipv4 show interfaces
        $Interface = Read-Host 'Input which interface (Idx number) you would like to change'
        }

        & netsh.exe interface ipv4 set interface "$Interface" "mtu=$MaxMTU"
            if ($LASTEXITCODE -ne 0) {
            Write-Host 'Insufficient credentials, or an invalid interface was provided.  Please try again.'
                BREAK
            } #If
        } # If
        if ($ShowSteps) {Write-Host "Testing connection to $Address..."} #If

        while ($Difference -gt 1) {
        $Numberofsteps ++

            if ($Showsteps) {
            Write-Host "Trying Size: $MTUSize
            "
            Write-Host "Incrementing steps: $Numberofsteps"
            } #If

        & '.\PING.EXE' -f $Address -l $MTUSize -n 1 | Out-Null

    
            if ($LASTEXITCODE -eq 0) {
                if ($ShowSteps) {
                    Write-Host "Splitting difference: $Difference
                    Difference: $Difference"
                } #If

                $MTUSize += $Difference
                $Difference = [math]::Truncate($Difference / 2 )        

                } else {
                    if ($ShowSteps) {
                        Write-Host "Splitting difference: $Difference"
                    } #If

                    $MTUSize -= $Difference
                    $Difference = [math]::Truncate($Difference / 2 )

                } #If/Else
    
        } #While

        while ($Difference -eq 1 -and $Count -ne 2) {

        & PING.EXE -f $Address -l $MTUSize -n 1 | Out-Null

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
                Write-Host "Failure, Count=$Count
                Incrementing MTUSize: $MTUSize"
                
                } #If
            } #If/Else

        } #While

        $MTUSize -= 1

        if ($ShowSteps) {
            Write-Host "Incrementing MTUSize: $MTUSize"
        } #If

        $24MTUSize = $MTUSize + 24  # Add 24 bits for frame header that is not included in ping size (payload) parameters.  (Payload+Header=MTU)
        $28MTUSize = $MTUSize + 28  # If the computer uses a VLAN, add 4 bits to frame header.
            Write-Host "
        
 Optimal payload size of $MTUSize was found in $Numberofsteps steps for the address: $Address
 The MTU size below should be <= $28MTUSize" 

        # Change internet adapter MTU settings.
        
        if ($Set) {

            if ($ShowSteps) {
                        Write-Host "Setting Local interface to: $24MTUSize to account for frame header"
            } #If
        & netsh.exe interface ipv4 set interface "$Interface" "mtu=$24MTUSize" | Out-Null
        
        & PING.EXE -f $Address -l $MTUSize -n 1 | out-null

            if ($LASTEXITCODE -ne 0) {
                if ($ShowSteps) {
                    Write-Host "VLAN detected, setting MTU to: $28MTUSize"
                } #If
            & netsh.exe interface ipv4 set interface "$Interface" "mtu=$28MTUSize" | Out-Null
            } #If
        Write-Host '
        Current Configuration:
        '
        & netsh.exe interface ipv4 show interfaces


        } else {
        Write-Host 'This number is based on your current settings below:'
        & netsh.exe interface ipv4 show interfaces
        } #If/Else
    } #Process

    END {}

} #Function
