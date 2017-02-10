#get-help Split-Path -Examples
#get-help Split-String -Examples






$string='DB-DBReference_DBAutomation_SSDT'
$strarr= $string.Split('_',2)

$strarr[1].ToString()

$strarr.Count



$BuildName= ${$Env:TF_BUILD_BUILDDEFINITIONNAME}
$StrList= $string.split('_')
$BranchPath="$/RevenueCycle"

for($i=1; $i -le $StrList.Count ; $i++)
{
$BranchPath=$BranchPath+"/"+ $StrList[$i]
}

$BranchPath


Get-Module -ListAvailable