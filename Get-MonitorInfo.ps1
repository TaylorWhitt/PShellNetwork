function Get-MonitorInfo {
    param (
        [Parameter(ValueFromPipeline=$true)]
        $Properties = @(
  @{
    name       = 'Model'
    expression = {
      [System.Text.Encoding]::ASCII.GetString($_.UserFriendlyName)
    }
  }, 
  @{
    name       = 'SerialNumber'
    expression = {
      [System.Text.Encoding]::ASCII.GetString($_.SerialNumberID)
    }
  },
    @{
    name       = 'ProductCodeID'
        expression = {
          [System.Text.Encoding]::ASCII.GetString($_.ProductCodeID)
        }
  },
    @{
    name       = 'ManufacturerName'
        expression = {
          [System.Text.Encoding]::ASCII.GetString($_.ManufacturerName)
        }
  },
  @{
    name       = 'ComputerName'
        expression = {$_.PSComputerName}
  }
), 
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    BEGIN{}
    PROCESS{
        ForEach ($Computer in $ComputerName) {
            Get-WmiObject -ComputerName $Computer -Namespace 'root/WMI' -Class WMIMonitorID | 
            Where-Object -Property UserFriendlyName | 
            Select-Object -Property $Properties
        }
    }
    END{}
}