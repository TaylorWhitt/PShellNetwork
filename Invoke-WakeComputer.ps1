Function Invoke-WakeComputer {
[CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True,
        Position=1,
        ParameterSetName = 'ByMAC',
        HelpMessage='MAC address(es) of computer(s) to wake',
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True)]
    [string[]]$MAC,
    [Parameter(Mandatory=$False,
        Position=2,
        HelpMessage='Computer Name, IP, or Broadcast address of Computer to wake. Default is local subnet.',
        ValueFromPipelineByPropertyName=$True)]
    $ComputerName = ([System.Net.IPAddress]::Broadcast),
    [int]$Retry = 1,
    [Parameter(Mandatory=$True,
        Position=1,
        ParameterSetName = 'FromFile',
        HelpMessage='File containing MAC addresses of computer(s) to wake',
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True)]
    [string]$FromFile,
    [Parameter(Mandatory=$True,
        Position=2,
        ParameterSetName = 'FromFile',
        HelpMessage='Header for MAC address of computers to wake',
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True)]
    [string]$MACHeader,
    [Parameter(Mandatory=$True,
        Position=3,
        ParameterSetName = 'FromFile',
        HelpMessage='Header for hostnames or IPs to wake',
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True)]
    [String]$ComputerHeader,
    [int]$Packets
    )
    BEGIN {
    IF ($FromFile) {
    $File = Import-CSV $FromFile | select @{Name='MAC';Expression="$MACHeader"},@{Name='ComputerName';Expression="$ComputerHeader"}} 
    }
    Process {
        $List = @()
        if ($MAC) {
        $MAC
        $List += $MAC}
        if ($FromFile) {
        $List += $File}
        ForEach ($Address in $List) {
            IF ($FromFile) {
            $ComputerName = $Address.ComputerName
            $ComputerName = [System.Net.DNS]::GetHostEntry("$ComputerName").hostname
            $MACBytes = ($Address.MAC -replace '[-:.]','' -replace '[{}]','').ToUpper()
            }
            IF ($MAC) {
            $MACBytes = ($Address -replace '[-:.]','' -replace '[{}]','').ToUpper()
            }
            $MACBytes =  [Net.NetworkInformation.PhysicalAddress]::Parse($MACBytes)
            [string]$Value = $MACBytes.ToString()
            if ($Value.Length -eq 12) {
                $MagicPacket = [byte[]]@(255,255,255, 255,255,255);
                $MagicPacket += ($MACBytes.GetAddressBytes()*16)
                Write-Verbose "Sending Packet to $MACBytes, at $ComputerName"
                $UdpClient = New-Object System.Net.Sockets.UdpClient
                $UdpClient.Connect($ComputerName,7)
                $UdpClient.Send($MagicPacket,$MagicPacket.Length)
                Write-Verbose "Packet Sent"
                $UdpClient.Close()
            } else {
                Write-Error "The MAC Address specified is not of the correct length: $Value" 
            }
        }
    }
    END {}
}
