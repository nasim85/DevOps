#Author: Tomasz Subik http://tsubik.com
#Date: 2014-05-27
#License: MIT
 
Param(
    [parameter(Mandatory=$false)]
    [alias("n")]
    $name = [System.Guid]::NewGuid().ToString(),
    [parameter(Mandatory=$false)]
    [alias("p")]
    $project = "Tran",
	[parameter(Mandatory=$false)]
    [alias("of")]
    [switch]$onlyfile = $false
	
)
 
Write-Host '######## Generating migration script ##############'
$dte = [System.Runtime.InteropServices.Marshal]::GetActiveObject("VisualStudio.DTE.12.0") 
$dte.Solution.Open("C:\Users\300915\Desktop\RevenueCycle\DBAutomation\SSDP\ACH_DB_Tran\ACH_DB_Tran.sln")
$Project = ($dte.Solution.Projects | where {$_.Name -eq $project})
$ProjItems = $Project.ProjectItems
$ProjDir = [System.IO.Path]::GetDirectoryName($Project.FullName)
 
$ProjMigrationsUpItems = ((($ProjItems | where {$_.Name -eq "Scripts"}).ProjectItems | where {$_.Name -eq "Migrations"}).ProjectItems | where {$_.Name -eq "up"}).ProjectItems
 
if(!$onlyfile){
	
	Write-Host "Opening schema compare..."
 
	$scmpFileName = $ProjDir + "\TranCare05.scmp"
 
	$dte.ExecuteCommand("File.OpenFile",$scmpFileName )
 
	Write-Host "Comparing items..."
	$dte.ExecuteCommand("SQL.SSDTSchemaCompareCompare")
 
	$done = $false
	
	do{
		try
		{
			$dte.ExecuteCommand("SQL.SSDTSchemaCompareGenerateScript")
			$done = $true
		}
		catch	
		{
			#uncomment to se
			#$error[0]
			Start-Sleep -s 2
		}
	}
	until($done)
	Write-Host "Generating comparison script..."
 
	#wait unit generating script finish
	do{
		Start-Sleep -s 1
	}
	until($dte.ActiveDocument.FullName.Contains('publish.sql'))
 
	Write-Host "Comparison script generated"
}
 
$migrationDir = $ProjDir +"\Scripts\Migrations\up"
$scriptFileName = $migrationDir +"\" + [System.DateTime]::Now.ToString("yyyyMMddhhmmss")+"_"+$name+".sql"
 
if(!$onlyfile)
{
	$dte.ActiveDocument.Save($scriptFileName)
}
else{
	New-Item $scriptFileName -type file
}
 
Write-Host "File saved as " + $scriptFileName
 
$addedScriptProjectItem = $ProjMigrationsUpItems.AddFromFile($scriptFileName)
#0 build action none
$addedScriptProjectItem.Properties.Item("BuildAction").Value = "0"
 
$dte.ExecuteCommand("File.OpenFile","ProjToDbMigrations.scmp")
$dte.ExecuteCommand("File.Close")
 
Write-Host '######## Generating migration script ends ##############'