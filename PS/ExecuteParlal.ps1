#requires -version 3.0

#assume SQLPS module is installed (which comes with sql server 2012)
#Import-Module sqlps -DisableNameChecking;
set-location c:
#create a workflow to run one script against multiple sql instances
WorkFlow Run-PSQL2 #PSQL means Parallel SQL
{
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ServerInstance,  # string array to hold multiple sql instances

        [Parameter(Mandatory=$false)]
        [string]$Database,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath # filepath to the t-sql script to be run
    )

    foreach -parallel ($s in $ServerInstance)
    { 
#invoke-sqlcmd -ServerInstance $s -Database $Database -InputFile $FilePath -querytimeout 60000;  
Sqlcmd -b -E -S "$s" -i "$FilePath" -d "$Database"
   

}
} #Run-PSQL2
Run-PSQL2 -ServerInstance 'ahva2apocsql01.extapp.local', 'ahva2apocsql02.extapp.local' -Database master -FilePath 'c:\temp\a.sql';
