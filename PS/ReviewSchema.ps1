#http://visualstudiogallery.msdn.microsoft.com/b1ef7eb2-e084-4cb8-9bc7-06c3bad9148f
# PowerShell "D:\PowerShellTools\ReviewSchema\ReviewSchema.ps1" "$/RevenueCycle/R2013.6/Care" "C:\AhtoAccess\Revenue_Cycle\Care"
 
Add-PSSnapin Microsoft.TeamFoundation.PowerShell  
          
            [parameter(HelpMessage="Enter the TFS Path",ValueFromPipeline=$True)]
            $TFSPath = ""
            [parameter(HelpMessage="Enter the Date Range",ValueFromPipeline=$True)]
            $StartDate = (Get-date).AddDays(-1).ToShortDateString()
            [parameter(HelpMessage="Enter the Date Range",ValueFromPipeline=$True)]
            $EndDate = (Get-date).ToShortDateString()
            [parameter(HelpMessage="Enter Search criteria",ValueFromPipeline=$True)]
            $SearchString = @(“CREATE TABLE", “DROP TABLE","ALTER TABLE","CREATE CLUSTERED INDEX","CREATE NONCLUSTERED INDEX","CREATE INDEX","CREATE UNIQUE CLUSTERED INDEX","CREATE UNIQUE NONCLUSTERED INDEX","CREATE UNIQUE INDEX","ALTER INDEX","DROP INDEX")
            [parameter(HelpMessage="Enter exclude search criteria",ValueFromPipeline=$True)]
            $excludeString = @(“CREATE TABLE #",“DROP TABLE #")


        [xml]$configfile = Get-Content "D:\PowerShellTools\ReviewSchema\ReviewConfig.xml" 
        [System.Xml.XmlElement] $root = $configfile.get_DocumentElement()

     
        $TFSCurrentBranchDatabase=$root.Tasks.TFSCurrentBranchDatabase   
        $TFSCurrentBranchDBControlLiteFacility=$root.Tasks.TFSCurrentBranchDBControlLiteFacility
        $TFSCurrentPathDatabase= $root.Tasks.TFSCurrentPathDatabase
        $TFSCurrentPathDBControlLiteFacility= $root.Tasks.TFSCurrentPathDBControlLiteFacility

        $TFSPatientBetaDatabase=$root.Tasks.TFSPatientBetaDatabase   
        $TFSPatientBetaDBControlLiteFacility=$root.Tasks.TFSPatientBetaDBControlLiteFacility
        $TFSPatientBetaPathDatabase= $root.Tasks.TFSPatientBetaPathDatabase
        $TFSPatientBetaPathDBControlLiteFacility= $root.Tasks.TFSPatientBetaPathDBControlLiteFacility
       
       
       
        $TFSCurrentBranchDBControlLiteFacilityAdmin=$root.Tasks.TFSCurrentBranchDBControlLiteFacilityAdmin
        $TFSCurrentBranchDBControlLiteFacilityBind=$root.Tasks.TFSCurrentBranchDBControlLiteFacilityBind
        $TFSCurrentBranchDBControlLiteFacilityCore=$root.Tasks.TFSCurrentBranchDBControlLiteFacilityCore
        $TFSCurrentBranchDBControlLiteFacilityHL7Stage=$root.Tasks.TFSCurrentBranchDBControlLiteFacilityHL7Stage
        $TFSCurrentBranchDBControlLiteFacilityNotificationDb=$root.Tasks.TFSCurrentBranchDBControlLiteFacilityNotificationDb
        $TFSCurrentBranchDBControlLiteFacilityStage= $root.Tasks.TFSCurrentBranchDBControlLiteFacilityStage
        $TFSCurrentBranchDBControlLiteFacilityTran=$root.Tasks.TFSCurrentBranchDBControlLiteFacilityTran
        $TFSServerString=$root.Tasks.TFSServerString


       
            $DateRange = "D"+$StartDate.ToString()+" 00:00:00Z~D"+$EndDate.ToString()+" 23:59:59z"
            Write-Host $DateRange
          #  $tfsServerString = "http://tfs.ahtoit.net:8080/tfs/revenuecyclecoll"
            $tfs = Get-TfsServer $TFSServerString
            $Reviewlist=''
            $Logfile = "D:\PowerShellTools\ReviewSchema\Logs\log.txt"
              Add-content $Logfile -value "Log"
            #Get the latest from TFS
            CD $TFSCurrentPathDatabase
            tf workspace /delete "1" /noprompt /s:$tfs 
            tf workspace /new /s:$tfs "1" /noprompt 
            
              
            tf workfold /s:$tfs /workspace:"1"  /map  $TFSCurrentBranchDatabase  $TFSCurrentPathDatabase
            CD $TFSCurrentPathDatabase
            tf get /force /recursive 
              "get" | D:\PowerShellTools\ReviewSchema\Logs\log.txt

            $TFSPath =  $TFSCurrentBranchDatabase
            $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                #Get-Content -Path $item.ServerItem.Substring($item.ServerItem.Length - ($item.ServerItem.Length - $item.ServerItem.LastIndexOf("/Care/"))+6)  -encoding UTF8 

                #if(Test-Path -Path ($item.ServerItem.Substring($item.ServerItem.Length - ($item.ServerItem.Length - $item.ServerItem.LastIndexOf("/Care/"))+6)))
                if(Test-Path -Path ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle")))
                { 
                       $match = (Get-Content -Path ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle"))) -replace('\s+', ' ') | Select-String -Pattern  $SearchString
                    
                       $temptable = select-string -Path  ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle")) -Pattern $excludeString
                     
                       if(($match.length -ne 0) -and ($temptable.Filename.Length -eq 0))
                       {
                            $Reviewlist += $item.ServerItem + "`r`n" 
                       }    
                }
            }
 
             
            CD  $TFSCurrentPathDBControlLiteFacility
            tf workspace /new /s:$tfs "2" /noprompt 
            tf workfold /s:$tfs /workspace:"2"/map   $TFSCurrentBranchDBControlLiteFacility  $TFSCurrentPathDBControlLiteFacility
            CD  $TFSCurrentPathDBControlLiteFacility
            tf get /force /recursive 

             $TFSPath =   $TFSCurrentBranchDBControlLiteFacility
             $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                #Get-Content -Path $item.ServerItem.Substring($item.ServerItem.Length - ($item.ServerItem.Length - $item.ServerItem.LastIndexOf("/Care/"))+6)  -encoding UTF8 

                #if(Test-Path -Path ($item.ServerItem.Substring($item.ServerItem.Length - ($item.ServerItem.Length - $item.ServerItem.LastIndexOf("/Care/"))+6)))
                if(Test-Path -Path ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle")))
                { 
                       $match = (Get-Content -Path ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle"))) -replace('\s+', ' ') | Select-String -Pattern  $SearchString
                    
                       $temptable = select-string -Path  ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle")) -Pattern $excludeString
                     
                       if(($match.length -ne 0) -and ($temptable.Filename.Length -eq 0))
                       {
                            $Reviewlist += $item.ServerItem + "`r`n" 
                       }    
                }
            }

             
             CD $TFSPatientBetaPathDatabase
             tf workspace /new /s:$tfs "3" /noprompt 
            tf workfold /s:$tfs /workspace:"3" /map $TFSPatientBetaDatabase $TFSPatientBetaPathDatabase
             CD $TFSPatientBetaPathDatabase
            tf get /force /recursive 
             $TFSPath = $TFSPatientBetaDatabase
             $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                #Get-Content -Path $item.ServerItem.Substring($item.ServerItem.Length - ($item.ServerItem.Length - $item.ServerItem.LastIndexOf("/Care/"))+6)  -encoding UTF8 

                #if(Test-Path -Path ($item.ServerItem.Substring($item.ServerItem.Length - ($item.ServerItem.Length - $item.ServerItem.LastIndexOf("/Care/"))+6)))
                if(Test-Path -Path ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle")))
                { 
                       $match = (Get-Content -Path ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle"))) -replace('\s+', ' ') | Select-String -Pattern  $SearchString
                    
                       $temptable = select-string -Path  ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle")) -Pattern $excludeString
                     
                       if(($match.length -ne 0) -and ($temptable.Filename.Length -eq 0))
                       {
                            $Reviewlist += $item.ServerItem + "`r`n" 
                       }    
                }
            }

            
             CD  $TFSPatientBetaPathDBControlLiteFacility
            tf workspace /new /s:$tfs "4" /noprompt 
            tf workfold /s:$tfs /workspace:"4" /map $TFSPatientBetaDBControlLiteFacility  $TFSPatientBetaPathDBControlLiteFacility
            CD $TFSPatientBetaPathDBControlLiteFacility
            tf get /force /recursive 
             $TFSPath = $TFSPatientBetaDBControlLiteFacility
             $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                #Get-Content -Path $item.ServerItem.Substring($item.ServerItem.Length - ($item.ServerItem.Length - $item.ServerItem.LastIndexOf("/Care/"))+6)  -encoding UTF8 

                #if(Test-Path -Path ($item.ServerItem.Substring($item.ServerItem.Length - ($item.ServerItem.Length - $item.ServerItem.LastIndexOf("/Care/"))+6)))
                if(Test-Path -Path ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle")))
                { 
                       $match = (Get-Content -Path ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle"))) -replace('\s+', ' ') | Select-String -Pattern  $SearchString
                    
                       $temptable = select-string -Path  ("C:\AhtoAccess" + $item.ServerItem.Replace("/","\").Replace("$","\").Replace("\\","\").Replace("RevenueCycle","Revenue_Cycle")) -Pattern $excludeString
                     
                       if(($match.length -ne 0) -and ($temptable.Filename.Length -eq 0))
                       {
                            $Reviewlist += $item.ServerItem + "`r`n" 
                       }    
                }
            }

             
          
 
 # SQL JOB Changes
                
             $Reviewlist += ' SQL JOBS '+ "`r`n" 
             $TFSPath = $TFSCurrentBranchDBControlLiteFacilityAdmin
             $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                   $Reviewlist += $item.ServerItem + "`r`n" 
            }

           
             $TFSPath = $TFSCurrentBranchDBControlLiteFacilityBind
             $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                   $Reviewlist += $item.ServerItem + "`r`n" 
            }
            
             $TFSPath = $TFSCurrentBranchDBControlLiteFacilityCore
             $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                   $Reviewlist += $item.ServerItem + "`r`n" 
            }

             $TFSPath = $TFSCurrentBranchDBControlLiteFacilityHL7Stage
             $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                   $Reviewlist += $item.ServerItem + "`r`n" 
            }

             $TFSPath = $TFSCurrentBranchDBControlLiteFacilityNotificationDb
             $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                   $Reviewlist += $item.ServerItem + "`r`n" 
            }

             $TFSPath = $TFSCurrentBranchDBControlLiteFacilityStage
             $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                   $Reviewlist += $item.ServerItem + "`r`n" 
            }

              $TFSPath = $TFSCurrentBranchDBControlLiteFacilityTran
             $itemsAll = Get-TfsItemHistory  $TFSPath -Recurse -Server $tfs -Version $DateRange -IncludeItems |
                            Select -Expand "Changes" |
                            Where { ($_.ChangeType -band ([Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::delete -bor [Microsoft.TeamFoundation.VersionControl.Client.ChangeType]::Merge )) -eq 0 } |
                            Select -Expand "Item" |
                            Where { $_.ContentLength -gt 0} |
                            Where { $_.ServerItem -like '*sql*' }
                            Select -Unique ServerItem
   
            foreach($item in $itemsAll |Select -Unique ServerItem | sort-object serveritem)
            {
                   $Reviewlist += $item.ServerItem + "`r`n" 
            }

            if($Reviewlist.length -eq 12)
            {
                $Reviewlist = "No changes to review."
            }
            Write-Host $Reviewlist

            $Reviewlist | Out-File D:\PowerShellTools\ReviewSchema\Logs\log.txt

            $mailto  = "Data_Arch@accretivehealth.com"
            $mailcc  = "sawasthi1@accretivehealth.com"
            $mailfrom= "ReleaseMgtTeam@accretivehealth.com"

            #SMTP server name
            $smtpServer = "smtpr.accretivehealth.local"
		    $msg = new-object Net.Mail.MailMessage

     		#Creating SMTP server object
     		$smtp = new-object Net.Mail.SmtpClient($smtpServer)
            
            $msg.From = $mailfrom
            $msg.To.Add($mailto)
            $msg.CC.Add($mailcc)
            $msg.subject =  'Scanned TFS Branch:'+$TFSCurrentBranchDatabase+". Index changes for your review. TFS Date Range: " + $DateRange.Replace("D","").Replace("23:59:59z","").Replace("~"," to ").Replace("00:00:00Z","")
            $msg.body = "Hello Data Arch Team," + "`n" + "Please review these Tables, Indexes for the date range (" + $DateRange.Replace("D","").Replace("23:59:59z","").Replace("~"," to ").Replace("00:00:00Z","") + "). Thank you." + "`n" + "`n"  + $Reviewlist | Sort-Object

            #Sending email
            $smtp.Send($msg)
            
            exit
           
 