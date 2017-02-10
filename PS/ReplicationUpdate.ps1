param([string]$ServerName="",[string]$DbName="",[string]$ObjectName="",[string]$operation="Delete")

$ServerName="AHVA2APL5COR01.dev.accretivehealth.local"
$DbName="Accretive"
$SqlScript="select 1"

#$result=Sqlcmd -b -E -S "$ServerName" -i "$ScriptFile" -d "$DbName"
$result=Sqlcmd -b -E -S "$ServerName" -d "$DbName" -Q "$SqlScript"

$result

#SQLCMD /L