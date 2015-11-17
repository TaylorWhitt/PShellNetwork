# PShellNetwork
# Powershell Scripts to assist with networking optomizations.
# This is my very first scripting experience that actually does something useful - go easy on me/suggestions welcome.
# There are a few bugs and future improvements annotated within the script.


# Define parameters (future - selectable/prompt with defaults, logarithmic scaling starting at 0)
# Future/side project, tracreroute and perform on per-hop basis to detect which network segments are causing overhead.  
# (useful in an enterprise enviornment)

$IPAddress = "www.google.com"
$MaxMTU = 1536
$MinMTU = 1000
$MTUSize = 1001
$MTUMaxFound = $false

# Start low, go high.  Successful pings are quicker than no reply caused by proxy or like devices.
while (-not $MTUMaxFound) {
    
    ping -f $IPAddress -l $MTUSize -n 1
    
    if ($LASTEXITCODE -eq 0) {
        $MTUSize += 5        
    } else {
        Write-Host "Ping was fragmented"
        $MTUMaxFound = $true
    }
    
        if ($MTUSize -gt $MaxMTU) {
        Write-Host "MTU is above threshold.  Congratulations, your network can support Jumbo packets end-to-end!"
        $MTUMaxFound = $true
        # (Future) Skip to optimized starting location for finding scaled MTU for Jumbo frames.
    }

}
# Need retry with counter (or error code specificity) to account for packet-loss possibility (future)

$MTUSizeFound = $false

while (-not $MTUSizeFound) {
    
    ping -f $IPAddress -l $MTUSize -n 1
    
    if ($LASTEXITCODE -ne 0) {
        $MTUSize -= 1

    } else {
    
        Write-Host "Ping was fragmented"
        $MTUSizeFound = $true
    }
    
        if ($MTUSize -lt $MinMTU) {
        Write-Host "MTU is below threshold or something is blocking the PING protocol."
        $MTUSizeFound = $true
    }
}

# Add 28 bits for frame header that is not included in ping size (payload) parameters.  (Payload+Header=MTU)
# Need VLAN detection for optional 4 bits in header.

$MTUSize=$MTUSize+28
Write-Host "MTU Size: $MTUSize"

# Change internet adapter MTU settings.

netsh interface ipv4 show interfaces
$Interface = Read-Host -Prompt 'Input which interface (Idx number) you would like to change'
netsh interface ipv4 set interface "$Interface" "mtu=$MTUSize"
netsh interface ipv4 show interfaces
