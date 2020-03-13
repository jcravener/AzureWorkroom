

# Parameter $projdir is the directory in which the solution resides and it is derived from the solution and not an user input
param (
	[Parameter(Mandatory=$true)]
	[string]$projdir
	)

# setup mustache node path
$mustpath = $projdir + '\..\..\..\mustache'
$mustnode = $mustpath +"\node_modules\mustache\bin\mustache"

# setup deployment mustache file path
$deplymustfile = $projdir + '\deployment.mustache.json'
# setup parameters view path
$parampath = $projdir + "\parameters.view.json"


# run mustache on deployment mustache file
[string]$john = node $mustnode $parampath  $deplymustfile

# create valid JSON primitive 
$john = '{ "countries": [ ' + $john.Substring(0,$john.Length-1) + ' ] }'
$depObj = $john | ConvertFrom-Json

foreach ($country in $depObj.countries)
{
	$n = $country.abbrev
	$rgn = $country.ResourceGroupName
	$tpf = $country.RootPath + $country.ParamPath + $country.ParamFile
	$tf = $country.RootPath + $country.TemplatePath + $country.TemplateFile
	
	New-Object -TypeName psobject -Property @{'Country' = $n; 'Commandline' = "New-AzureRmResourceGroupDeployment -Name $n -ResourceGroupName $rgn -TemplateParameterFile $tpf -TemplateFile $tf"}
}
