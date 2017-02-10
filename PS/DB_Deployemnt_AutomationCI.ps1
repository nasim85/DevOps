param([string]$RootPath="C:\RevenueCycle\R2016.5\Care\DB_Projects\ACH_DB_NonTran",[string]$DropLocation="C:\RevenueCycle\R2016.5\Care\DB_Projects",[string]$BuildName=(Get-Date -format 'yyyyMMdd') +"_"+(Get-Date -format 'HHmm'),[string]$ENV="PROD",[bool]$DeployChanges=$False,[string] $DbList="3",[bool]$ExcludeSynonym=$true)

#Add-PSSnapin SqlServerCmdletSnapin100
#Add-PSSnapin SqlServerProviderSnapin100
#Register the DLL we need #######################################################
Add-Type -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\120\DAC\bin\Microsoft.SqlServer.Dac.dll" 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null
 ###################### Global Variables ########################################
 $EnvConfigPath =""
 $LogPath =""
 $EnvDetailList =""
 # Out put Log File ############################################################# 
 $LogPath = $DropLocation+"\Logs\"
 $LogFilePath =$LogPath + $BuildName+"_EventLog_Summary.txt"
 ###################### SQLPackage Load #########################################
 $SQLPkgPath="${env:ProgramFiles(x86)}\Microsoft SQL Server\120\DAC\bin\sqlpackage.exe"
 $TFS = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 11.0\Common7\IDE\tf.exe"


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


 # Create a data table for holding change script details.========================
@( $dtScriptList = New-Object System.Data.DataTable            

 $dtScriptList.Columns.Add("FileName")| Out-Null
 $dtScriptList.Columns.Add("DBClass") | Out-Null
 $dtScriptList.Columns.Add("Order", [int]) | Out-Null
 $dtRow = $null)


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
    if($ExcludeSynonym -eq $true){
     for ($i=0; $i -lt $FileContaints.Count; $i++)
        {
 # Remove Drop User Scripts from Change Script =================================
 # Write-Host $FileContaints.GetValue($i).ToString()
            $SummaryTxt ="";
            $PrintTRG = "Y"
           $lineSkip=22
            if (($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP FULLTEXT" ))
                {
                $lineSkip=7
                }
             if (($FileContaints.GetValue($i) -match "PRINT N'Creating" -and $FileContaints.GetValue($i+4) -match "CREATE STATISTICS"))
                {
                $lineSkip=23
                }

            if ($IncludeTran -eq $true)
            {
#                 if (($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP USER|DROP ROLE|DROP SCHEMA|DROP SYNONYM|DROP FULLTEXT|sp_droprolemember" )-or
#                   ($FileContaints.GetValue($i) -match "PRINT N'Creating" -and $FileContaints.GetValue($i+4) -match "CREATE SYNONYM|CREATE STATISTICS")
#                     )

                 if (($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP SCHEMA|DROP FULLTEXT|sp_droprolemember" )-or
                   ($FileContaints.GetValue($i) -match "PRINT N'Creating" -and $FileContaints.GetValue($i+4) -match "CREATE STATISTICS")
                     )

                    {
                        $i = $i+$lineSkip
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
                if (($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP SCHEMA|DROP FULLTEXT|sp_droprolemember" )-or
                    ($FileContaints.GetValue($i) -match "PRINT N'Creating" -and $FileContaints.GetValue($i+4) -match "CREATE STATISTICS")
                    )
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
        }
    Else
    {
    for ($i=0; $i -lt $FileContaints.Count; $i++)
        {
 # Remove Drop User Scripts from Change Script =================================
 # Write-Host $FileContaints.GetValue($i).ToString()
            $SummaryTxt ="";
            $PrintTRG = "Y"
            if ($IncludeTran -eq $true)
            {
                 #if (($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP USER|DROP ROLE|DROP SCHEMA|EXECUTE sp_droprolemember")
                 if (($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP SCHEMA|EXECUTE sp_droprolemember")
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
                if (($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP SCHEMA|EXECUTE sp_droprolemember")
                    )
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
       # 16-AHCrossSite
       # 17-DNN
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
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "AHCrossSite"; ExcOrder = "16" }
    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "DNN"; ExcOrder = "17" }
   )

   IF($DbList -ne "0")
 {
    $DatabaseList =$DatabaseList  | Where-Object {$_.ExcOrder -in ($DbList -split ",")}
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

				   #& $SQLPkgPath /a:DeployReport /SourceFile:$ProjDacpacPath /Profile:$ProfilePath /OutPutPath:$UpdatedChangeScriptFile".xml"  |Out-File -FilePath $LogFilePath -Append 
                   #if($DeployChanges -eq $true)
                   #{
                        #& $SQLPkgPath /a:Publish /SourceFile:$ProjDacpacPath /Profile:$ProfilePath |Out-File -FilePath $LogFilePath -Append 
                   #}
                   #else
                   #{
                        & $SQLPkgPath /a:Script /SourceFile:$ProjDacpacPath /Profile:$ProfilePath /OutPutPath:$OrgOutScriptPath  |Out-File -FilePath $LogFilePath -Append 
                   #}
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


	 if ($DeployChanges -eq $true)
    {
     # Function for execute sql scripts. =======================================
       Function Execute-Sql{
           param($ServerName, $DbName, $ScriptFile)

           $LogFilePathD =$LogPath + $BuildName+"_"+$ServerName.Replace("\" ,"-")+"_"+$DbName+"_Log.txt"
           try
           {
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null 
                $sqlSrv = New-Object 'Microsoft.SqlServer.Management.Smo.Server' ($server)
                LogFileGen -SummaryTxt ( "Deployment start for :- " + $DbName + " on Server :-" +$server)
                Invoke-Sqlcmd -ServerInstance "$server" -InputFile "$ScriptFile" -ErrorAction 'Continue' -Database "$DbName" -OutputSqlErrors:$true -Verbose *>&1  |Out-File -FilePath $LogFilePathD 
                LogFileGen -SummaryTxt ( "Deployment Completed for : " +$DbName)

           }
           Catch
           {
                $_.Exception.ToString()|Out-File -FilePath $LogFilePathD -Append 
                LogFileGen -SummaryTxt ( "Deployment Error in " +$DbName+ " Execute SQL Error : " +$_.Exception)
                Write-Error "Deployment Error: $_.Exception.ToString()" -Targetobject $_
                #Write-Host "Deployment Error in " $DbName " Error Details:- " $_.Exception
           }
        }


     # Print Change script colletion data.=====================================
       $dtScriptList |Sort-Object Order |Format-Table -AutoSize


       if ($dtScriptList.Rows.Count -gt 0)
       {
       # Iterate throw change script list. ====================================== 
           foreach($Row in $dtScriptList.Rows)
           {
            
             $ProfilePathD=($RootPath+"\"+$Row["DBClass"].ToString() +"\"+$Row["DBClass"].ToString()+"_"+$Env+".publish.xml")
              if (Test-Path $ProfilePathD )
              {

                   $dacProfileD = [Microsoft.SqlServer.Dac.DacProfile]::Load($ProfilePathD)
                   $Connection = New-Object System.Data.SQLClient.SQLConnection($dacProfileD.TargetConnectionString)
                   $server=$Connection.DataSource
                   $Database=$dacProfileD.TargetDatabaseName

                   execute-Sql  -ServerName $server -DbName $Database -ScriptFile $Row["FileName"].ToString()
               }
           }
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


