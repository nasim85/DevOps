##Created by: Nasimuddin
##Created on: 03/21/2016
##To start stop woindows service##
[CmdletBinding()]
param (
    [parameter(Mandatory=$true)]
    [string]$ServerList,
    [parameter(Mandatory=$true)]
    [string]$ServiceName,
	[parameter(Mandatory=$true)]
    [ValidateSet("Start", "Stop", "Recycle")]
	[String]$Action
)


function fstart-Service([string] $Server)
{

    Try{

        Write-Host "Starting service $ServiceName on $Server"
    Start-Service -InputObject $(Get-Service -ComputerName $Server -Name $ServiceName) -verbose
        Write-Host "Service $ServiceName started on $Server"
    }
    Catch
    {
        Write-Host $_.Exception

    }

}

function fstop-Service([string] $Server,[string] $Service)
{

    Try{
        Write-Host "Stoping service $ServiceName on $Server"
    Stop-Service -InputObject $(Get-Service -ComputerName $Server -Name $ServiceName) -verbose
        Write-Host "Service $ServiceName stoped on $Server"
    }
    Catch
    {
        Write-Host $_.Exception
    }


}



ForEach ($Server in ($ServerList -split ",")) {
	        If ($Action -eq "Stop") 
                {
		            fstop-Service $Server
	            }
            Elseif($Action -eq "Start")
                {
  		            fstart-Service $Server
                }
            Elseif($Action -eq "Recycle")
                {
                    fstop-Service $Server
                    fstart-Service $Server
                }
            Else{ Write-Host "`r`nInvalid action provided." }
}


read-host "Service refresh complete, press enter to close this window. for more details review above logs"
