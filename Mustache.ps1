# This powershell script does mustache replacements for templates  and Generate ServiceModel, RolloutSpecs, Rollout Parameters Files for ARM Templates and Shell Extensions.

# Parameter $projdir is the directory in which the solution resides and it is derived from the solution and not an user input
param (
	[Parameter(Mandatory=$true)]
	[string]$projdir
	)
# make sure all output files are UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'ASCII'

# $sgrdir is ServiceGroupRoot directory where all files will be generated like ServiceModel,RolloutSPec, RolloutParameter Files
$sgrdir = $projdir + "..\..\expressv2\ResourceProvisioning\ServiceGroupRoot"


$paramdir = $sgrdir + "\parameters"
$templatedir = $sgrdir + "\templates"
$scriptdir = $sgrdir + "\scripts"

# create the output directories
if (!(Test-Path -Path $sgrdir)) {md $sgrdir}
if (!(Test-Path -Path $paramdir)) {md $paramdir}
if (!(Test-Path -Path $templatedir)) {md $templatedir}
if (!(Test-Path -Path $scriptdir)) {md $scriptdir}

# copy the templates & scripts
robocopy .\templates $templatedir *.json
robocopy .\Scripts $scriptdir *.zip
robocopy .\ $sgrdir buildver.txt

# run mustache to generate the service model
$servpath = $sgrdir + "\ServiceModel.json"
Write-Host $servpath
$mustpath = $env:USERPROFILE + "\AppData\Roaming\npm"
$mustnode = $mustpath +"\node_modules\mustache\bin\mustache"
$parampath = $projdir + "parameters.view.json"
$servmodelpath = $projdir + "ServiceModel.mustache.json"

pushd $mustpath
# run mustache to generate the service model
dir
node $mustnode $parampath $servmodelpath  > $servpath
popd

# Please follow through Readme.MD  to refernce all properties available for each country and for steps need to be followed.
# Creates object list of countries available in parameters.view file . 
# Each country oject contains properties regions,subscription id , locations
$viewObj = Get-Content .\parameters.view.json | ConvertFrom-Json
foreach ($country in $viewObj.countries)
{
	$abbrev = $country.abbrev
	$abbrev
	$countryviewpath = $projdir + $country.name + "_view.json"
	$country.last = ""

	#Add global properties(shared secrets key vaults link , Service Principal object id, Pools list ) into the country property object
	Add-Member -InputObject $country -MemberType NoteProperty -Name myObjId -Value $viewObj.myObjId
	Add-Member -InputObject $country -MemberType NoteProperty -Name scriptSpnAppId -Value $viewObj.scriptSpnAppId
	Add-Member -InputObject $country -MemberType NoteProperty -Name scriptSpnObjId -Value $viewObj.scriptSpnObjId
	Add-Member -InputObject $country -MemberType NoteProperty -Name spnSecretLink -Value $viewObj.spnSecretLink
	Add-Member -InputObject $country -MemberType NoteProperty -Name tenantId -Value $viewObj.tenantId
	Add-Member -InputObject $country -MemberType NoteProperty -Name existKeyVaultLink -Value $viewObj.existKeyVaultLink
	Add-Member -InputObject $country -MemberType NoteProperty -Name poolSuffix1 -Value $viewObj.poolSuffix1
	Add-Member -InputObject $country -MemberType NoteProperty -Name poolSuffix2 -Value $viewObj.poolSuffix2
	$country
	# Create a temporary file to store the country property object for each country
	$country | ConvertTo-Json | Out-File $countryviewpath

	# Set the output Paths for Rollout parameters, RolloutSpec files, Shell Extension parameter files
	$armparampath = $sgrdir + "\parameters\resourceprovisioining_azuredeploy_" + $abbrev + "_parameters.json"
	$rollparampath = $sgrdir + "\parameters\resourceprovisioining_shellext_" + $abbrev + "_parameters.json"
	$rollspecpath = $sgrdir + "\RolloutSpec-ResProv-" + $abbrev + ".json"


	pushd $mustpath
	# run mustache to generate Parameter files, RolloutSpec Files, Shell extension parameter files
	$deploymustpath = $projdir + "azuredeploy.parameters.mustache.json"
	node $mustnode $countryviewpath $deploymustpath > $armparampath
	$shellmustpath = $projdir + "rolloutparameters.shellext.mustache.json"
	node $mustnode $countryviewpath $shellmustpath > $rollparampath
	$rolloutmustpath = $projdir + "rolloutspec.mustache.json"
	node $mustnode $countryviewpath $rolloutmustpath > $rollspecpath
	popd
	# delete the country property work file
	Remove-Item $countryviewpath
}

# copy buildver.txt a second time
robocopy .\ $sgrdir buildver.txt

