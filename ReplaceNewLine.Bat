@ECHO OFF
SET /P fPath=Please enter Folder path: 
PowerShell.exe -Command "& ReplaceString.ps1 -FolderPath %fPath%"
SET /P fPath=Press enter to exit: 

