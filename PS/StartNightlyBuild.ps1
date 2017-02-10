$tfBuild="C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\TfsBuild.exe"
&$tfBuild start /collection:http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl /buildDefinition:RevenueCycle\UIAutomation


Write-Host "Starting nightly build" -ForegroundColor DarkGreen