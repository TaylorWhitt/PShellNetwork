Function Set-ComputerState {
<#
    .Synopsis
		Will log off, shutdown, reboot a local or remote computer.
	.Description
		Will log off, shutdown, reboot a local or remote computer.
		"-Force" may return unexpected results, but will not require user interaction to close programs.
		Credentials can be provided with a global $PSCredential variable, or can be prompted for with the -Credential switch parameter.  
		Otherwise, it will use the current session's credentials.
	.Example
	 Set-ComputerState computer.domain -LogOff
        Will gracefully log off users on computer listed.
#>
	[CmdletBinding()]
    	Param(
		[Parameter(
        	Mandatory = $True,
	        ValueFromPipeline = $True,
        	ValueFromPipelineByPropertyName = $True,
          Position = 1)]
		[string[]]$ComputerName,
		[switch]$Force,
		[switch]$Credential,

		[Parameter(ParameterSetName='LogOff')]
		[switch]$LogOff,

		[Parameter(ParameterSetName='ShutDown')]
		[switch]$ShutDown,

		[Parameter(ParameterSetName='Reboot')]
		[switch]$Reboot,

		[Parameter(ParameterSetName='PowerOff')]
		[switch]$PowerOff
    	) #Params

	BEGIN {}

	PROCESS {
        
    If ($Credential -eq $True) { 
      $PSCredential = (Get-Credential) 
    } #If
		ForEach ($Computer in $ComputerName) {
	    if ($LogOff) 	{$State = 0}
	    if ($ShutDown) 	{$State = 1}
	    if ($Reboot)	{$State = 2}
	    if ($PowerOff)	{$State = 8}
	    if ($Force)     {$State += 4}
            
      if ($Credential -and $PSCredential -ne $Null) {
        write-Host 'Using $PSCredential'
        (Get-WmiObject win32_operatingsystem -ComputerName $Computer -ErrorAction SilentlyContinue -Credential $PSCredential)
        Trap [System.UnauthorizedAccessException] { 
          Write-Host "$Computer was provided with incorrect or insufficient credentials."
          continue
        } #Trap

      } elseif ($Global:PSCredential -ne $Null) {
        write-Host 'Using $Global:PSCredential'
        (Get-WmiObject win32_operatingsystem -ComputerName $Computer -ErrorAction SilentlyContinue -Credential $Global:PSCredential)
        Trap [System.UnauthorizedAccessException] { 
          Write-Host "$Computer was supplied with incorrect or insufficient Global: credentials."
          continue
        } #Trap
      
      } Else {
        Try {
    	    (Get-WmiObject win32_operatingsystem -ComputerName $Computer -ErrorAction SilentlyContinue)
        } Catch [System.UnauthorizedAccessException] { 
            Write-Host "$Computer was supplied with insufficient session credentials."
        } #Try/Catch
      } #If/ElseIf/Else

    } # ForEach

	} #PROCESS

	END {}

} #Function
