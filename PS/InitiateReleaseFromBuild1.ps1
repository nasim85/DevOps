<#
param(
    [string]$rmServer,
    [string]$rmUser,
    [string]$rmPassword,
    [string]$rmDomain,
    [string]$releaseDefinition,
    [string]$deploymentPropertyBag
    )
#>



    [string]$rmServer="ahvtfsdv01rmt01.accretivehealth.local:1000"
    [string]$rmUser="India\300915"
    [string]$rmPassword="Login@M03"
    [string]$rmDomain="accretivehealth.local"
    [string]$releaseDefinition="vNext-DB-Tran-CI"
    [string]$deploymentPropertyBag= '{ "vNextDBTran:Build" : "DB-RM-Tran-R2016.3_20160411.1", "ReleaseName" : "$releaseName"}'


#$deploymentPropertyBag = '{ "vNextDBTran:Build" : "DB-RM-Tran-R2016.2_20160218.1", "ReleaseName" : "$releaseName"}'

$propertyBag = [System.Uri]::EscapeDataString($deploymentPropertyBag)
$exitCode = 0

trap
{
  $e = $error[0].Exception
  $e.Message
  $e.StackTrace
  if ($exitCode -eq 0) { $exitCode = 1 }
}

$scriptName = $MyInvocation.MyCommand.Name
$scriptPath = Split-Path -Parent (Get-Variable MyInvocation -Scope Script).Value.MyCommand.Path

Push-Location $scriptPath  

$orchestratorService = "http://$rmServer/account/releaseManagementService/_apis/releaseManagement/OrchestratorService"

$status = @{
    "2" = "InProgress";
    "3" = "Released";
    "4" = "Stopped";
    "5" = "Rejected";
    "6" = "Abandoned";
}

#For Update3 use api-version=2.0 for Update4 use api-version=3.0.
$uri = "$orchestratorService/InitiateRelease?releaseTemplateName=" + $releaseDefinition + "&deploymentPropertyBag=" + $propertyBag + "&api-version=2.0"

$wc = New-Object System.Net.WebClient
#$wc.UseDefaultCredentials = $true
# rmuser should be part rm users list and he should have permission to trigger the release.
$wc.Credentials = new-object System.Net.NetworkCredential("$rmUser", "$rmPassword", "$rmDomain")

try
{
    $releaseId = $wc.UploadString($uri,"")
    $url = "$orchestratorService/ReleaseStatus?releaseId=$releaseId"
    $releaseStatus = $wc.DownloadString($url)

    Write-Host -NoNewline "`nReleasing ..."

    while($status[$releaseStatus] -eq "InProgress")
    {
        Start-Sleep -s 5
        $releaseStatus = $wc.DownloadString($url)
        Write-Host -NoNewline "."
    }

    " done.`n`nRelease completed with {0} status." -f $status[$releaseStatus]
}
catch [System.Exception]
{
    if ($exitCode -eq 0) { $exitCode = 1 }
    Write-Host "`n$_`n" -ForegroundColor Red
}

if ($exitCode -eq 0)
{
  "`nThe script completed successfully.`n"
}
else
{
  $err = "Exiting with error: " + $exitCode + "`n"
  Write-Host $err -ForegroundColor Red
}

Pop-Location

exit $exitCode