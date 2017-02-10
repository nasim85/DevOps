 $TFS = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 11.0\Common7\IDE\tf.exe"

$COMPUTERNAME=$env:COMPUTERNAME
$USERNAME=$env:USERNAME


$WS=&$TFS workspaces /owner:$USERNAME /computer:* /server:http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl #| Select-Object -Property workspace
$ws | Select-String -Pattern $USERNAME
 

 #$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE"
 #$workapce= tf.exe  workspaces /s:http://ahv-dv1tfsapp01:8080/tfs/revenuecyclecoll 

#Write-Host $wsVlues | Format-Table -AutoSize

#Foreach ($dtr in $wsVlues)
#{
#  Write-Host $dtr.Workspace
#}




# Select-Object -First 1

#foreach($wi in $wsVlues)
#{
#    writ-host $wi
#}
#$OLDCOMPUTERNAME=$wsVlues.Fields["Computer"].Value;



#Write-Host $OLDCOMPUTERNAME

#&$TFS workspaces /owner:300915 /computer:* /server:http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl

#&$TFS workspaces /owner:$USERNAME  /computer:$COMPUTERNAME /collection:"http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl" /updateComputerName:


