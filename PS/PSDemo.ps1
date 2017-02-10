#Variable ,looping, Function

$LogFilePath ="C:\Users\300915\Desktop\Automation\logs.txt"

#Region
@(

Function LogFileGen([string] $SummaryTxt )
 {  

    Try
    {
        If (!(Test-Path -Path $LogFilePath))
        {
            New-Item -ItemType "directory" -Path $LogFilePath | Out-Null
        }
        else
        {
        }
    }
    Catch
    {
        #LogFileGen -SummaryTxt "Creating Log Folder : "$error
    }


        Write-Host $SummaryTxt
        $SummaryTxt +" Time : "+((Get-Date).ToString('yyyy,MM,dd hh:mm:ss')) |Out-File -FilePath $LogFilePath -Append 
  }
)



LogFileGen 'Hi PS'

$fileData= Get-Content $LogFilePath




 foreach ($Data in $fileData)
    {

        Write-Host $Data

    }

