######### Web builds test ############
$vstest="C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe"
$dll="C:\Users\300915\Desktop\RevenueCycle\Development\UITest\AH_Automation_RCM\AH_Automation\Accretive_PRJ_Patient\bin\Debug\Accretive_PRJ_Patient.dll"
&$vstest $dll /TestCaseFilter:FullyQualifiedName='Accretive_PRJ_Patient.AH_Critical.AH_Critical_Login'

TestModule=Sanity


###### MTM #############

$tcm= "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\tcm.exe"
#&$tcm configs /list /collection:http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl /teamproject:RevenueCycle
#&$tcm plans /list /collection:http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl /teamproject:RevenueCycle
#&$tcm suites /list /planid:43184 /collection:http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl /teamproject:RevenueCycle
#&$tcm testenvironments /list /collection:http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl /teamproject:RevenueCycle 
#&$tcm run /create /title:"F_Log_001: Verify that end user is able to login into application" /planid:43184 /suiteid:43197 /configid:5  /testenvironment:"RevenueCycle.0.phlvalmrd01" /collection:http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl /teamproject:RevenueCycle
#/settingsname:"<Name of your automated test settings>"
