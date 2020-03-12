# This powershell script does mustache replacements for templates  and Generate ServiceModel, RolloutSpecs, Rollout Parameters Files for ARM Templates and Shell Extensions.

# Parameter $projdir is the directory in which the solution resides and it is derived from the solution and not an user input
param (
	[Parameter(Mandatory=$true)]
	[string]$projdir
	)
# make sure all output files are UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'ASCII'

# $sgrdir is ServiceGroupRoot directory where all files will be generated like ServiceModel,RolloutSPec, RolloutParameter Files
$sgrdir = $projdir + "\..\..\ServiceGroupRoot"

$paramdir = $sgrdir + "\parameters"
$templatedir = $sgrdir + "\templates"

# create the output directories
if (!(Test-Path -Path $sgrdir)) {md $sgrdir}
if (!(Test-Path -Path $paramdir)) {md $paramdir}
if (!(Test-Path -Path $templatedir)) {md $templatedir}

# copy the templates & scripts
robocopy .\templates $templatedir *.json
robocopy .\ $sgrdir buildver.txt

# setup mustache node path
$mustpath = $projdir + '\..\..\..\mustache'
$mustnode = $mustpath +"\node_modules\mustache\bin\mustache"

# setup parameters view path
$parampath = $projdir + "\parameters.view.json"

# Please follow through Readme.MD  to refernce all properties available for each country and for steps need to be followed.
# Creates object list of countries available in parameters.view file . 
# Each country oject contains properties regions,subscription id , locations
$viewObj = Get-Content -Path $parampath | ConvertFrom-Json
$viewObj
exit

foreach ($country in $viewObj.countries)
{
	$abbrev = $country.abbrev
	$abbrev
	$countryviewpath = $projdir + $country.name + "_view.json"
	$country.last = ""

	$country
	# Create a temporary file to store the country property object for each country
	$country | ConvertTo-Json | Out-File $countryviewpath

	# Set the output Paths for Parameters files
	$armparampath = $sgrdir + "\parameters\resourceprovisioining_azuredeploy_" + $abbrev + "_parameters.json"


	pushd $mustpath
	# run mustache to generate Parameters files
	$deploymustpath = $projdir + "azuredeploy.parameters.mustache.json"
	node $mustnode $countryviewpath $deploymustpath > $armparampath

	popd
	# delete the country property work file
	Remove-Item $countryviewpath
}

# copy buildver.txt a second time
robocopy .\ $sgrdir buildver.txt

