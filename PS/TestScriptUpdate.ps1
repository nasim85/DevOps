#$BuildNumber="2016.5.0.4"
$regex='AssemblyCompany\(\W+([a-zA-Z0-9\W]+|\w?)\W+\)'
$Company ='[assembly: AssemblyCompany("CopyrightAccretive Health, Inc. 2015")]'
$Company -replace $regex , 'AssemblyCompany("bbbbb")'

#$revNo=$BuildNumber.Substring($BuildNumber.LastIndexOf("."),($BuildNumber.Length-1))
#$revNo=$BuildNumber.Split(".",4)
#$revNo[$revNo.Count-1]
#$revNo