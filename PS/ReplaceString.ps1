
param([string]$FolderPath="C:\Logs") 

foreach ($file in (Get-ChildItem $FolderPath))
{
    $Data= Get-Content $file.FullName

    $Data=$Data.Replace("`n","`r`n")

    $Data | Out-File $file.FullName -Force
}


