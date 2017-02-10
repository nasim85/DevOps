#============================================================
# Restore a Database using PowerShell and SQL Server SMO
# Restore to the same database, overwrite existing db
# 
#============================================================
 
#param([string]$RootPath="",[string]$DropLocation="",[bool]$DeployChanges=$True)


#clear screen
#cls
 
#load assemblies
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
#Need SmoExtended for backup
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null


#get backup file
#you can also use PowerShell to query the last backup file based on the timestamp
#I'll save that enhancement for later
$backupFile = "E:\Backups\TranSCFL.bak"
 
#we will query the db name from the backup file later
 
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") "AHVA2APL5TRN01.dev.accretivehealth.local"
$backupDevice = New-Object ("Microsoft.SqlServer.Management.Smo.BackupDeviceItem") ($backupFile, "File")
$smoRestore = new-object("Microsoft.SqlServer.Management.Smo.Restore")
 
#settings for restore
$smoRestore.NoRecovery = $false;
$smoRestore.ReplaceDatabase = $true;
$smoRestore.Action = "Database"
 
#show every 10% progress
$smoRestore.PercentCompleteNotification = 10;
 
$smoRestore.Devices.Add($backupDevice)
 
#read db name from the backup file's backup header
$smoRestoreDetails = $smoRestore.ReadBackupHeader($server)
 
#display database name
"Database Name from Backup Header : " + $smoRestoreDetails.Rows[0]["DatabaseName"]
 
$smoRestore.Database = $smoRestoreDetails.Rows[0]["DatabaseName"]

#$smoRestoreDetails |Select-Object 
 
#restore 
$smoRestore.SqlRestore($server)
 
"Done"
