#param([string]$DropLocation="",[string]$ENV="CI",[string] $FileList="textfile.txt",[string] $ReportMailTo="nasimuddin@accretivehealth.com",[string] $MasterDeploy="0",[string] $buildNumber=(Get-Date -format 'yyyyMMdd'))


#Add-PSSnapin SqlServerCmdletSnapin100
#Add-PSSnapin SqlServerProviderSnapin100
$DropLocation="C:\RevenueCycle\R2016.5\Care"
$ENV="CI"
#$FileList="Database\aaDeployment_Scripts\accretiveTest.txt"
$FileList="Database\aaDeployment_Scripts\905808ePARSAccountsappearingYBFU2.txt"
$ReportMailTo="nasimuddin@accretivehealth.com"
$BUILDNUMBER=(Get-Date -format 'yyyyMMdd')
$MasterDeploy="0"


$isSuccessded="1"
$onErrorExit=$False
$objStatusList=@()
$sDepStatus=""

<#Parameters 1 Environment (QA, UAT or PROD) 2 Client environments (CARE or IMH) 3 txt file 4 command mode Test file to deploy Environment: UAT QA CARE|IMH Database |Tran| All #>

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null
try
{
  #Write-Host ("ENV=$ENV ,  buildNumber= $BUILDNUMBER , DropLocation=$DropLocation, ConfigLocation=$LogPath, DBList=$DbList")
###################### Global Variables ########################################
 $EnvConfigPath =""
 $LogPath =""
 $EnvDetailList =""
 ####### Out put Log File ########## 
 $LogPath = $DropLocation+"\Logs\"
 $LogFilePath =$LogPath + "Deployment_EventLog_Summary.txt"

 ####### Create configuration file for Deployment ##########
 $EnvConfigPath  = $DropLocation +"\Database\aaDeployment_Scripts\DeploymentTools\EnvironmentConfig-"+$ENV+".csv"
 $EnvconfigFileName=$EnvConfigPath|Split-path -Leaf
#######Function for loging events and exceptions ####################################
 Function LogFileGen([string] $SummaryTxt )
 {  
        #Write-Host $SummaryTxt
        $((Get-Date).ToString('yyyy,MM,dd hh:mm:ss'))+" | "+$SummaryTxt |Out-File -FilePath $LogFilePath -Append 
 }

 ######## Validate log file path.#######################################################
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
     LogFileGen -SummaryTxt "Reading Environment Config file $EnvConfigPath"
     Write-Host "Reading Environment Config file $EnvConfigPath"

     if (Test-Path $EnvConfigPath ) 
     {
        $EnvDetailList= Import-Csv $EnvConfigPath  | Where-Object {$_.env -eq $Env}
             LogFileGen -SummaryTxt "Completed Reading Environment Config file "
     }
     Else { LogFileGen -SummaryTxt "Environment Config file Missing." }
 )

 
   # Function for execute sql scripts. =======================================
  
         Function Execute-Sql{
           param($Client,$ServerName, $DbName, $ScriptFile,$txtFile)

           $txtFileName= $txtFile|Split-Path -Leaf
           $LogFilePathD =$LogPath + $txtFileName+"_"+$Client +"_"+$ENV+"_Log.txt"
           try
           {
                #[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null 
                $scriptFileName=$ScriptFile |Split-Path -Leaf
                LogFileGen -SummaryTxt ( "Deployment Begin :- DB Name: " + $DbName + ", Server:" +$ServerName +", ScriptFile:" + $scriptFileName)
                "Deployment Begin:-  DBName:" + $DbName + ", Server:" +$ServerName +", ScriptFile:" + $scriptFileName | Out-File $LogFilePathD -Append
                Write-Host "Deployment Begin:-  DBName:$DbName , Server:$ServerName , ScriptFile:$scriptFileName"


                #Invoke-Sqlcmd -QueryTimeout 0 -ConnectionTimeout 0 -ServerInstance "$ServerName" -InputFile "$ScriptFile" -ErrorAction 'Continue' -Database "$DbName" -OutputSqlErrors:$true -Verbose *>&1 |Out-File -FilePath $LogFilePathD
                $result=Sqlcmd -b -E -S "$ServerName" -i "$ScriptFile" -d "$DbName"

                if($LASTEXITCODE -eq 1)
                {
                    throw $result
                }
                
                    $result |Out-File -FilePath $LogFilePathD -Append
                    $result
               
                #Invoke-Sqlcmd -ServerInstance "$ServerName" -InputFile "$ScriptFile" -ErrorAction 'Continue' -Database "$DbName" -OutputSqlErrors:$true -Verbose *>&1|Out-Host
                #Invoke-Sqlcmd -ServerInstance "$ServerName" -InputFile "$ScriptFile" -ErrorAction 'Continue' -Database "$DbName" -OutputSqlErrors:$true -Verbose *>&1
                #############deployment status###################################
                $Global:objStatusList+=New-Object PsObject -property @{  ENV = $ENV; Client = $Client; ServerName=$ServerName; DBName=$DbName;Status="Succeded";ScriptFile=($ScriptFile|Split-Path -Leaf);DeploymentTime=(Get-Date -format "MM/dd/yyyy HH:mm:ss");Details=""}
                #################################################################################
                #$objectsDeploy= Get-Content -Path $LogFilePathD | Out-String 
                #Write-Host $objectsDeploy

                Write-Host "Deployment Completed`n"
                LogFileGen -SummaryTxt ( "Deployment Completed`n")
                LogFileGen -SummaryTxt ( "`n")
                "Deployment Completed`n" | Out-File $LogFilePathD -Append

           }
           Catch
           {
                #############deployment status###################################
                $Global:objStatusList+=New-Object PsObject -property @{  ENV = $ENV; Client = $Client; ServerName=$ServerName; DBName=$DbName;Status="Failed";ScriptFile=($ScriptFile|Split-Path -Leaf);DeploymentTime=(Get-Date -format "MM/dd/yyyy HH:mm:ss");Details=$_.Exception}

                $_.Exception.ToString()|Out-File -FilePath $LogFilePathD -Append 
                $_.Exception.Message|Out-File -FilePath $LogFilePath -Append 
                #$objectsDeploy= Get-Content -Path $LogFilePathD | Out-String 
                #$objectsDeploy 
                #LogFileGen -SummaryTxt ( "Deployment Error in " +$DbName+ " Execute SQL Error : " +$_.Exception)

                if($onErrorExit -eq $true)
                {
                  throw $_.Exception
                }
                else
                {
                    $global:isSuccessded="0"
                }

           }

        }




        Function sendMail()
        {

		        $a = @{Expression={$_.Env};Label="Env";width=10}, `
                     @{Expression={$_.Client};Label="Client";width=10}, `
                     @{Expression={$_.ServerName};Label="Server";width=50}, `
                     @{Expression={$_.DeploymentTime};Label="DeploymentTime";width=20}, `
                     @{Expression={$_.DBName};Label="DBName";width=25}, `
                     @{Expression={$_.Status};Label="Status";width=10}, `
                     @{Expression={$_.ScriptFile};Label="ScriptFile"}, `
                     @{Expression={$_.Details};Label="Details"}


        Write-Host "Sending Deployment report..."
				if($ReportMailTo)
				{
				$mailto  =  $ReportMailTo
				}
                $mailcc  = "nasimuddin@accretivehealth.com"
                $mailfrom= "ALM@accretivehealth.com"

                #SMTP server name
                $smtpServer = "smtpr.accretivehealth.local"
                $msg = new-object System.Net.Mail.MailMessage
                #Creating SMTP server object
                $smtp = new-object System.Net.Mail.SmtpClient($smtpServer)

				$subject="DB Txt file Deployment report - $BUILDNUMBER"
                $head="<style>body{font-family:Arial; font-size:11px;} th, td {background-color: white; } table{background-color: gray;}</style>"
                $body="Hello Team,<br /> <br />Deployment report for txt file for the build number $BUILDNUMBER<br /><br />"
                $footer="<br />Regards<br /><br />
                            ALM Team
                            "
                #$att = new-object Net.Mail.Attachment($DepSummaryCSV)
                $msg.From = $mailfrom
                $msg.To.Add($mailto)
                #$msg.CC.Add($mailcc)
				$msg.Bcc.Add($mailcc)
                $msg.subject =  $subject
                $mailBody=$Global:objStatusList|ConvertTo-Html -Head $head -Body $body -PostContent $footer
                $mailBody=$mailBody.replace("<table>","<table  cellspacing='1px' cellpadding='4px'>")
                $msg.body = $mailBody
                $msg.IsBodyHTML = $true
                #$msg.Attachments.Add($att)
                #Sending email
                #$smtp.Send($msg)
                #$att.Dispose()
                Write-Host "Mail successfully sent to $mailto"
                
                Write-Host "`n`n=========================== Deployment Summary ======================================"
                $Global:objStatusList|Format-Table -Wrap $a -AutoSize
                LogFileGen -SummaryTxt "`n"
                LogFileGen -SummaryTxt "`n`n================================== Deployment Summary =================================="
                $Global:objStatusList|Format-Table -Wrap $a|Out-File $LogFilePath -Append


}

  
LogFileGen -SummaryTxt ( "=============================Deployment phase Begin====================================") 



####################### Check master file and deploy #####################
if($MasterDeploy -eq "1")
{
    foreach($MtxtFile in ($FileList.Split("|")))
    {
        if(Test-Path $DropLocation\$MtxtFile)
        {
            $MatertxtPath=split-path $DropLocation\$MtxtFile -parent
            Write-Host "Begin Master txt file :- '$MtxtFile' `n" -ForegroundColor Green
            LogFileGen -SummaryTxt "Begin Master txt file :- '$MtxtFile' `n"
            foreach($txtFile in (Get-Content $DropLocation\$MtxtFile))
            {
            if(Test-Path $MatertxtPath\$txtFile)
                {
                    $txtFilePath=split-path $MatertxtPath\$txtFile -parent
                    Write-Host "Begin TXT file :- $txtFile`n" -ForegroundColor Gray
                    LogFileGen -SummaryTxt  "Begin TXT file :- $txtFile`n"
                    foreach($txtRow in (Get-Content $MatertxtPath\$txtFile))
                    {
                        $RowValues=$txtRow.Split("|")
                        $Client=$RowValues[0]
                        $DBClass=$RowValues[1]
                        $DBNameAll=$RowValues[2]
                        $DBName=if($RowValues[2] -eq "All"){""}else{$RowValues[2]}
                        $ScriptPath=$RowValues[3]
                        $ScriptName=$RowValues[4]

                        $scriptPathName=$txtFilePath+"\"+$ScriptPath+$ScriptName
                        $ScriptName=$scriptPathName| Split-Path -Leaf
                        #[environment]::CurrentDirectory="$txtFilePath"

                        if(Test-Path (Resolve-Path -Path $scriptPathName))
                        {
                        if(($EnvDetailList| Where-Object { $_.dbclass -eq $DBClass -and $_.CLIENT -eq $Client -and $_.DBNAME -like '*'+$DBName+'*' -and $_.Replication -in ('Pub','None')}))
                            {
                                $EnvDetailList| Where-Object { $_.dbclass -eq $DBClass -and $_.CLIENT -eq $Client -and $_.DBNAME -like '*'+$DBName+'*' -and $_.Replication -in ('Pub','None')}| %{
                                Execute-Sql -Client $Client -ServerName $_.SERVERNAME -DbName $_.DBName -ScriptFile $scriptPathName -txtFile $txtFile
                                }
                            }
                        else
                            {

                                $msg="Environment config check failed for $ScriptPath $ScriptName. DBClass:$DBClass, DBName:$DBNameAll, Client:$Client, Env:$ENV not found in Environment Config file $EnvconfigFileName.`n`n"
                                Write-Warning $msg
                                LogFileGen -SummaryTxt  $msg
                                $Global:objStatusList+=New-Object PsObject -property @{  ENV = $ENV; Client = $Client; ServerName="not found"; DBName="DBClass:$DBClass";Status="Failed";ScriptFile=$ScriptName;DeploymentTime=(Get-Date -format "MM/dd/yyyy HH:mm:ss");Details=$msg}

                            }
                        }
                        else
                        {
                             Write-Host "Script file $ScriptName not found" -ForegroundColor Yellow
                        }
            
                    }
                        Write-Host "End txt file $txtFile deployment" -ForegroundColor Gray
                        LogFileGen -SummaryTxt  "End TXT file :- $txtFile`n`n"
                }
            else
                {
                    Write-Host "txt file $txtFile not found." -ForegroundColor Yellow
                }
            }
            Write-Host "`nEnd Master txt file '$MtxtFile' deployment completed" -ForegroundColor Green
            LogFileGen -SummaryTxt  "End Master txt file :- $MtxtFile`n`n"
        }
        else
        {
            Write-Host "`nMaster file '$MtxtFile' not found. please check if Master file exists." -ForegroundColor Yellow
        }
    }
}
else
{
    foreach($txtFile in ($FileList.Split("|")))
    {
        if(Test-Path $DropLocation\$txtFile)
        {
            $txtFilePath=split-path $DropLocation\$txtFile -parent
            Write-Host "Begin TXT file '$txtFile'`n" -ForegroundColor Green
            LogFileGen -SummaryTxt  "Begin TXT file $txtFile"
            foreach($txtRow in (Get-Content $DropLocation\$txtFile))
            {

                $RowValues=$txtRow.Split("|")
                $Client=$RowValues[0]
                $DBClass=$RowValues[1]
                $DBNameAll=$RowValues[2]
                $DBName=if($RowValues[2] -eq "All"){""}else{$RowValues[2]}
                $ScriptPath=$RowValues[3]
                $ScriptName=$RowValues[4]

                $scriptPathName=$txtFilePath+"\"+$ScriptPath+$ScriptName
                $ScriptName=$scriptPathName| Split-Path -Leaf
                #[environment]::CurrentDirectory="$txtFilePath"

                if(Test-Path (Resolve-Path -Path $scriptPathName))
                {
                    if(($EnvDetailList| Where-Object { $_.dbclass -eq $DBClass -and $_.CLIENT -eq $Client -and $_.DBNAME -like '*'+$DBName+'*' -and $_.Replication -in ('Pub','None')}))
                    {
                        $EnvDetailList| Where-Object { $_.dbclass -eq $DBClass -and $_.CLIENT -eq $Client -and $_.DBNAME -like '*'+$DBName+'*' -and $_.Replication -in ('Pub','None')}| %{
                        Execute-Sql -Client $Client -ServerName $_.SERVERNAME -DbName $_.DBName -ScriptFile $scriptPathName -txtFile $txtFile
                        }
                    }
                    else
                    {
                        $msg="Environment config check failed for $ScriptName. DBClass:$DBClass, DBName:$DBNameAll, Client:$Client, Env:$ENV not found in Environment Config file $EnvconfigFileName.`n`n"
                        Write-Warning $msg
                        LogFileGen -SummaryTxt  $msg
                        $Global:objStatusList+=New-Object PsObject -property @{  ENV = $ENV; Client = $Client; ServerName="not found"; DBName="DBClass:$DBClass";Status="Failed";ScriptFile=$ScriptName;DeploymentTime=(Get-Date -format "MM/dd/yyyy HH:mm:ss");Details=$msg}
                    }
                }
                else
                {
                        Write-Host "Script file $ScriptName not found" -ForegroundColor Yellow
                }

            
            }
            Write-Host "End txt file $txtFile deployment" -ForegroundColor Green
            LogFileGen -SummaryTxt  "End TXT file :- $txtFile`n`n"
        }
        else
        {
            Write-Host "`nTxt file '$MtxtFile' not found. please check if file exists." -ForegroundColor Yellow
        }
    }
   
}

  if($isSuccessded -eq "0")
  {
    throw "Deployment Error: Please check Deployment report or logs for more details."
  }

  sendMail

}
Catch
{
    LogFileGen -SummaryTxt ( "Deployment Error : " +$_.Exception)
	Write-Host $_.Exception
    sendMail
    throw $_.Exception
}

