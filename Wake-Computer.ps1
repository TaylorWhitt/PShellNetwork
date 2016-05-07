Function Wake-Computer {
[CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True,
        Position=1,
        HelpMessage='MAC address of comptuer to wake',
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True)]
    [string[]]$Mac
    )
    Process {
        ForEach ($Address in $Mac) {
            $MacByteArray = $Mac -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
            [Byte[]] $MagicPacket = (,0xFF * 6) + ($MacByteArray  * 16) 
            Write-Verbose "Sending Packet to $Address"
            $UdpClient = New-Object System.Net.Sockets.UdpClient
            $UdpClient.Connect(([System.Net.IPAddress]::Broadcast),7)
            $UdpClient.Send($MagicPacket,$MagicPacket.Length) | Out-Null
            Write-Verbose "Packet Sent"
            $UdpClient.Close()
        }
    }
}

