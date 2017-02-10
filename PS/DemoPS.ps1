

   $FileContaints =get-content "C:\Users\300915\Desktop\RevenueCycle\R2015.3\Care\DB_Projects\ACH_DB_Tran\Bin\TranDemo.sql"

   $ObjEx=' $FileContaints.GetValue($i+4) -match "DROP USER")'

     for ($i=0; $i -lt $FileContaints.Count; $i++)
        { 
         if (($FileContaints.GetValue($i) -match "PRINT N'Dropping" -and $FileContaints.GetValue($i+4) -match "DROP USER|DROP ROLE"  ))
         {
            Write-Host "DROP USER,DROP SYNONYM"
         }
        }




<#
#get-help Get-Command  -detailed

Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100

cls
    $ServerName ="AHV-A2ACORTST02"
    $DbName="CI_ACCRETIVE"
    $ScriptFile ="C:\Users\300915\Desktop\Automation\CI_14Accretive_20140528_2043.sql"
    $DeployVarArray = ("DatabaseName=CI_Accretive")
    $LogFilePath ="C:\Users\300915\Desktop\Automation\TESTLOG_OutPut.txt"


    #Get-Content -Path $ScriptFile -ErrorAction Continue -Verbose -WarningAction Continue

 
    #Invoke-Sqlcmd -ServerInstance $ServerName -Database $DbName -Query "select getdate()"
    $strmsg= Invoke-Sqlcmd -Variable $DeployVarArray -OutputSqlErrors:$True -ServerInstance $ServerName -Database $DbName -InputFile $ScriptFile -verbose 4>&1 | Out-File -FilePath $LogFilePath -Append 
    #$strmsg= Invoke-Sqlcmd -SuppressProviderContextWarning -ServerInstance $ServerName -Database $DbName -InputFile $ScriptFile  -verbose 4>&1| export-csv -path "C:\Users\300915\Desktop\Automation\TESTLOG_OutPut.csv"
    #$strmsg= Invoke-Sqlcmd -ServerInstance $ServerName -Database $DbName -InputFile $ScriptFile -verbose 4> $LogFilePath
    # Variable $DeployVarArray -Verbose |Out-File -FilePath $LogFilePath -Append 
    #| select-object -expandproperty Script | invoke-expression

    #Write-Host $strmsg
    # LogDatabaseLogs -SummaryTxt $strmsg -servername $ServerName -DbName $DbName


#>