$MyCredentials=IMPORT-CLIXML C:\Chef\SecureCredentials.xml
$runList='recipe[IS::installpackage]'

Write-Host $runList

knife winrm 'name:ahv-phsdevweb01' chef-client --winrm-user $MyCredentials.UserName --winrm-password $MyCredentials.GetNetworkCredential().password -r '$runList'

