# Script is taken from https://ye110wbeard.wordpress.com/2012/05/21/three-ways-to-pass-credentials-in-a-powershell-script/

$MyCredentials=GET-CREDENTIAL –Credential "ACCRETIVEHEALTH\aschmidt" | EXPORT-CLIXML C:\Chef\SecureCredentials.xml