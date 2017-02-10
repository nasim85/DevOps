
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

#Get-Content C:\Users\300915\Desktop\Automation\PublishReport.xml

[xml] $doc=(Get-Content C:\Users\300915\Desktop\Automation\PublishReport1.xml)#| Format-Xml

#$doc.DeploymentReport.Operations.Operation|ConvertTo-Html -Head $style |Out-File C:\Test.htm

#$doc.DeploymentReport.Operations.Operation.SelectNodes('*')| ConvertTo-Html|Out-File C:\Test.htm

$table=$style +"<table><th>Operation</th><th>Object</th><th>Object Type</th>"

foreach($node in $doc.DeploymentReport.Operations.SelectNodes('*[@Name]')|Where-Object {$_.Name -in ("Drop","Create")  })
    {
    #$table +="<th>"+ $node.attributes['Name'].value+"</th>"

        $Operation= $node.attributes['Name'].value
        if($node.HasChildNodes)
        {
        
        
             foreach ($filterNode in $node.ChildNodes|Where-Object {$_.Type -notmatch "SqlSynonym|SqlFullTextIndex|SqlFullTextCatalog|SqlUser|SqlRole|SqlSchema"  }) 
                    { 
                        $table +="<tr><td>"+$Operation +"</td><td>"+$filterNode.Value +"</td><td>"+$filterNode.Type +"</td></tr>"
                    } 
                            
        }
        
    }

$table +="</table>"

#Write-Host $table

$table | Out-File C:\Test.htm


#Select-Xml -Path "C:\Users\300915\Desktop\Automation\PublishReport1.xml" -XPath "//Operation" |  Select-Object -ExpandProperty Node

#$report= Import-Clixml C:\Users\300915\Desktop\Automation\PublishReport1.xml

#[XML] $reportFile= (Get-Content C:\Users\300915\Desktop\Automation\PublishReport1.xml)| Format-Xml |ConvertTo-Html -Head $style  Out-File C:\Test.htm

#(Get-Content C:\Users\300915\Desktop\Automation\PublishReport1.xml) | Format-Xml -AttributesOnNewLine

 #$xDdoc.DeploymentReport.Operations.Operation.Item.Name | Select-Object | ConvertTo-Html|Out-File C:\Test.htm

 #Select-Xml -Path $path -XPath "//Operations"| Select-Object -ExpandProperty Node

 #$feed.rss.channel.item | format-table title,link

 #Write-Host $xDdoc.SelectNodes("/Operations")

#Write-Host $content

#Write-Host $reportFile |foreach {$_.node.InnerXML}

#Get-Service | Select-Object Status, Name, DisplayName | ConvertTo-Html -Head $style  #| Out-File C:\Test.htm

#Get-Process | ConvertTo-Html name,path,fileversion,title -title "Process Information" | Set-Content c:\test.htm

#Invoke-Expression C:\Test.htm

#Get-Help Convertto-Html -Examples
#Get-Help XML
#Get-Help select-xml -Examples



