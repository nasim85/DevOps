 $ReportFile="C:\Users\300915\Desktop\Scripts\ACH_DB_All\DailyBuildScript\CI_01_Global_FCC_PreRegistration_DB_NonTran_CI_R2016.6_20161123359.1.sql.xml"

                  [xml] $doc=(Get-Content $ReportFile)
                    foreach($node in $doc.DeploymentReport.Operations.SelectNodes('*[@Name]')|Where-Object {$_.Name -in ("Drop","Alter","TableRebuild")  })
                        {

                            $Operation= $node.attributes['Name'].value
                            if($node.HasChildNodes)
                            {
        
        
                                 #foreach ($filterNode in $node.ChildNodes|Where-Object {$_.Type -notmatch "SqlSynonym|SqlFullTextIndex|SqlFullTextCatalog|SqlUser|SqlRole|SqlSchema|SqlStatistic"  }) 
                                 foreach ($filterNode in $node.ChildNodes|Where-Object {$_.Type -match "SqlTable|SqlView|SqlProcedure|SqlScalarFunction|SqlMultiStatementTableValuedFunction|SqlInlineTableValuedFunction"}) 
                                        { 
                                            $Operation +":-"+$filterNode.Value +" Type:-"+$filterNode.Type
                                        } 
                            
                            }
        
                        }


           