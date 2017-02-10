# Create a function that loads our managed code into powershell

Set-Location "C:\Users\300915\Desktop\Automation\TestPowerShellTokenReplace"

$serverRoot = "/AHServiceConfig/QA/DataStore/HBase/QA01/"; # This must resolve to a particular server location

function ZooKeeperClass
{
    [string]$SourceCode =  @”
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Org.Apache.Zookeeper.Data;
using ZooKeeperNet;

namespace Accretive.ALM.ConfigurationManagement
{
    public class ZooKeeperHelper
    {

        public string GetValue(string keyName)
        {
            var zookeeper =
               new ZooKeeper(
                  // "ahvintqa01hdp01.accretivehealth.local, ahvintqa01hdp02.accretivehealth.local, ahvintqa01hdp03.accretivehealth.local",
                  "ahvintqa01hdp01.accretivehealth.local",
                  TimeSpan.FromMinutes(1), null);
    
            // Example 1 - Sync way to call ZooKeeper
            var children = zookeeper.GetChildren("/AHServiceConfig", false);

            var specificnodevalue =
               zookeeper.GetData(keyName, false, default(Stat));
    
            return Encoding.ASCII.GetString(specificnodevalue);
        }
    }
}
“@



# use the powershell 2.0 add-type cmdlet to compile the source and make it available to our powershell session

$zoolib = (get-item ZooKeeperNet.dll).fullname
[void][reflection.assembly]::LoadFrom($zoolib)

  if (-not ([System.Management.Automation.PSTypeName]'Accretive.ALM.ConfigurationManagement.ZooKeeperHelper').Type)
  {
    Add-type -TypeDefinition $SourceCode -ReferencedAssemblies $zoolib
  } else {
    Write-Host("Type already exists");
  }
}


# Load up our C# code

ZooKeeperClass

$zkclient = New-Object Accretive.ALM.ConfigurationManagement.ZooKeeperHelper

function GetParamsFromZooKeeper($xmlfile)
{
$content = (Get-Content -path $xmlfile) -join "`r`n"
$pattern = "__(\w+[\.\w+]*)__";

$mc = [regex]::matches($content, $pattern)
Write-Host $mc.count

foreach ($match in $mc)
{
  foreach ($group in $match.groups[1])
  {
      Write-Host "Replacing $group";
      #$bar = $zkclient.GetValue($("/AHServiceConfig/QA/DataStore/HBase/QA01/ + $($group.value)")); # "/AHServiceConfig/QA/DataStore/HBase/QA01/hadoop.security.authentication"
      try
      {
         # Get a value from ZooKeeper
         $zooKeeperValue = $zkclient.GetValue("$serverRoot$group"); # Will be: "/AHServiceConfig/QA/DataStore/HBase/QA01/hadoop.security.authentication"
         if ($zooKeeperValue) 
         {
              $content = [regex]::replace($content, "__" + $group + "__", $zooKeeperValue);
         }
      }
      catch
      {
          Write-Host "Not found $group";
          continue;
      }
  }
}

Set-Content -path $xmlfile".temp" $content

# Write-Host $content;
}

function XmlDocTransform($xml, $xdt)
{
      $scriptpath = $PSScriptRoot + "\"
      $xmlpath = $scriptpath + $xml
      $xdtpath = $scriptpath + $xdt

      if (!($xmlpath) -or !(Test-Path -path ($xmlpath) -PathType Leaf)) {
         throw "Base file not found. $xmlpath";
      }

      if (!($xdtpath) -or !(Test-Path -path ($xdtpath) -PathType Leaf)) {
         throw "Transform file not found. $xdtpath";
      }

      $targetXmlPath = (Split-Path -Path ($xmlpath) -Leaf);

      $targetXmlPath = (Join-Path -Path (Join-Path -Path $scriptpath -ChildPath Artifacts) -ChildPath $targetXmlPath);

      Write-Host $targetXmlPath;

      $xmllib = (get-item Microsoft.Web.XmlTransform.dll).fullname
      Add-Type -LiteralPath $xmllib
      # Add-Type -LiteralPath "$PSScriptRoot\Microsoft.Web.XmlTransform.dll"

      # __(\w+[\.\w+]*)__

      $xmldoc = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument;
      $xmldoc.PreserveWhitespace = $true
      $xmldoc.Load($xmlpath);

      GetParamsFromZooKeeper($xdtpath);

      $xdtpath = $xdtpath + ".temp";

      $transf = New-Object Microsoft.Web.XmlTransform.XmlTransformation($xdtpath);
      if ($transf.Apply($xmldoc) -eq $false)
      {
          throw "Transformation failed."
      }
      $xmldoc.Save($targetXmlPath);

      Write-Host "Transformation succeeded" -ForegroundColor Green
  }

XmlDocTransform "App.config" "App.Release.config";