param([string]$RootPath="C:\RevenueCycle\R2014.4\Care\Database\SSDP\ACH_DB_All",[string]$DropLocation="C:\RevenueCycle\R2014.4\Care\Database\SSDP",[string]$BuildName=(Get-Date -format 'yyyyMMdd') +"_"+(Get-Date -format 'HHmm'),[string]$ENV="CI",[String]$ScriptFileName="CI_01Accretive_20140604_2359.sql")

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
    $ReferenceServer="" )
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


Try
{


    Try
        {
           $ProfilePath=($RootPath+"\"+$DbProjectName +"\"+$DbProjectName+"_"+$Env+".publish.xml")
           $ProjDacpacPath = ($RootPath+"\Bin\"+$DbProjectName+".dacpac")
           $OrgOutScriptPath = ($RootPath+"\Bin\"+$DbProjectName+".sql")
           $UpdatedChangeScriptFile = $ScriptFileName


              if (Test-Path $ProfilePath )
              {
                   $dacProfile = [Microsoft.SqlServer.Dac.DacProfile]::Load($ProfilePath)
      
              }
              Else
              {
                LogFileGen -SummaryTxt ($DbProjectName+" :publish file not found.")
              } 


         }
         Catch
         {
             LogFileGen -SummaryTxt ("Error in Project "+$DProjectName+ " Function GenerateChangeScript. ErrorLog :"+$_.Exception)
         }

# Publish the change to target database. ========================================

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

                #DNN
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
            }
 )
      # Function for execute sql scripts. =======================================
       Function Execute-Sql{
           param($ServerName, $DbName, $ScriptFile,$DeployVarArray)

           $LogFilePath =$LogPath + $BuildName+"_"+$ServerName+"_"+$DbName+"_Log.txt"
           try
           {
                Add-PSSnapin SqlServerCmdletSnapin100
                Add-PSSnapin SqlServerProviderSnapin100
                Invoke-Sqlcmd -ServerInstance "$ServerName" -Database "$DbName" -InputFile "$ScriptFile" -Variable $DeployVarArray -OutputSqlErrors:$true -Verbose *>&1  |Out-File -FilePath $LogFilePath
           }
           Catch
           {
                $_.Exception.ToString()|Out-File -FilePath $LogFilePath -Append 
                LogFileGen -SummaryTxt ( "Execute SQL Error : " +$_.Exception)
           }
        }
       # Print Change script colletion data.=====================================
       $dtScriptList |Sort-Object Order |Format-Table -AutoSize

       if (Test-Path $ScriptFileName)
       {

               # Iterate throw environment config records. ====================== 
               $EnvValue = $EnvDetailList|  Where-Object {$_.dbclass -eq $DbProjectName -and $_.Replication -in ('Pub','None')}
               foreach($EnvRow in $EnvValue)
               {
                   LogFileGen -SummaryTxt ("Deploying Script on :" + $EnvRow.SERVERNAME.Trim()+"_"+$EnvRow.DBNAME)
                   # 1-DNN30 ====================================================
                   if ($DbProjectName -eq "DNN30")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+"")
                   }
                   # 2-DNNStage ================================================= 
                   Elseif ($DbProjectName -eq "DNNStage")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+"")
                   }
                   # 3-ClaimStatus ==============================================
                   Elseif ($DbProjectName -eq "ClaimStatus")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+"")
                   }
                   # 4-CrossSiteYBFU ============================================
                   Elseif ($DbProjectName -eq "CrossSiteYBFU")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+"")
                   }
                   # 5-Reference ================================================
                   Elseif ($DbProjectName -eq "Reference")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("DefaultFDataPath="+$DefaultFDataPath+"")
                   }
                   # 6-Global_AhtoDialer ========================================
                   Elseif ($DbProjectName -eq "Global_AhtoDialer")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+"")
                   }
                   # 7-DataArchive ==============================================
                   Elseif ($DbProjectName -eq "DataArchive")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+""),("AccretiveServer="+$AccretiveServer+""),("EligibilityDb="+$EligibilityDb+""),("EligibilityServer="+$EligibilityServer+"")
                   }
                   # 8-ELIGIBILITY ==============================================
                   Elseif ($DbProjectName -eq "ELIGIBILITY")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+""),("DataArchiveDb="+$DataArchiveDb+""),("DataArchiveServer="+ $DataArchiveServer+"")
                   }
                   # 9-Accretive ================================================
                   elseif ($DbProjectName -eq "Accretive")
                   { 
                       $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("DefaultFDataPath='"+$DefaultFDataPath+"'"),("AccretiveLogsDb="+ $AccretiveLogsDb+""),("AccretiveLogsServer="+$AccretiveLogsServer+""),("AuditDNNBetaDb="+$AuditDNNBetaDb+""),`
                                     ("AuditDNNBetaServer="+$AuditDNNBetaServer+""),("DataArchiveDb="+$DataArchiveDb+""),("DataArchiveServer="+$DataArchiveServer+""),("DNNDb="+$DNNDb+""),("EligibilityDb="+$EligibilityDb+""),("EligibilityServer="+$EligibilityServer+""),`
                                     ("FileExchangeDb="+$FileExchangeDb+""),("FileExchangeServer="+$FileExchangeServer+""),("ReferenceDb="+$ReferenceDb+"")
                   }
                    # 10-AccretiveLogs ==========================================
                   Elseif ($DbProjectName -eq "AccretiveLogs") 
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+""),("DNNDb="+$DNNDb+""),("EligibilityDb="+$EligibilityDb+""),("EligibilityServer="+$EligibilityServer+"")
                   }
                    # 11-CrossSiteSupport =======================================
                   Elseif ($DbProjectName -eq "CrossSiteSupport")
                   {
                         $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+""),("AccretiveServer="+$AccretiveServer+"")
                   }
                    # 12-Global_FCC_PreRegistration =============================
                   Elseif ($DbProjectName -eq "Global_FCC_PreRegistration")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+"")
                   }
                    # 13-TranGLOBAL =============================================
                   Elseif ($DbProjectName -eq "TranGLOBAL")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+"")
                   }
                    # 14-FileExchange ===========================================
                   Elseif ($DbProjectName -eq "FileExchange")
                   {
                        $MyArrayAcc = ("DatabaseName="+$EnvRow.DBNAME+""),("AccretiveDb="+$AccretiveDb+""),("AccretiveLogsDb="+$AccretiveLogsDb+""),("AccretiveLogsServer="+$AccretiveLogsServer+""),("DNNDb="+$DNNDb+""),("DNNServer="+$DNNServer+""),("ReferenceDb="+$ReferenceDb+""),("ReferenceServer="+$ReferenceServer+"")
                   }
                   # 15-Tran ====================================================
                   Elseif ($DbProjectName -eq "Tran")
                   {

                   }
                   execute-Sql -ServerName $EnvRow.SERVERNAME.Trim() -DbName $EnvRow.DBNAME.Trim() -ScriptFile $Row["FileName"].ToString() -DeployVarArray $MyArrayAcc
               }

       }
       else 
       {
       LogFileGen -SummaryTxt "Invalid Script file."
       }
    }
    catch
    {
      LogFileGen -SummaryTxt $_.Exception  
    }
   
}
Catch
{
   LogFileGen -SummaryTxt $_.Exception.ToString()
}


