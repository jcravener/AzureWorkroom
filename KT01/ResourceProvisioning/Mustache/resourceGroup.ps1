# This powershell script does mustache replacements for templates  and Generate ServiceModel, RolloutSpecs, Rollout Parameters Files for ARM Templates and Shell Extensions.

# Parameter $projdir is the directory in which the solution resides and it is derived from the solution and not an user input
param (
	[Parameter(Mandatory=$true)]
	[string]$projdir,
	[Parameter(Mandatory=$true)]
	[string]$subId 
	)
# make sure all output files are UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'ASCII'

# setup parameters view path
$parampath = $projdir + "\parameters.view.json"

$azcontext = Get-AzureRmContext
if( $azcontext.Subscription.Id -ne $subId )
{
	Write-Error -Message "AzureRM context not set to $subId. exiting..."
	exit
}

# Please follow through Readme.MD  to refernce all properties available for each country and for steps need to be followed.
# Creates object list of countries available in parameters.view file . 
# Each country oject contains properties regions,subscription id , locations
$viewObj = Get-Content -Path $parampath | ConvertFrom-Json

foreach ($country in $viewObj.countries)
{
	$rgname = "rg-" + $country.abbrev + "-" + $country.region1 + "-arm-tst"
	Get-AzureRmResourceGroup -ResourceGroupName $rgname -ErrorAction SilentlyContinue | Out-Null

	if(-not $?)
	{
		New-AzureRmResourceGroup -Name $rgname -Location $country.location1	
	}
	else
	{
		Write-Host -Object "Resource Group $rgname already exists."
	}
}

Get-AzureRmResourceGroup |
	? ResourceGroupName -Match '^rg.*\-arm\-tst' |
		Select-Object -Property ResourceGroupName, Location