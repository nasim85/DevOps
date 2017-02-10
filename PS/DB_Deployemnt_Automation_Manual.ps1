get-pssnapin -registered

Set-Location -Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE"
Get-Location

Add-PSSnapin Microsoft.TeamFoundation.PowerShell
$TFSSSDPPath = "$/RevenueCycle/DBAutomation/SSDP"
$TFSWKPath = "C:\SSDP"
$tfsServerString="http://tfs.ahtoit.net:8080/tfs/revenuecyclecoll"
$tfs = Get-TfsServer $tfsServerString  

tf workspace /new /s:$tfs "SSDT" /noprompt 
CD $TFSWKPath
tf workspace /delete "SSDT" /noprompt /s:$tfs 
tf workspace /new /s:$tfs "SSDT" /noprompt 
            
tf workfold /s:$tfs /workspace:"SSDT"  /map  $TFSSSDPPath $TFSWKPath
CD "C:\SSDP\ACH_DB_Tran"
tf get /force /recursive



#param([string]$RootPath="D:\SSDP\ACH_DB_All",[string]$DropLocation="D:\SSDP",[string]$BuildName=(Get-Date -format 'yyyyMMdd') +"_"+(Get-Date -format 'HHmm'),[string]$ENV="UAT",[bool]$DeployChanges=$False,[string] $DbList="15")
$RootPath="D:\SSDP\ACH_DB_Tran"
$DropLocation="D:\SSDP"
$BuildName=(Get-Date -format 'yyyyMMdd') +"_"+(Get-Date -format 'HHmm')
$ENV="CI"
$DeployChanges=$False
$DbList="15"


	#Add-PSSnapin SqlServerCmdletSnapin100
	#Add-PSSnapin SqlServerProviderSnapin100
 #Register the DLL we need #######################################################
Add-Type -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\DAC\bin\Microsoft.SqlServer.Dac.dll" 

 ###################### Global Variables ########################################
 $EnvConfigPath =""
 $LogPath =""
 $EnvDetailList =""
 # Out put Log File ############################################################# 
 $LogPath = $DropLocation+"\Logs\"
 $LogFilePath =$LogPath + $BuildName+"_EventLog_Summary.txt"
 ###################### SQLPackage Load #########################################
 $SQLPkgPath="${env:ProgramFiles(x86)}\Microsoft SQL Server\110\DAC\bin\sqlpackage.exe"
 $TFS = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 11.0\Common7\IDE\tf.exe"

 

 # Local database veriable details for deployment.###############################
@(  $AccretiveDb =""
    $AccretiveServer=""
    $AccretiveLogsDb=""
    $AccretiveLogsServer=""
    $AuditDNNBetaDb=""
    $AuditDNNBetaServer=""
    $DataArchiveDb=""
    $DataArchiveServer=""
    $DefaultFDataPath=""
    $DNNDb=""
    $DNNServer=""
    $EligibilityDb=""
    $EligibilityServer=""
    $FileExchangeDb=""
    $FileExchangeServer=""
    $ReferenceDb=""
    $ReferenceServer="" 
	$TranDB=""
	$TranServer=""

    $CrossSiteSupportDB=""
    $CrossSiteSupportServer=""
    $CrossSiteYBFUDB=""
    $CrossSiteYBFUServer=""
    $Global_AhtoDialerDB=""
    $Global_AhtoDialerServer=""
    $Global_FCC_PreRegistrationDB=""
    $Global_FCC_PreRegistrationServer=""
    $HL7StageDB=""
    $HL7StageServer=""
    $StageDB=""
    $StageServer=""
    $TranGLOBALDB=""
    $TranGLOBALServer=""
    $ClaimStatusDb=""
    $ClaimStatusServer=""





	)
 # Function for loging events and exceptions ####################################
 Function LogFileGen([string] $SummaryTxt )
 {  
        Write-Host $SummaryTxt
        $SummaryTxt +" Time : "+$((Get-Date).ToString('yyyy,MM,dd hh:mm:ss')) |Out-File -FilePath $LogFilePath -Append 
  }
 # Validate log file path.#######################################################
    Try
    {
        If (!$(Test-Path -Path $LogPath)){New-Item -ItemType "directory" -Path $LogPath | Out-Null}
    }
    Catch
    {
        LogFileGen -SummaryTxt "Creating Log Folder : "$error
    }


# Function to Get updated projects from TFS. ===============================
Function GetLatest([string] $FolderPath )
{  
   Try
   {

        LogFileGen -SummaryTxt ("Getting Latest Project from TFS Started..")
        #&$TFS Get $FolderPath /force /recursive
        &$TFS Get $FolderPath /recursive
        LogFileGen -SummaryTxt ("Getting Latest Project from TFS Completed.")        
   }
   catch
   {
        LogFileGen -SummaryTxt ("Getting Latest Project from TFS : "+ $_.Exception)
   }
}


#### Build the solution to get the updated dacpack###################
IF($DbList -ne "0")
{
 Try
   {

   #GetLatest -FolderPath $RootPath


 #$msbuild="C:\SSDT\msbuild.cmd"
  $msbuild=[Environment]::GetFolderPath("Windows").ToString()+"\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe"
 LogFileGen -SummaryTxt "Building the project solution ..."
 $SolPath= "$RootPath\ACH_DB_Tran.sln"

 #& $msbuild /v:m /ds $SolPath|Out-Host #Out-File $ProjectPath\bin\Debug\$logFileName
  LogFileGen -SummaryTxt "Building the project solution Completed"

   }
   catch
   {
        LogFileGen -SummaryTxt ("Build Error in solution : "+ $_.Exception)
   }

}

##### Check for Full script ENV and restore the database to original state
if($ENV -eq "CIF")
{
    try{
    #$RestoreScript=".\SQL_restore.ps1"
    #.$RestoreScript
    LogFileGen -SummaryTxt ( "Full script Env DB restore Completed")
    }
  Catch
           {
                $_.Exception.ToString()|Out-File -FilePath $LogFilePath -Append 
                LogFileGen -SummaryTxt ( "Full script Env DB restore error : " +$_.Exception)
           }

}

 # Validate and read environment config details.=================================
@( 
     LogFileGen -SummaryTxt "Reading Environment Config file"
     $EnvConfigPath  = $RootPath+"\..\..\aaDeployment_Scripts\DeploymentTools\EnvironmentConfig-"+$ENV+".csv"
     if (Test-Path $EnvConfigPath ) 
     {
        $EnvDetailList= Import-Csv $EnvConfigPath  | Where-Object {$_.env -eq $Env}
     }
     Else 
     {
         LogFileGen -SummaryTxt "Environment Config file Missing."
     }
 )

 # Create a data table for holding change script details.========================
@( $dtScriptList = New-Object System.Data.DataTable            

 $dtScriptList.Columns.Add("FileName")| Out-Null
 $dtScriptList.Columns.Add("DBClass") | Out-Null
 $dtScriptList.Columns.Add("Order", [int]) | Out-Null
 $dtRow = $null)

# Function for adding new change script into TFS. ===============================
Function ChekinFile([string] $FolderPath )
{  
   Try
   {
        &$TFS add $FolderPath /recursive /lock:none
        &$TFS checkin $FolderPath /comment:"Automation:Change Script generated by Build DB Automation." /noprompt
   }
   catch
   {
        LogFileGen -SummaryTxt ("Chekin File : "+ $_.Exception)
   }
}





# Generate OUT Script File Name and Location ====================================
Function GetOutScriptFileName([string] $DBClass)
{
    $FileNo =""
    $List = Get-ChildItem $RootPath"\DailyBuildScript" | Where-Object {$_.Extension -eq ".sql" -and $_.Name -match $ENV +"_*" -and $_.Name -match $DBClass }
    #$List
    if (($list.Count.ToString().length -le 1 ))
    {
       $FileNo= "0"+([int]$list.Count+1)
    }
    Elseif (($list.Count -eq 0 ))
    {
      $FileNo=  "01"
    }
    Else
    {
       $FileNo= ([int]$list.Count+1)
    }

    return $RootPath + "\DailyBuildScript\"+ $Env+"_"+$FileNo+$DBClass+"_"+$BuildName+".sql"
}
# Function for Sql Script Cleanup.  =============================================
Function UpdateChangeScript([string] $SourceFile,[string] $TargetFile, [string] $DBClass,[Int] $Order,[bool] $IncludeTran )
{  

    $FileContaints =Get-Content $SourceFile 

     for ($i=0; $i -lt $FileContaints.Count; $i++)
        {
 # Remove Drop User Scripts from Change Script =================================
 # Write-Host $FileContaints.GetValue($i).ToString()
            $SummaryTxt ="";
            $PrintTRG = "Y"
            if ($IncludeTran -eq $true)
            {
                if (($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP USER") -or 
                    ($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP ROLE")
                )
                    {
                        $i = $i+22
                        $SummaryTxt = $FileContaints.GetValue($i)
                        $PrintTRG ="N"
                    }
                    elseif ($FileContaints.GetValue($i) -eq "IF (@VarDecimalSupported > 0)")
                    {
                       $i = $i+6
                       $SummaryTxt = $FileContaints.GetValue($i)
                       $PrintTRG ="N"  
                    }
                    else
                    {
                        $SummaryTxt = $FileContaints.GetValue($i)
                    }
            }
            Else
            {
                if (($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP USER") -or
                    ($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP ROLE"))
                {
                    $i = $i+7
                    $SummaryTxt = $FileContaints.GetValue($i)
                    $PrintTRG ="N"
                }
                elseif ($FileContaints.GetValue($i) -eq "IF (@VarDecimalSupported > 0)")
                {
                   $i = $i+6
                   $SummaryTxt = $FileContaints.GetValue($i)
                   $PrintTRG ="N"  
                }
                else
                {
                    $SummaryTxt = $FileContaints.GetValue($i)
                }
            }
            if ($PrintTRG -eq "Y")
            {
               $SummaryTxt |Out-File -FilePath $TargetFile -Append 
            }
        }
  #Add Change SCript Details into script Collection.============================
  
    $dtRow = $dtScriptList.NewRow()
    $dtRow["FileName"]= $TargetFile
    $dtRow["DbClass"]= $DBClass
    $dtRow["Order"]= $Order
    $dtScriptList.Rows.Add($dtRow)
}
# Generating Change script for all Databases.===================================
Try
{
# Populate Database list. =======================================================
    @(
       # 1-DNN30 
       # 2-DNNStage 
       # 3-ClaimStatus
       # 4-CrossSiteYBFU
       # 5-Reference
       # 6-Global_AhtoDialer
       # 7-DataArchive
       # 8-ELIGIBILITY
       # 9-Accretive  
       # 10-AccretiveLogs
       # 11-CrossSiteSupport
       # 12-Global_FCC_PreRegistration
       # 13-TranGLOBAL
       # 14-FileExchange
       # 15-Tran
    $DatabaseList=@()

    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "DNN30"; ExcOrder = "1" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "DNNStage"; ExcOrder = "2"   }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "ClaimStatus"; ExcOrder = "3"}
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "CrossSiteYBFU"; ExcOrder = "4" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "Reference"; ExcOrder = "5" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "Global_AhtoDialer"; ExcOrder = "6" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "DataArchive"; ExcOrder = "7" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "ELIGIBILITY"; ExcOrder = "8" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "Accretive"; ExcOrder = "9" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "AccretiveLogs"; ExcOrder = "10" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "CrossSiteSupport"; ExcOrder = "11" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "Global_FCC_PreRegistration"; ExcOrder = "12" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "TranGLOBAL"; ExcOrder = "13" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "FileExchange"; ExcOrder = "14" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "Tran"; ExcOrder = "15" }
   )



 IF($DbList -ne "0")
 {
    $DatabaseList =$DatabaseList|Where-Object{$_.ExcOrder -in ($DbList -split ",")}
 }   

    Function GenerateChangeScript([string] $DbProjectName,[int] $ExcOrder)
    {
       Try
        {
           $ProfilePath=($RootPath+"\"+$DbProjectName +"\"+$DbProjectName+"_"+$Env+".publish.xml")
           $ProjDacpacPath = ($RootPath+"\Bin\"+$DbProjectName+".dacpac")
           $OrgOutScriptPath = ($RootPath+"\Bin\"+$DbProjectName+".sql")
           $UpdatedChangeScriptFile = GetOutScriptFileName -DBClass $DbProjectName

              if ((Test-Path $ProjDacpacPath) -and (Test-Path $ProfilePath ))
              {
                   $dacProfile = [Microsoft.SqlServer.Dac.DacProfile]::Load($ProfilePath)
                   & $SQLPkgPath /a:Script /SourceFile:$ProjDacpacPath /Profile:$ProfilePath /OutPutPath:$OrgOutScriptPath  |Out-File -FilePath $LogFilePath -Append 

                   #Get Published File Info =====================================
                   LogFileGen -SummaryTxt ($DbProjectName +" : Updating sql script file.")
                   if (Test-Path $OrgOutScriptPath ) 
                   {
                        UpdateChangeScript -SourceFile $OrgOutScriptPath -TargetFile $UpdatedChangeScriptFile -DBClass $DbProjectName -Order $ExcOrder -IncludeTran $dacProfile.DeployOptions.IncludeTransactionalScripts
                   }
                   Else
                   {
                        LogFileGen -SummaryTxt ($DbProjectName +" :Script file not generated.")
                   }
      
              }
              Else
              {
                LogFileGen -SummaryTxt ($DbProjectName+" :.dacpac or .publish file not found.")
              } 
         }
         Catch
         {
             LogFileGen -SummaryTxt ("Error in Project "+$DProjectName+ " Function GenerateChangeScript. ErrorLog :"+$_.Exception)
         }
    }
# Iterate All Database and generate change script. ============================== 
    foreach ($Database in $DatabaseList)
    {
       LogFileGen -SummaryTxt ($Database.DatabaseName + " : Start Change Script Generation.")
       GenerateChangeScript -DbProjectName $Database.DatabaseName -ExcOrder $Database.ExcOrder
       LogFileGen -SummaryTxt ($Database.DatabaseName +" : END Change Script Generation.")
    }
# Publish the change to target database. ========================================
    if ($DeployChanges -eq $true)
    {
        Try
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        {
      # Function for asigining value to all deployment veriables.================
        @(            
           LogFileGen -SummaryTxt "Asigining Deployment Veriable Values."

            if ($EnvDetailList.Count -gt 0)
            {
                if ($ENV -eq "CI")
                   {
                        $DefaultFDataPath ="E:\MSSQL\FTData\"
                   }
                else
                   {
                        $DefaultFDataPath ="E:\MSSQL\FTData\"
                   }
                #Accretive
                  
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'Accretive' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $AccretiveDb = $EnvValue.DbName
                $AccretiveServer = $EnvValue.ServerName
                
                #AccretiveLogs
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'AccretiveLogs' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $AccretiveLogsDb = $EnvValue.DbName
                $AccretiveLogsServer = $EnvValue.ServerName

                #Audit11.DNNBeta
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'Audit11.DNNBeta' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $AuditDNNBetaDb = $EnvValue.DbName
                $AuditDNNBetaServer = $EnvValue.ServerName


                #DataArchive
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'DataArchive' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $DataArchiveDb = $EnvValue.DbName
                $DataArchiveServer = $EnvValue.ServerName

                #DNN
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'DNN30' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $DNNDb = $EnvValue.DbName
                $DNNServer = $EnvValue.ServerName

                #Eligibility
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'Eligibility' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $EligibilityDb = $EnvValue.DbName
                $EligibilityServer = $EnvValue.ServerName

                #FileExchange
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'FileExchange' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $FileExchangeDb = $EnvValue.DbName
                $FileExchangeServer = $EnvValue.ServerName

                #Reference
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'Reference' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $ReferenceDb = $EnvValue.DbName
                $ReferenceServer = $EnvValue.ServerName
				
				 #Tran
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'TRAN' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $TranDB = $EnvValue.DbName
                $TranServer = $EnvValue.ServerName


                #CrossSiteSupport
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'CrossSiteSupport' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $CrossSiteSupportDB = $EnvValue.DbName
                $CrossSiteSupportServer = $EnvValue.ServerName


                #CrossSiteYBFU
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'CrossSiteYBFU' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $CrossSiteYBFUDB = $EnvValue.DbName
                $CrossSiteYBFUServer = $EnvValue.ServerName


                #Global_AhtoDialerDB
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'Global_AhtoDialer' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $Global_AhtoDialerDB = $EnvValue.DbName
                $Global_AhtoDialerServer = $EnvValue.ServerName


                #Global_FCC_PreRegistrationDB
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'Global_FCC_PreRegistration' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $Global_FCC_PreRegistrationDB = $EnvValue.DbName
                $Global_FCC_PreRegistrationServer = $EnvValue.ServerName

                #HL7StageDB
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'HL7Stage' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $HL7StageDB = $EnvValue.DbName
                $HL7StageServer = $EnvValue.ServerName

                #StageDB
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'Stage' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $StageServer = $EnvValue.DbName
                $CrossSiteYBFUServer = $EnvValue.ServerName

                #TranGLOBALDB
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'TranGLOBAL' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $TranGLOBALDB = $EnvValue.DbName
                $TranGLOBALServer = $EnvValue.ServerName


                #ClaimStatus
                $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq 'ClaimStatus' -and $_.Replication -in ('Pub','None')}|Select-Object -First 1
                $ClaimStatusDb = $EnvValue.DbName
                $ClaimStatusServer = $EnvValue.ServerName
                

            }
 )
      # Function for execute sql scripts. =======================================
       Function Execute-Sql{
           param($ServerName, $DbName, $ScriptFile,$DeployVarArray)

           $LogFilePath =$LogPath + $BuildName+"_"+$ServerName+"_"+$DbName+"_Log.txt"
           try
           {
           [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null 
            $sqlSrv = New-Object 'Microsoft.SqlServer.Management.Smo.Server' ($server)
                Invoke-Sqlcmd -ServerInstance "$ServerName" -ErrorAction 'Continue' -Database "$DbName" -InputFile "$ScriptFile" -Variable $DeployVarArray -OutputSqlErrors:$true -Verbose *>&1  |Out-File -FilePath $LogFilePath
                LogFileGen -SummaryTxt ( "Deployment Completed : " +$DbName)

           }
           Catch
           {
                $_.Exception.ToString()|Out-File -FilePath $LogFilePath -Append 
                LogFileGen -SummaryTxt ( "Execute SQL Error : " +$_.Exception)
           }
        }
       # Print Change script colletion data.=====================================
       $dtScriptList |Sort-Object Order |Format-Table -AutoSize
       if ($dtScriptList.Rows.Count -gt 0)
       {
       # Iterate throw change script list. ====================================== 
           foreach($Row in $dtScriptList.Rows)
           {
               # Iterate throw environment config records. ====================== 
               $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq $Row["DbClass"].ToString() -and $_.Replication -in ('Pub','None')}
               foreach($EnvRow in $EnvValue)
               {
                   LogFileGen -SummaryTxt ("Deploying Script on :" + $EnvRow.SERVERNAME.Trim()+"_"+$EnvRow.DBNAME)
                   # 1-DNN30 ====================================================
                   if ($Row["DbClass"].ToString() -eq "DNN30")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+"")
                   }
                   # 2-DNNStage ================================================= 
                   Elseif ($Row["DbClass"].ToString() -eq "DNNStage")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+"")
                   }
                   # 3-ClaimStatus ==============================================
                   Elseif ($Row["DbClass"].ToString() -eq "ClaimStatus")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+"")
                   }
                   # 4-CrossSiteYBFU ============================================
                   Elseif ($Row["DbClass"].ToString() -eq "CrossSiteYBFU")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+"")
                   }
                   # 5-Reference ================================================
                   Elseif ($Row["DbClass"].ToString() -eq "Reference")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("DefaultFDataPath="+$DefaultFDataPath+"")
                   }
                   # 6-Global_AhtoDialer ========================================
                   Elseif ($Row["DbClass"].ToString() -eq "Global_AhtoDialer")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+"")
                   }
                   # 7-DataArchive ==============================================
                   Elseif ($Row["DbClass"].ToString() -eq "DataArchive")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+""),("AccretiveServer="+$AccretiveServer+""),`
                                    ("EligibilityDb="+$EligibilityDb+""),("EligibilityServer="+$EligibilityServer+"")
                   }
                   # 8-ELIGIBILITY ==============================================
                   Elseif ($Row["DbClass"].ToString() -eq "ELIGIBILITY")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+""),("DataArchiveDb="+$DataArchiveDb+""),("DataArchiveServer="+ $DataArchiveServer+"")
                   }
                   # 9-Accretive ================================================
                   elseif ($Row["DbClass"].ToString() -eq "Accretive")
                   { 
                       $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("DefaultFDataPath='"+$DefaultFDataPath+"'"),`
                                   ("AccretiveLogsDb="+ $AccretiveLogsDb+""),("AccretiveLogsServer="+$AccretiveLogsServer+""),`
                                   ("AuditDNNBetaDb="+$AuditDNNBetaDb+""),("AuditDNNBetaServer="+$AuditDNNBetaServer+""),`
                                   ("DataArchiveDb="+$DataArchiveDb+""),("DataArchiveServer="+$DataArchiveServer+""),`
                                   ("DNNDb="+$DNNDb+""),("EligibilityDb="+$EligibilityDb+""),("EligibilityServer="+$EligibilityServer+""),`
                                   ("FileExchangeDb="+$FileExchangeDb+""),("FileExchangeServer="+$FileExchangeServer+""),("ReferenceDb="+$ReferenceDb+"")
                   }
                    # 10-AccretiveLogs ==========================================
                   Elseif ($Row["DbClass"].ToString() -eq "AccretiveLogs") 
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+""),("DNNDb="+$DNNDb+""),`
                                    ("EligibilityDb="+$EligibilityDb+""),("EligibilityServer="+$EligibilityServer+"")
                   }
                    # 11-CrossSiteSupport =======================================
                   Elseif ($Row["DbClass"].ToString() -eq "CrossSiteSupport")
                   {
                         $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+""),("AccretiveServer="+$AccretiveServer+"")
                   }
                    # 12-Global_FCC_PreRegistration =============================
                   Elseif ($Row["DbClass"].ToString() -eq "Global_FCC_PreRegistration")
                   {
                        #$MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+"")
                         $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("DefaultFDataPath='"+$DefaultFDataPath+"'"),`
                             ("AccretiveDb="+$AccretiveDb+""),("AccretiveServer="+$AccretiveServer+""),`
                             ("AccretiveLogsDb="+ $AccretiveLogsDb+""),("AccretiveLogsServer="+$AccretiveLogsServer+""),`
                             ("AuditDNNBetaDb="+$AuditDNNBetaDb+""),("AuditDNNBetaServer="+$AuditDNNBetaServer+""),`
                             ("DataArchiveDb="+$DataArchiveDb+""),("DataArchiveServer="+$DataArchiveServer+""),`
                             ("DNNDb="+$DNNDb+""),("EligibilityDb="+$EligibilityDb+""),("EligibilityServer="+$EligibilityServer+""),`
                             ("FileExchangeDb="+$FileExchangeDb+""),("FileExchangeServer="+$FileExchangeServer+""),("ReferenceDb="+$ReferenceDb+"")
                
                   }
                    # 13-TranGLOBAL =============================================
                   Elseif ($Row["DbClass"].ToString() -eq "TranGLOBAL")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+"")
                   }
                    # 14-FileExchange ===========================================
                   Elseif ($Row["DbClass"].ToString() -eq "FileExchange")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+""),`
                                        ("AccretiveLogsDb="+$AccretiveLogsDb+""),("AccretiveLogsServer="+$AccretiveLogsServer+""),`
                                        ("DNNDb="+$DNNDb+""),("DNNServer="+$DNNServer+""),`
                                        ("ReferenceDb="+$ReferenceDb+""),("ReferenceServer="+$ReferenceServer+"")
                   }
                   # 15-Tran ====================================================
                   Elseif ($Row["DbClass"].ToString() -eq "Tran")
                   {
                     $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("DefaultFDataPath='"+$DefaultFDataPath+"'"),`
                             ("AccretiveDb="+$AccretiveDb+""),("AccretiveServer="+$AccretiveServer+""),`
                             ("AccretiveLogsDb="+ $AccretiveLogsDb+""),("AccretiveLogsServer="+$AccretiveLogsServer+""),`
                             ("AuditDNNBetaDb="+$AuditDNNBetaDb+""),("AuditDNNBetaServer="+$AuditDNNBetaServer+""),`
                             ("DataArchiveDb="+$DataArchiveDb+""),("DataArchiveServer="+$DataArchiveServer+""),`
                             ("DNNDb="+$DNNDb+""),("EligibilityDb="+$EligibilityDb+""),("EligibilityServer="+$EligibilityServer+""),`
                             ("FileExchangeDb="+$FileExchangeDb+""),("FileExchangeServer="+$FileExchangeServer+""),("ReferenceDb="+$ReferenceDb+""),
                             ("CrossSiteSupportDB="+$CrossSiteSupportDB+""),("CrossSiteSupportServer="+$CrossSiteSupportServer+"")
                             ("CrossSiteYBFUDB="+$CrossSiteYBFUDB+""),("CrossSiteYBFUServer="+$CrossSiteYBFUServer+"")
                             ("Global_AhtoDialerDB="+$Global_AhtoDialerDB+""),("Global_AhtoDialerServer="+$Global_AhtoDialerServer+"")
                             ("Global_FCC_PreRegistrationDB="+$Global_FCC_PreRegistrationDB+""),("Global_FCC_PreRegistrationServer="+$Global_FCC_PreRegistrationServer+"")
                             ("HL7StageDB="+$HL7StageDB+""),("HL7StageServer="+$HL7StageServer+"")
                             ("StageDB="+$StageDB+""),("StageServer="+$StageServer+"")
                             ("TranGLOBALDB="+$TranGLOBALDB+""),("TranGLOBALServer="+$TranGLOBALServer+"")
                             ("ClaimStatusDb="+$ClaimStatusDb+""),("ClaimStatusServer="+$ClaimStatusServer+"")
                             


                   }
                   execute-Sql  -ServerName $EnvRow.SERVERNAME.Trim() -DbName $EnvRow.DBNAME.Trim() -ScriptFile $Row["FileName"].ToString() -DeployVarArray $MyArrayAcc
               }
           }
       }
    }
        catch
                {
      LogFileGen -SummaryTxt $_.Exception  
    }
    }
    else
    {
         LogFileGen -SummaryTxt "DeployChanges parameter is set to False."  
    }
}
Catch
{
   LogFileGen -SummaryTxt $_.Exception.ToString()
}


