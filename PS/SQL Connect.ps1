CD "C:\Users\300915\Desktop\Automation"
$RestoreScript=".\SQL_restore.psm1"

Import-Module $RestoreScript

restoresql

#get-help invoke-expression -full


$dataSource = “”
$user =""
$pwd = ""
$database = “”

$connectionString = "Server=$dataSource;uid=$user; pwd=$pwd;Database=$database;Integrated Security=True;"

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString

$connection.Open()

$query = “SELECT * FROM EmployeeMaster”

$command = $connection.CreateCommand()

$command.CommandText = $query

$result = $command.ExecuteReader()
$table = new-object “System.Data.DataTable”
$table.Load($result)
$format = @{Expression={$_.Id};Label=”User Id”;width=10},@{Expression={$_.Name};Label=”Identified Swede”; width=30}


$table  |  Out-File C:\swedes.txt

$connection.Close()
