$content =Get-Content C:\RevenueCycle\R2016.5\Care\Website\Followup\Accretive.Tasks.IDM\Properties\AssemblyInfo.cs

$CopyRightRegex = "assembly: AssemblyCopyright"

$content -match $CopyRightRegex


#Get-PSSnapin -Registered

<#
$BuildName="DB_Tran_UAT01_R2016.5_20160524528.1"
$buildNameArr= ($BuildName).split("_")
$buildString= "Build_"+$buildNameArr[$buildNameArr.Count-2]+"_"+$buildNameArr[$buildNameArr.Count-1]
$buildString
#>
<#
$content=Get-Content C:\Users\300915\Desktop\UAT01_03Tran_DB_Tran_UAT01_R2016.5_2016052062.1.sql
$DBNameString= $content | select -Last 100 | Where-Object { $_.Contains("PRINT N'The transacted portion of the database update succeeded.'") }
$content=$content.Replace($DBNameString,"Update Gold.dbversion set BuildNumber='Build20160203_1833_R2016.2',BuildDate=getdate()  `n PRINT N'The transacted portion of the database update succeeded.'")
$content | Out-File C:\Users\300915\Desktop\UAT01_03Tran_DB_Tran_UAT01_R2016.5_2016052062.1.sql
#>

<#

$csvPath= "C:\Users\300915\Desktop\RMConfig\test.csv"
#Get-Process|select 'Date', 'Type', 'Description' | Export-Csv 'C:\Users\300915\Desktop\RMTool\test.csv' -NoTypeInformation
$content= "BuildNumber, DataBase,Status, DBScript"
#$content|Select 'BuildNumber', 'DataBase','Status', 'DBScript'| Export-Csv "C:\Users\300915\Desktop\RMConfig\test.csv" -NoTypeInformation

Add-Content  -Path $csvPath -Value $content

get-date

$a1=@(1,2,3,4,5)
$b1=@(1,2,3,4,5,6)
(Compare-Object $a1 $b1).InputObject

#>

<#
$csv = "Path,Publish,Hashlist,Package`r`n"
$fso = new-object -comobject scripting.filesystemobject
$file = $fso.CreateTextFile("C:\Users\300915\Desktop\RMConfig\test.csv",$true)
$file.write($csv)
$file.close()
  #>
<#
$script="C:\Users\300915\Desktop\RMTool\Tran.sql"
#$DBNameString= Get-Content $script | select -First 100 | Where-Object { $_.Contains(":setvar DatabaseName") }
#$DBNameString
$content=':setvar DatabaseName "TranSCFL"'
$content=$content.Replace($content,':setvar DatabaseName "TranGCFL"')

$content #| Out-File "C:\Users\300915\Desktop\RMTool\TranUpdated.sql"
#>


#Get-Location

#$ServerName="AHVA2ADEVSQL01\devTest"
#$ServerName1=$ServerName -replace '\' ,'-'
#$ServerName1=$ServerName.Replace("\" ,"-")
#$ServerName.Replace("\" ,"-")
#$LogFilePathD ="$ServerName _DbName_Log.txt"
#Write-Host $ServerName1 

<#
$ApplicationPathRoot="ApplicationPathRoot"
$ComponentName ="ComponentName"

$DropLocation="$ApplicationPathRoot\$ComponentName"

$DropLocation

#>

#Add-PSSnapin SqlServerCmdletSnapin100
#Add-PSSnapin SqlServerProviderSnapin100
#Invoke-Sqlcmd -ServerInstance "AHVA2ADEVSQL01\devTest" -Query "SELECT * from  vwAhtoDialer_old ;" -ErrorAction 'Continue' -Database "Global_AhtoDialer" -OutputSqlErrors:$true
#Sqlcmd -S AHVA2APL5COR01.dev.accretivehealth.local -Q "INSERT INTO [DBProject].[dbo].[DBProjects]([Name],[active],[status]) VALUES('Name',0,'Inactive')" -d "DBProject"




<#
        function Get-BuildServer
            {
            param($serverName = $(throw 'please specify a TFS server name'))
            [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft;.TeamFoundation.Client")
            [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Client")
            $tfs = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($serverName)

            return $tfs.GetService([Microsoft.TeamFoundation.Build.Client.IBuildServer])
            }

        # SAS: Get the Build Server
        $buildserver = Get-BuildServer "http://tfs.ahtoit.net:8080/tfs/revenuecyclecoll"

        # SAS: Set the parameters (Team Project and Build Definition)
        $teamProject = "RevenueCycle"
        $buildDefinition = "DB-TestCI_NonTran_R2015.6"

        # SAS: Get the build definition
        $definition = $buildserver.GetBuildDefinition($teamProject, $buildDefinition)

        # SAS: Create the build request
        $request = $definition.CreateBuildRequest()

        # SAS: Deserialise the Process Parameter for the Build Definition
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Workflow")
        $paramValues = [Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers]::DeserializeProcessParameters($request.ProcessParameters)

        # SAS: Set the parameter(s)
        $paramValues.Item("DeployChanges") = $DeployChanges

        # SAS: Serialise the Process Parameter for the Build Definition
        $request.ProcessParameters = [Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers]::SerializeProcessParameters($paramValues)

        # SAS: Queue the build
        $buildserver.QueueBuild($request, "None") 
#>



<#

function Get-BuildDropLocation {
	param(
		[Parameter(Position=0,Mandatory=$true)] [string]$tfsLocation,
		[Parameter(Position=1,Mandatory=$true)] [string]$projectName,
		[Parameter(Position=3,Mandatory=$true)] [string]$buildDefinitionName
	)

	Add-Type -AssemblyName "Microsoft.TeamFoundation.Client, Version=10.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a, processorArchitecture=MSIL"
	Add-Type -AssemblyName "Microsoft.TeamFoundation.Build.Client, Version=10.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a, processorArchitecture=MSIL"
	$tfsUri = New-object Uri($tfsLocation)
	$teamProjectCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($tfsUri)
	$service = $teamProjectCollection.GetService([Type]"Microsoft.TeamFoundation.Build.Client.IBuildServer")
	$spec = $service.CreateBuildDetailSpec($projectName, $buildDefinitionName)

	$spec.MaxBuildsPerDefinition = 1
	$spec.QueryOrder = [Microsoft.TeamFoundation.Build.Client.BuildQueryOrder]::FinishTimeDescending
	$spec.Status = [Microsoft.TeamFoundation.Build.Client.BuildStatus]::Succeeded

	$results = $service.QueryBuilds($spec)

	if ($results.Builds.Length -eq 1) { Write-Output $results.Builds[0].DropLocation } else { Write-Error "No builds found." }

Get-Help Get-Content -Examples

}

Get-BuildDropLocation "http://tfs.ahtoit.net:8080/tfs/revenuecyclecoll" "RevenueCycle" "DB-Automation_UAT01_R2015.8"


#>


#Add-PSSnapin SqlServerCmdletSnapin100
#Add-PSSnapin SqlServerProviderSnapin100

#[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
#add-type -path "C:\Program Files (x86)\Microsoft SQL Server\120\DAC\bin\Microsoft.SqlServer.Dac.dll"

#$dacProfile = [Microsoft.SqlServer.Dac.DacProfile]::Load("C:\Users\300915\Desktop\RevenueCycle\R2015.6\Care\DB_Projects\ACH_DB_NonTran\DNN30\DNN30_CI.publish.xml")
#[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null 
#$sqlSrv = New-Object 'Microsoft.SqlServer.Management.Smo.Server' ($dacProfile.TargetConnectionString)
#$dacProfile.TargetConnectionString
#$Connection = New-Object System.Data.SQLClient.SQLConnection($dacProfile.TargetConnectionString)
#$server=$Connection.DataSource
#$Database=$dacProfile.TargetDatabaseName
#$ScriptFile="C:\Users\300915\Desktop\RevenueCycle\R2015.6\Care\DB_Projects\ACH_DB_NonTran\DailyBuildScript\PROD_01DNN30_20150819_1637.sql"
#Invoke-Sqlcmd -ServerInstance "$server" -Query "SELECT GETDATE() AS TimeOfQuery;" -ErrorAction 'Continue' -Database "$Database" -OutputSqlErrors:$true
#Invoke-Sqlcmd -ServerInstance "$server" -InputFile "$ScriptFile" -ErrorAction 'Continue' -Database "$Database" -OutputSqlErrors:$true -Verbose *>&1  |Out-Host






#$Env: TF_BUILD_BUILDDEFINITIONNAME

<#
$TFS = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
 
$FolderPath= "C:\Users\300915\Desktop\RevenueCycle\Development\PowerShellScripts\DB_Automation\UpdateNonTranDBReference.ps1"

#&$TFS Get $FolderPath /force /recursive
&$TFS checkin $FolderPath /override:"Automation:CHEKIN by powershell" /comment:"Automation:CHEKIN by powershell" /noprompt -Force

#>

#Get-Process

<#
$msbuild=[Environment]::GetFolderPath("Windows").ToString()+"\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe"
$SolPath= "C:\Users\300915\Desktop\RevenueCycle\DBAutomation\SSDP\ACH_DB_NonTran\dnn30.sln"
& $msbuild $SolPath #/t:rebuild #/P:PublishProfile=Accretive_CI

#>



<#
[void][System.Reflection.Assembly]::LoadWithPartialName("envdte.dll")
[void][System.Reflection.Assembly]::LoadWithPartialName("envdte80.dll")
[void][System.Reflection.Assembly]::LoadWithPartialName("VSLangProj.dll")
[void][System.Reflection.Assembly]::LoadWithPartialName("VSLangProj80.dll")

$envdte = [System.Runtime.InteropServices.Marshal]::GetActiveObject("VisualStudio.DTE.12.0")


    $envdte.Solution.Open($FullPathtoSolution)

    $envdte.Solution.AddFromFile($FUllPathtoNewProject1)
$envdte.Solution.AddFromFile($FUllPathtoNewProject2)
$envdte.Solution.AddFromFile($FUllPathtoNewProject3) 

    $envdte.Solution.SaveAs($FullPathtoSolution)

    foreach ($proj in $envdte.Solution.Projects)
               {
                    $proj.Kind #Prints {FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}
        $proj.Name #Prints the name of my web application project like it should
        $vsproj = [VSLangProj.VSProject]$proj.Object #this line causes the error
        $vsproj.References.AddProject($NewProject1Name)
                    $vsproj.References.AddProject($NewProject2Name)
                    $vsproj.References.AddProject($NewProject3Name)
                }



$envdte.Solution.SaveAs($FullPathtoSolution)






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
write-host $dte.FileName
$Project = ($dte.Solution.Projects | where {$_.Name -eq $project})
$ProjItems = $Project.ProjectItems
$ProjDir = [System.IO.Path]::GetDirectoryName($Project.FullName)

#>