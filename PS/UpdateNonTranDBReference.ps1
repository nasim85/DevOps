param([string]$RootPath="C:\Users\300915\Desktop\RevenueCycle\R2015.4\Care\DB_Projects\ACH_DB_NonTran",[string]$DropLocation="C:\Users\300915\Desktop\RevenueCycle\R2015.4\Care\DB_Projects",[string] $DbList="PathforThetranDBProject")

$DatabaseList="DNN30|DNNStage|ClaimStatus|CrossSiteYBFU|Reference|Global_AhtoDialer|DataArchive|ELIGIBILITY|Accretive|gAccretive|AccretiveLogs|CrossSiteSupport|Global_FCC_PreRegistration|TranGLOBAL"
$LogPath = $DropLocation+"\Logs\"
$LogFilePath =$LogPath +"EventLog_Summary.txt"

$List = Get-ChildItem $RootPath"\Bin" | Where-Object {$_.Extension -eq ".dacpac" -and $_.Name -match $DatabaseList} 


 # Function for loging events and exceptions ####################################
 Function LogFileGen([string] $SummaryTxt )
 {  
        Write-Host $SummaryTxt
        $SummaryTxt +" Time : "+$((Get-Date).ToString('yyyy,MM,dd hh:mm:ss')) |Out-File -FilePath $LogFilePath -Append 
  }



Try{
 LogFileGen -SummaryTxt "List count ="$List.Count


Add-PSSnapin Microsoft.TeamFoundation.PowerShell
#$BuildName= ${$Env:TF_BUILD_BUILDDEFINITIONNAME}
#$StrList= $BuildName.split('_')
#$BranchPath="$/RevenueCycle"

#for($i=1; $i -le $StrList.Count ; $i++)
#{$BranchPath=$BranchPath+"/"+ $StrList[$i]}

#$TFSSSDPPath = "$/RevenueCycle/DBAutomation/SSDP/ACH_DB_Tran/Tran/ReferenceDacpack/"
$TFSSSDPPath = $DbList
$TFSWKPath = "D:\ReferenceDacpack"
$tfsServerString="http://tfs.ahtoit.net:8080/tfs/revenuecyclecoll"
$tfs = Get-TfsServer $tfsServerString  

#tf workspace /new /s:$tfs "SSDT" /noprompt 
CD $TFSWKPath
 LogFileGen -SummaryTxt "Deleting Workspace ReferenceDacpack"
Try{
    tf workspace /delete "ReferenceDacpack" /noprompt /s:$tfs 
}
Catch
{
   LogFileGen -SummaryTxt $_.Exception.ToString()
}

LogFileGen -SummaryTxt "Creating Workspace ReferenceDacpack"
tf workspace /new /s:$tfs "ReferenceDacpack" /noprompt 
LogFileGen -SummaryTxt "Map Workspace ReferenceDacpack"            
tf workfold /s:$tfs /workspace:"ReferenceDacpack"  /map  $TFSSSDPPath $TFSWKPath
CD $TFSWKPath
LogFileGen -SummaryTxt "Get updated Workspace ReferenceDacpack"
tf get /force /recursive
LogFileGen -SummaryTxt "Checkout Workspace ReferenceDacpack"
TF checkout DNN30.dacpac DNNStage.dacpac ClaimStatus.dacpac CrossSiteYBFU.dacpac Reference.dacpac Global_AhtoDialer.dacpac DataArchive.dacpac ELIGIBILITY.dacpac Accretive.dacpac gAccretive.dacpac AccretiveLogs.dacpac CrossSiteSupport.dacpac Global_FCC_PreRegistration.dacpac TranGLOBAL.dacpac


LogFileGen -SummaryTxt "Copy updated dacpac"
ForEach($li in $List)
{
    $name=$li.Name
    $Source=$RootPath+"\Bin\"+$name
    $Destination=$TFSWKPath+"\"+$name

    LogFileGen -SummaryTxt "Copy $name "
    Copy-Item $Source $Destination  -Force
    LogFileGen -SummaryTxt "Copy Completed $name "
}



LogFileGen -SummaryTxt "Checkin pending changes "$li
TF checkin /override:"Update Non-Tran Database reference by automation" /comment:"Update Non-Tran Database reference by automation"  /noprompt 


 LogFileGen -SummaryTxt "Deleting Workspace ReferenceDacpack"
Try{
    tf workspace /delete "ReferenceDacpack" /noprompt /s:$tfs 
}
Catch
{
   LogFileGen -SummaryTxt $_.Exception.ToString()
}

}
Catch
{
   LogFileGen -SummaryTxt $_.Exception.ToString()
   

}
