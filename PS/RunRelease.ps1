#$Rel="C:\Program Files (x86)\Microsoft Visual Studio 14.0\Release Management\Client\bin\ReleaseManagementBuild.exe"
$Rel="C:\Program Files (x86)\Microsoft Visual Studio 12.0\Release Management\bin\ReleaseManagementBuild.exe"


&$Rel release -tfs "http://tfs.ahtoit.net:8080/tfs//RevenueCycleColl" -tp "RevenueCycle" -bd "RM_R2016.5_UAT03_Nightly" -bn "RM_R2016.5_UAT03_Nightly" -ts "RCM-INT"
#&$Rel release -tfs "http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl" -tp "RevenueCycle" -bd "DB-RM-Tran-R2016.4" -bn "DB-RM-Tran-R2016.4_20160418.1" -ts "RCM-INT"
#&$Rel release -tfs "http://tfs.ahtoit.net:8080/tfs/RevenueCycleColl" -tp "RevenueCycle" -bd "RCMWEBReleasePOC" -bn "Web.044" -ts "RCM-INT"
#&$Rel release -rt "vNext-DB-Tran-CI" -pl "\\ahvtfsdv01rmt01\Drop\DB-RM-Tran-R2016.4\DB-RM-Tran-R2016.4_20160418.1" -ts "RCM-INT"



