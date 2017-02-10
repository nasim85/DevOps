write-verbose -verbose "Build Definition: $buildDefinition"
write-verbose -verbose "Build ENV: $ENV"
write-verbose -verbose "DeployChanges: $DeployChanges"
write-verbose -verbose  $Env:TF_BUILD_BUILDNUMBER

$LogPath="logs"
$LogFilePath="$LogPath\RM_Powershell_Log.txt"

write-verbose -verbose "Log File Path: $LogFilePath"

$psloc=Get-Location 

write-verbose -verbose $psloc



write-verbose -verbose "Build Definition: $buildDefinition"

#$ApplicationPathRoot

# Function for loging events and exceptions ####################################
 Function LogFileGen([string] $SummaryTxt )
 {  
        #Write-Host $SummaryTxt
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

Try{

        function Get-BuildServer
            {
            param($serverName = $(throw 'please specify a TFS server name'))
            [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client")
            [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Client")
            $tfs = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($serverName)

            return $tfs.GetService([Microsoft.TeamFoundation.Build.Client.IBuildServer])
            }

        # SAS: Get the Build Server
        $buildserver = Get-BuildServer "http://tfs.ahtoit.net:8080/tfs/revenuecyclecoll"

        # SAS: Set the parameters (Team Project and Build Definition)
        $teamProject = "RevenueCycle"
        $buildDefinition = $buildDefinition

        # SAS: Get the build definition
        $definition = $buildserver.GetBuildDefinition($teamProject, $buildDefinition)

        # SAS: Create the build request
        $request = $definition.CreateBuildRequest()

        # SAS: Deserialise the Process Parameter for the Build Definition
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Workflow")
        $paramValues = [Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers]::DeserializeProcessParameters($request.ProcessParameters)

        # SAS: Set the parameter(s)
        $isDeploy=$false
        if($DeployChanges -eq "1")
        {
        $isDeploy=$True
        }
        $paramValues.Item("DeployChanges") = $isDeploy

        # SAS: Serialise the Process Parameter for the Build Definition
        $request.ProcessParameters = [Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers]::SerializeProcessParameters($paramValues)

        # SAS: Queue the build
        $buildserver.QueueBuild($request, "None") 
  }
Catch
{
   LogFileGen -SummaryTxt $_.Exception.ToString()
}





