<#
.Synopsis
   Performs actions similiar to tracert.exe
.DESCRIPTION
   Performs actions similiar to tracert.exe using the .NET framework, but returns the not-null values as an array.
.NOTES
   File Name   :  Trace-Route.ps1
   Author      :  Taylor Whitt
.LINKS
   https://github.com/TaylorWhitt
#>
Function Trace-Route {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Address = 'www.google.com',
        [Parameter()]
        [int]$Timeout = 5000,
        [Parameter()]
        [int]$MaxTTL  = 64,
        [Parameter()]
        [string]$Message = 'MESSAGE',
        [Parameter()]
        [bool]$DoNotFragment = $false,
        [Parameter()]
        [int]$MaxBlankHops = 5,
        [Parameter()]
        [bool]$Resolve = $false
    )

    BEGIN {
        $ping = new-object System.Net.NetworkInformation.Ping
        $msg = [System.Text.Encoding]::Default.GetBytes("$Message")
        $success = [System.Net.NetworkInformation.IPStatus]::Success
        $Hoplist = @()
        [int]$BlankHops = 0

    }
    PROCESS {
        Try {
        $ping.Send("$Address") | Out-Null
        Write-Verbose "Tracing $Address"
        for ($TTL=1;$TTL -le $MaxTTL; $TTL++) {
            $PingOptions = new-object System.Net.NetworkInformation.PingOptions($TTL, $DoNotFragment)   
            $Reply = $Ping.Send($Address, $Timeout, $msg, $PingOptions)
            $Hop = '' | select Hop,Address
            $addr = $reply.Address
            $rtt = $reply.RoundtripTime
            If($Resolve) {
                $Hop = '' | select Hop,Address,Name
                $dns = [System.Net.Dns]::GetHostByAddress($addr)
                $name = $dns.HostName
                $Hop.Name = $name
            }


            $Hop.Hop = $TTL
            $Hop.Address = $addr
            
            Write-Verbose "Hop: $TTL`t= $addr`t($name)"
            if (!$Hop.Address) {
                $BlankHops++
                if ($BlankHops -ge $MaxBlankHops) {break}
            } else {
                $Hoplist += $Hop
            }

            if($Reply.Status -eq $success) {break}
        }
        } catch [System.Net.NetworkInformation.PingException] {
        Write-Error "Unable to construct a proper PING packet. Please check the address provided: $Address"
        {exit}
        }
    }
    END {
        Write-Output $Hoplist
    }
}
