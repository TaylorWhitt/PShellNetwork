Function Set-ComputerState {
<#
    .Synopsis
		Will log off, shutdown, reboot a local or remote computer.
	.Description
		Will log off, shutdown, reboot a local or remote computer.
		"-Force" may return unexpected results, but will not require user interaction to close programs. They will lose unsaved work.
		Credentials can be provided with a global $PSCredential variable (must be defined) or, 
		With the -Credential switch parameter, it will prompt you for input.  
		Otherwise, it will use the current session's credentials.
	.Example
	 Set-ComputerState computer.domain -LogOff
        Will prompt logged-in users to log off on computer(s) listed, using current session credentials.
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
	    if ($Force)     	{$State += 4}
            
      if ($Credential -and $PSCredential -ne $Null) {
        write-Host 'Using $PSCredential'
        (Get-WmiObject win32_operatingsystem -ComputerName $Computer -ErrorAction SilentlyContinue -Credential $PSCredential).win32shutdown($State)
        Trap [System.UnauthorizedAccessException] { 
          Write-Host "$Computer was provided with incorrect or insufficient credentials."
          continue
        } #Trap

      } elseif ($Global:PSCredential -ne $Null) {
        write-Host 'Using $Global:PSCredential'
        (Get-WmiObject win32_operatingsystem -ComputerName $Computer -ErrorAction SilentlyContinue -Credential $Global:PSCredential).win32shutdown($State)
        Trap [System.UnauthorizedAccessException] { 
          Write-Host "$Computer was supplied with incorrect or insufficient Global: credentials."
          continue
        } #Trap
      
      } Else {
        Try {
    	    (Get-WmiObject win32_operatingsystem -ComputerName $Computer -ErrorAction SilentlyContinue).win32shutdown($State)
        } Catch [System.UnauthorizedAccessException] { 
            Write-Host "$Computer was supplied with insufficient session credentials."
        } #Try/Catch
      } #If/ElseIf/Else

    } # ForEach

} #PROCESS

	END {}

} #Function
