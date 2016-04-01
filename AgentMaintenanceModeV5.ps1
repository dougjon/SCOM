param($rootMS,$computerPrincipalName,$minutes,$comment,$reason)
$startMM=$true

$OMCmdletsTest = (Get-Module|%{$_.Name}) -Join " "
If(!$OMCmdletsTest.Contains("OperationsManager")){Import-Module OperationsManager -ErrorVariable err -Force}
 
Write-Host "Connecting to MS: $rootMS..."
New-SCOMManagementGroupConnection $rootMS

$computer = $null
$class=get-scomclass -Name Microsoft.Windows.Computer
$computer = get-scomclassinstance -Class $class | where {$_.DisplayName -like "$computerPrincipalName*"} | select-object -first 1

if ($computer -eq $null -or $computer -eq '')
 {
	$class=get-scomclass -Name Microsoft.Linux.Computer
	$computer = get-scomclassinstance -Class $class | where {$_.DisplayName -like "$computerPrincipalName*"} | select-object -first 1
	if ($computer -ne $null -and $computer -ne '')
	{
	}
	else
	{
		$class=get-scomclass -Name Microsoft.Unix.Computer
		$computer = get-scomclassinstance -Class $class | where {$_.DisplayName -like "$computerPrincipalName*"} | select-object -first 1	
	}
}

if ($computer -eq $null -or $computer -eq '') {
	Write-Host "Could not find computer: $computerPrincipalName"
	exit 1
}


$endTime = ([System.DateTime]::Now).AddMinutes($minutes)
 
if($computer.InMaintenanceMode -eq $false -and $startMM -eq $true)
{
 	if($class.Name -eq "Microsoft.Windows.Computer")
	   {
	"Putting " + $computerPrincipalName + " into maintenance mode"
       Start-SCOMMaintenanceMode -EndTime $endTime -Comment $comment -Reason $reason -Instance $computer
		} 
	Elseif($class.Name -eq "Microsoft.Linux.Computer")
		{
				"Putting " + $computerPrincipalName + " into maintenance mode"
        Start-SCOMMaintenanceMode -EndTime $endTime -Comment $comment -Reason $reason -Instance $computer
		Start-Sleep -s 5
	    Get-SCOMTask -DisplayName "Reset Linux Log File Scanning"  | Start-SCOMTask -Instance $computer
		} 
	Else
		{
		"Putting " + $computerPrincipalName + " into maintenance mode"
       Start-SCOMMaintenanceMode -EndTime $endTime -Comment $comment -Reason $reason -Instance $computer
	   Start-Sleep -s 5
		Get-SCOMTask -DisplayName "Reset AIX Log File Scanning (Action Account)"  | Start-SCOMTask -Instance $computer
		}
}
elseif($startMM -eq $false)
{
       "Removing " + $computerPrincipalName + " and related objects from maintenance mode"
       foreach($Instance in ($computer,$computer.GetRelatedMonitoringObjects()))
       {
       
              $mm = Get-SCOMMaintenanceMode -Instance $Instance
              $NewEndTime = ([System.DateTime]::Now)
              if($Instance.InMaintenanceMode -eq $true)
              {
                     $Instance.DisplayName
                     Set-SCOMMaintenanceMode -MaintenanceModeEntry $mm -EndTime $NewEndTime -Comment "Ending MM"
              }
 
       }
 }
else {
	"Computer already in maintenance mode."
	exit 1
}
exit 0