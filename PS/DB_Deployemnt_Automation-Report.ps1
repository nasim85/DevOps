param([string]$RootPath="C:\Users\300915\Desktop\RevenueCycle\R2015.5\Care\DB_Projects\ACH_DB_NonTran",[string]$DropLocation="C:\Users\300915\Desktop\RevenueCycle\R2015.5\Care\DB_Projects",[string]$BuildName=(Get-Date -format 'yyyyMMdd') +"_"+(Get-Date -format 'HHmm'),[string]$ENV="PROD",[string] $DbList="1",[bool]$ExcludeSynonym=$true,[string]$RequestedByEmail="nasimuddin@accretivehealth.com")
#param([string]$RootPath="C:\Users\300915\Desktop\RevenueCycle\R2015.5\Care\DB_Projects\ACH_DB_Tran",[string]$DropLocation="C:\Users\300915\Desktop\RevenueCycle\R2015.5\Care\DB_Projects",[string]$BuildName=(Get-Date -format 'yyyyMMdd') +"_"+(Get-Date -format 'HHmm'),[string]$ENV="PROD",[string] $DbList="15",[bool]$ExcludeSynonym=$true)


	#Add-PSSnapin SqlServerCmdletSnapin100
	#Add-PSSnapin SqlServerProviderSnapin100
 #Register the DLL we need #######################################################
Add-Type -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\130\DAC\bin\Microsoft.SqlServer.Dac.dll" 

 ###################### Global Variables ########################################
 $EnvConfigPath =""
 $LogPath =""
 $EnvDetailList =""
 # Out put Log File ############################################################# 
 $LogPath = $DropLocation+"\Logs\"
 $LogFilePath =$LogPath + $BuildName+"_EventLog_Summary.txt"
 ###################### SQLPackage Load #########################################
 $SQLPkgPath="${env:ProgramFiles(x86)}\Microsoft SQL Server\130\DAC\bin\sqlpackage.exe"
 $TFS = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 11.0\Common7\IDE\tf.exe"

 #$BuildName= $Env:TF_BUILD_COLLECTIONURI

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



Function sendMail([string] $mailBody)
{
                #Assign value
                #Try{
                    #$MailToPerson= $env:TF_BUILD_REQUESTEDBY.Split("\")[1]      
                 #   Import-Module ActiveDirectory

                  #   try
	              #  {
                  #          $name=$env:RequestedBy
                  #          $email = Get-ADUser -Filter {Name -eq $name}   -Server "india"   –Properties  mail | Select-Object mail
                  #   }
	          #	Catch {
	            #            $email = "Nomailidfound"
	            #     }
                #}
                #Catch
                #{

                 #  LogFileGen -SummaryTxt $_.Exception.ToString()
                 #   $MailToPerson="nasimuddin"
                #}



               
                #Assign sending Person mailID
                #$mailto  =  $MailToPerson+"@accretivehealth.com"
                #$mailto  =  $email.mail
				$mailto  =  $RequestedByEmail
				LogFileGen -SummaryTxt "Email ID requested by"
                LogFileGen -SummaryTxt $RequestedByEmail
                $mailcc  = "nasimuddin@accretivehealth.com"
                $mailfrom= "ALM@accretivehealth.com"

                #SMTP server name
                $smtpServer = "smtpr.accretivehealth.local"
                $msg = new-object System.Net.Mail.MailMessage

                #Creating SMTP server object
                $smtp = new-object System.Net.Mail.SmtpClient($smtpServer)
                 
				$subject="DB Project validation - Tran SQL changes $BuildName"

                $msg.From = $mailfrom
                $msg.To.Add($mailto)
                $msg.CC.Add($mailcc)
                $msg.subject =  $subject
                $msg.body = $mailBody
                $msg.IsBodyHTML = $true
             
                #Sending email
                $smtp.Send($msg)
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

    $DatabaseList+=New-Object PsObject -property @{  DatabaseName = "DNN"; ExcOrder = "1" }
    #$DatabaseList+=New-Object PsObject -property @{  DatabaseName = "DNN30"; ExcOrder = "1" }
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
    #$DatabaseList+=New-Object PsObject -property @{  DatabaseName = "DNN"; ExcOrder = "17" }
   )

   IF($DbList -ne "0")
 {
    $DatabaseList =$DatabaseList  | Where-Object {$_.ExcOrder -in ($DbList -split ",")}
 }   



     $style = "Hi,</br></br>This SQL change script report is generated using the build Definition $BuildName by comparing with Production. </br></br>
	 This will <b><i>proactively</i></b> help to verify the SQL changes before  it reaches production.</br></br><style>BODY{font-family: Arial; font-size: 10pt;}"
                        $style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
                        $style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
                        $style = $style + "TD{border: 1px solid black; padding: 5px; }"
                        $style = $style + "</style>"

    $table=$style +"<table><th>Operation</th><th>Object</th><th>Object Type</th><th>DataBase</th>"

    $reportFile= $RootPath + "\DailyBuildScript\"+ $Env+"_"+$BuildName+"_Report.html"

    $table | Out-File $reportFile

    #$htmlBody=$table

    $table=''


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
				   & $SQLPkgPath /a:DeployReport /SourceFile:$ProjDacpacPath /Profile:$ProfilePath /OutPutPath:$UpdatedChangeScriptFile".xml"  |Out-File -FilePath $LogFilePath -Append 
                   #& $SQLPkgPath /a:Script /SourceFile:$ProjDacpacPath /Profile:$ProfilePath /OutPutPath:$OrgOutScriptPath  |Out-File -FilePath $LogFilePath -Append 



                    

                    [xml] $doc=(Get-Content $UpdatedChangeScriptFile".xml")#| Format-Xml
                    
                    

                    foreach($node in $doc.DeploymentReport.Operations.SelectNodes('*[@Name]')|Where-Object {$_.Name -in ("Drop","Create","Alter","Refresh","TableRebuild")  })
                        {

                            $Operation= $node.attributes['Name'].value
                            if($node.HasChildNodes)
                            {
        
        
                                 foreach ($filterNode in $node.ChildNodes|Where-Object {$_.Type -notmatch "SqlSynonym|SqlFullTextIndex|SqlFullTextCatalog|SqlUser|SqlRole|SqlSchema|SqlStatistic"  }) 
                                        { 
                                            $table +="<tr><td>"+$Operation +"</td><td>"+$filterNode.Value +"</td><td>"+$filterNode.Type +"</td><td>"+$DbProjectName +"</td></tr>"
                                        } 
                            
                            }
        
                        }

                    #$table +="</table>"

                    $table | Out-File $reportFile -Append

                    #$htmlBody=$htmlBody +$table

      
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
       LogFileGen -SummaryTxt ($Database.DatabaseName + " : Start Change Report Generation.")
       GenerateChangeScript -DbProjectName $Database.DatabaseName -ExcOrder $Database.ExcOrder
       LogFileGen -SummaryTxt ($Database.DatabaseName +" : END Change Report Generation.")
    }

    $table ="</table> </br> </br> </br>
	 Thanks, ALM & RM "

    $table | Out-File $reportFile -Append

    $htmlBody = Get-Content $reportFile

     #LogFileGen -SummaryTxt $htmlBody

    sendMail $htmlBody

}
Catch
{
   LogFileGen -SummaryTxt $_.Exception.ToString()
}


