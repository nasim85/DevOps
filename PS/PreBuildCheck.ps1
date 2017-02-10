Param(
#  [string]$DropLocation = $env:TF_BUILD_SOURCESDIRECTORY,
  [string]$DropLocation ="C:\RevenueCycle\R2016.5\Care",
  [string]$searchFilter = "*.pdb",
  [string]$action = "StopBuild|ShowWarning"
)

#    Write-Host "Location:" $DropLocation
#    Write-Host "Arguments:" $searchFilter
#    Write-Host "action:" $action


 # Out put Log File ############################################################# 
 $LogPath = $DropLocation+"\Logs\"
 $LogFilePath =$LogPath+"PowerShell_EventLog_Summary.txt"

  # Function for loging events and exceptions #####
 Function LogFileGen([string] $SummaryTxt )
 {  
        Write-Host $SummaryTxt
        $SummaryTxt +" Time : "+$((Get-Date).ToString('yyyy,MM,dd hh:mm:ss')) |Out-File -FilePath $LogFilePath -Append 
  }
 # Validate log file path.###
    Try
    {
        If (!$(Test-Path -Path $LogPath)){New-Item -ItemType "directory" -Path $LogPath | Out-Null}
    }
    Catch
    {
        LogFileGen -SummaryTxt "Creating Log Folder : "$error
    }

###################### Log End ###################################################



$errorMsg=""

LogFileGen -SummaryTxt "Start searching files...."
gci $DropLocation -Recurse -Filter $searchFilter | select Name 

gci $DropLocation -Recurse -Filter $searchFilter | %{
    $errorMsg=$errorMsg+$_.FullName
}

LogFileGen -SummaryTxt "Searching files completed"

if($errorMsg -eq "")
{

    LogFileGen -SummaryTxt "Pre Build Check completed, No $searchFilter files found."
    Write-Host "Pre Build Check completed, No $searchFilter files found."
    exit 0
}
else
{
    if($action -eq "ShowWarning"){
        LogFileGen -SummaryTxt "Pre Build Check Failed, But build will be succesded as action parameter is to ShowWarning mode. $searchFilter files found in the source control."
        LogFileGen -SummaryTxt $errorMsg    
        Write-Host "Pre Build Check Failed, $searchFilter files found in the source control."
        Write-Host $errorMsg
        exit 0
    }
    else
    {
        LogFileGen -SummaryTxt "Pre Build Check Failed, $searchFilter files found in the source control."
        LogFileGen -SummaryTxt $errorMsg   
        Write-Error "Pre Build Check Failed, $searchFilter files found in the source control."
        Write-Error $errorMsg
        exit 1
    }
}

#Get-Help gci -Examples
<#
 
if ($buildNumber -match $pattern -ne $true) 
{
    Write-Error "Could not extract a version from [$buildNumber] using pattern [$pattern]"
    exit 1
} 
else 
{
    try {
        $extractedBuildNumber = $Matches[0]
        Write-Host "Using version $extractedBuildNumber"
 
        gci -Path $DropLocation -Filter $searchFilter -Recurse | %{
            Write-Host "  -> Changing $($_.FullName)"
         
            # remove the read-only bit on the file
            sp $_.FullName IsReadOnly $false
 
            # run the regex replace
            (gc $_.FullName) | % { $_ -replace $pattern, $extractedBuildNumber } | sc $_.FullName
        }
 
        Write-Host "Done!"
        exit 0
    } catch {
        Write-Error $_
        exit 1
    }
}
#>