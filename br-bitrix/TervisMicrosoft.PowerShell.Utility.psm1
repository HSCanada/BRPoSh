function ConvertFrom-StringUsingRegexCaptureGroup {
    param (        
        [Parameter(Mandatory,ParameterSetName="Regex")][Regex]$Regex,
        [Parameter(Mandatory,ParameterSetName="TemplateFile")]$TemplateFile,
        [Parameter(Mandatory,ValueFromPipeline)]$Content
    )
    begin {
        if($TemplateFile) {
            [Regex]$Regex = Get-Content -Path $TemplateFile | Out-String
        }
    }
    process {
        $Match = $Regex.Match($Content)
        $Object = [pscustomobject]@{} 
        
        foreach ($GroupName in $Regex.GetGroupNames() | select -Skip 1) {
            $Object | 
            Add-Member -MemberType NoteProperty -Name $GroupName -Value $Match.Groups[$GroupName].Value 
        }
        $Object
    }
}

function Compare-ObjectAllProperties {
    param (
        [Parameter(Mandatory)]$ReferenceObject,
        [Parameter(Mandatory)]$DifferenceObject,
        [Switch]$IncludeEqual
    )
    
    $ReferenceObjectPropertyNames = $ReferenceObject |
    Get-PropertyName

    $ReferenceObjectPropertyNames = $DifferenceObject |
    Get-PropertyName

    $Properties = ($ReferenceObjectPropertyNames + $DifferenceObject) |
    Sort-Object -Unique

    Compare-Object -ReferenceObject $ReferenceObject -DifferenceObject $DifferenceObject -Property $Properties -IncludeEqual:$IncludeEqual
}

function ConvertTo-HashTable {
    #Inspired by http://stackoverflow.com/questions/3740128/pscustomobject-to-hashtable
    param(
        [Parameter(ValueFromPipeline)]$Object,
        [Switch]$Ordered
    )
    process {
        $HashTable = if ($Ordered) { [ordered]@{} } else { @{} }
        
        $Object.psobject.properties |
        Where-Object {$_} |
        ForEach-Object { $HashTable[$_.Name] = $_.Value }

        $HashTable
    }
}

function Split-HashTable {
    param (
        [Parameter(ValueFromPipeline)]$HashTable
    )
    process {
        ForEach ($Key in $HashTable.Keys) {
            @{ $Key = $HashTable[$Key] }
        }
    }
}

function ConvertTo-Variable {
    param (
        [Parameter(ValueFromPipeline)][HashTable]$HashTableToConvert
    )
    process {
        foreach ($Key in $HashTableToConvert.Keys) {
            New-Variable -Name $Key -Value $HashTableToConvert[$Key] -Force -Scope 1
        }
    }
}

function Get-Hash {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]$String,
        [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512")]
        [Parameter(Mandatory)]
        $HashFunction
    )
    begin {
        $HashCryptoServiceProvider = new-object -TypeName System.Security.Cryptography.$($HashFunction)CryptoServiceProvider
        $UTF8 = new-object -TypeName System.Text.UTF8Encoding
    }
    process {  
        [System.BitConverter]::ToString(
            $HashCryptoServiceProvider.ComputeHash(
                $UTF8.GetBytes($String)
            )
        ).replace("-","")
    }
}

function New-HashTableIndex {
	param (
        [Parameter(Mandatory,ValueFromPipeline)]$InputObject,
		[Parameter(Mandatory)]$PropertyToIndex
    )
    begin {
        $HashTable = @{}
    }
    process {
        try {
			$InputObject.$PropertyToIndex |
			ForEach-Object -Process {
				$HashTable.Add($_, $InputObject)
			}
        }
        catch {
            Write-Warning "$($InputObject.$PropertyToIndex) could not be added to the index."
        }
    }
    end {
        $HashTable
    }
}

function ConvertTo-PSCustomObjectStanza {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]$Object
    )
    begin {
        $Array = @()
    }
    process {
        $OFSBeforeFunctionCall = $OFS
        $OFS = ""
        $PropertyNames = $Object | Get-PropertyName
        
        $Array += @"
[PSCustomObject][Ordered]@{
$(
    foreach ($Property in $PropertyNames) {
        $Value = $($Object.$Property)
        if ($Value) {
            "    $Property = $(if ($Value -is [String]) {'"' + $Value + '"'} else {$Value})`r`n"
        }
    }
)}
"@
    $OFS = $OFSBeforeFunctionCall
    }
    end {
        $Array -join ",`r`n"
    }
}

function Remove-HashtableKeysWithEmptyOrNullValues {
    param (
        [Parameter(ValueFromPipeline,Mandatory)]
        [Hashtable]$Hashtable
    )
    process {
        $NewHashtable = @{}
        foreach ($Key in $Hashtable.Keys) {
            if (($Hashtable.$Key -ne $null) -and ($Hashtable.$Key -ne "")) {
                $NewHashtable += @{$Key = $Hashtable.$Key}
            }
        }
        $NewHashtable
    }
}

filter Split-String {
    param (
		$SplitParameter
	)
	$_ -split $SplitParameter
}

filter ConvertTo-Generic {
    param (
		$As
	)
	$_ -as $As
}

function ConvertFrom-PSBoundParameters {
    param (
        [Parameter(ValueFromPipeline)]$ValueFromPipeline,
        $Property = "*", #Work arond for bug in Select-Object that doesn't support -ExcludeProperty without -Property
        $ExcludeProperty,
        [Switch]$AsHashTable
    )
    process {
        $PropertiesToInclude = if ($Property -eq "*" -or $Property -contains "*") { 
            $Property
        } else {
            $Property | Where-Object {$_ -in $ValueFromPipeline.Keys} 
        }
        
        if ($PropertiesToInclude) {
            $Object = [pscustomobject]([ordered]@{}+$ValueFromPipeline) |
            Select-Object -Property $PropertiesToInclude -ExcludeProperty $ExcludeProperty |
            Where-Object {$_.psobject.Properties.name -ne "*"} # There is a bug in PowerShell <v6 that returns a property named * when all the properites of the object are excluded
            #https://github.com/PowerShell/PowerShell/issues/2351
            
            #In cases where we get back a property named * along with other properties, remove * and leave the others
            if ($Object) {$Object.PSObject.Properties.Remove("*")}
        }

        if ($AsHashTable) {
            $Object | ConvertTo-HashTable -Ordered
        } else {
            $Object
        }
    }
}

function New-TemporaryDirectory {
	param (
		[ValidateSet("System")]$TemporaryFolderType
	)
	$GUID = New-Guid | Select-Object -ExpandProperty GUID
    $TemporaryFolderRoot = if ($TemporaryFolderType -eq "System") {
		"C:\windows\temp"
	}

	"$TemporaryFolderRoot\$Guid"
}

function Invoke-FileDownload {
    param (
        [Parameter(Mandatory)]$URI,
		[Parameter(Mandatory)]$OutFile,
		[Switch]$AsThreadJob,
		[Switch]$Force
    )
    process {
        if (-not $Force -and (Test-Path $OutFile)) {
            $Response = Invoke-WebRequest -UseBasicParsing -Uri $URI -Method Head
            $ContentLength = $Response.Headers."Content-Length"
            $Length = Get-Item -Path $OutFile | Select-Object -ExpandProperty Length

            if ($Length -eq $ContentLength) {
				return
            }
        } 

		if (-not $AsThreadJob) {
			Invoke-WebRequest -UseBasicParsing -Uri $URI -OutFile $OutFile
		} else {
			Start-ThreadJob -ArgumentList @($URI,$OutFile) -ScriptBlock {
				param ($URI, $OutFile)
				$ProgressPreference = "SilentlyContinue"
				Invoke-WebRequest -UseBasicParsing -Uri $URI -OutFile $OutFile
			}
		}
    }
}

function Get-GuidFromString {
    param (
		[Parameter(Mandatory,ValueFromPipeline)]$InputString,
		[Switch]$IncludeBraces
    )
    process {
        $GUID = $InputString | 
        ConvertFrom-StringUsingRegexCaptureGroup -Regex "(?<GUID>\w{8}-?\w{4}-?\w{4}-?\w{4}-?\w{12}?)" |
		Select-Object -ExpandProperty GUID

		if (-not $IncludeBraces) {
			$GUID
		} else {
			"{$GUID}"
		}
    }
}

#https://github.com/lazywinadmin/PowerShell/blob/master/TOOL-Remove-PSObjectEmptyOrNullProperty/Remove-PSObjectEmptyOrNullProperty.ps1
function Remove-PSObjectEmptyOrNullProperty {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]$PSObject
    )
    process {
        $PSObject.psobject.Properties |
		Where-Object { -not $_.value -and $_.value -ne $false} |
		ForEach-Object {
			$PsObject.psobject.Properties.Remove($_.name)
        }
        $PSObject
    }
}

#https://github.com/beatcracker/Powershell-Misc/blob/master/New-DynamicParameter.ps1
<#
.SYNOPSIS
	Helper function to simplify creating dynamic parameters

.DESCRIPTION
	Helper function to simplify creating dynamic parameters.

	Example use cases:
		Include parameters only if your environment dictates it
		Include parameters depending on the value of a user-specified parameter
		Provide tab completion and intellisense for parameters, depending on the environment

	Please keep in mind that all dynamic parameters you create, will not have corresponding variables created.
		Use New-DynamicParameter with 'CreateVariables' switch in your main code block,
		('Process' for advanced functions) to create those variables.
		Alternatively, manually reference $PSBoundParameters for the dynamic parameter value.

	This function has two operating modes:

	1. All dynamic parameters created in one pass using pipeline input to the function. This mode allows to create dynamic parameters en masse,
	with one function call. There is no need to create and maintain custom RuntimeDefinedParameterDictionary.

	2. Dynamic parameters are created by separate function calls and added to the RuntimeDefinedParameterDictionary you created beforehand.
	Then you output this RuntimeDefinedParameterDictionary to the pipeline. This allows more fine-grained control of the dynamic parameters,
	with custom conditions and so on.

.NOTES
	Credits to jrich523 and ramblingcookiemonster for their initial code and inspiration:
		https://github.com/RamblingCookieMonster/PowerShell/blob/master/New-DynamicParam.ps1
		http://ramblingcookiemonster.wordpress.com/2014/11/27/quick-hits-credentials-and-dynamic-parameters/
		http://jrich523.wordpress.com/2013/05/30/powershell-simple-way-to-add-dynamic-parameters-to-advanced-function/

	Credit to BM for alias and type parameters and their handling

.PARAMETER Name
	Name of the dynamic parameter

.PARAMETER Type
	Type for the dynamic parameter.  Default is string

.PARAMETER Alias
	If specified, one or more aliases to assign to the dynamic parameter

.PARAMETER Mandatory
	If specified, set the Mandatory attribute for this dynamic parameter

.PARAMETER Position
	If specified, set the Position attribute for this dynamic parameter

.PARAMETER HelpMessage
	If specified, set the HelpMessage for this dynamic parameter

.PARAMETER DontShow
	If specified, set the DontShow for this dynamic parameter.
	This is the new PowerShell 4.0 attribute that hides parameter from tab-completion.
	http://www.powershellmagazine.com/2013/07/29/pstip-hiding-parameters-from-tab-completion/

.PARAMETER ValueFromPipeline
	If specified, set the ValueFromPipeline attribute for this dynamic parameter

.PARAMETER ValueFromPipelineByPropertyName
	If specified, set the ValueFromPipelineByPropertyName attribute for this dynamic parameter

.PARAMETER ValueFromRemainingArguments
	If specified, set the ValueFromRemainingArguments attribute for this dynamic parameter

.PARAMETER ParameterSetName
	If specified, set the ParameterSet attribute for this dynamic parameter. By default parameter is added to all parameters sets.

.PARAMETER AllowNull
	If specified, set the AllowNull attribute of this dynamic parameter

.PARAMETER AllowEmptyString
	If specified, set the AllowEmptyString attribute of this dynamic parameter

.PARAMETER AllowEmptyCollection
	If specified, set the AllowEmptyCollection attribute of this dynamic parameter

.PARAMETER ValidateNotNull
	If specified, set the ValidateNotNull attribute of this dynamic parameter

.PARAMETER ValidateNotNullOrEmpty
	If specified, set the ValidateNotNullOrEmpty attribute of this dynamic parameter

.PARAMETER ValidateRange
	If specified, set the ValidateRange attribute of this dynamic parameter

.PARAMETER ValidateLength
	If specified, set the ValidateLength attribute of this dynamic parameter

.PARAMETER ValidatePattern
	If specified, set the ValidatePattern attribute of this dynamic parameter

.PARAMETER ValidateScript
	If specified, set the ValidateScript attribute of this dynamic parameter

.PARAMETER ValidateSet
	If specified, set the ValidateSet attribute of this dynamic parameter

.PARAMETER Dictionary
	If specified, add resulting RuntimeDefinedParameter to an existing RuntimeDefinedParameterDictionary.
	Appropriate for custom dynamic parameters creation.

	If not specified, create and return a RuntimeDefinedParameterDictionary
	Aappropriate for a simple dynamic parameter creation.

.EXAMPLE
	Create one dynamic parameter.

	This example illustrates the use of New-DynamicParameter to create a single dynamic parameter.
	The Drive's parameter ValidateSet is populated with all available volumes on the computer for handy tab completion / intellisense.

	Usage: Get-FreeSpace -Drive <tab>

	function Get-FreeSpace
	{
		[CmdletBinding()]
		Param()
		DynamicParam
		{
			# Get drive names for ValidateSet attribute
			$DriveList = ([System.IO.DriveInfo]::GetDrives()).Name

			# Create new dynamic parameter
			New-DynamicParameter -Name Drive -ValidateSet $DriveList -Type ([array]) -Position 0 -Mandatory
		}

		Process
		{
			# Dynamic parameters don't have corresponding variables created,
			# you need to call New-DynamicParameter with CreateVariables switch to fix that.
			New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

			$DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object {$Drive -contains $_.Name}
			$DriveInfo |
				ForEach-Object {
					if(!$_.TotalFreeSpace)
					{
						$FreePct = 0
					}
					else
					{
						$FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), 2)
					}
					New-Object -TypeName psobject -Property @{
						Drive = $_.Name
						DriveType = $_.DriveType
						'Free(%)' = $FreePct
					}
				}
		}
	}

.EXAMPLE
	Create several dynamic parameters not using custom RuntimeDefinedParameterDictionary (requires piping).

	In this example two dynamic parameters are created. Each parameter belongs to the different parameter set, so they are mutually exclusive.

	The Drive's parameter ValidateSet is populated with all available volumes on the computer.
	The DriveType's parameter ValidateSet is populated with all available drive types.

	Usage: Get-FreeSpace -Drive <tab>
		or
	Usage: Get-FreeSpace -DriveType <tab>

	Parameters are defined in the array of hashtables, which is then piped through the New-Object to create PSObject and pass it to the New-DynamicParameter function.
	Because of piping, New-DynamicParameter function is able to create all parameters at once, thus eliminating need for you to create and pass external RuntimeDefinedParameterDictionary to it.

	function Get-FreeSpace
	{
		[CmdletBinding()]
		Param()
		DynamicParam
		{
			# Array of hashtables that hold values for dynamic parameters
			$DynamicParameters = @(
				@{
					Name = 'Drive'
					Type = [array]
					Position = 0
					Mandatory = $true
					ValidateSet = ([System.IO.DriveInfo]::GetDrives()).Name
					ParameterSetName = 'Drive'
				},
				@{
					Name = 'DriveType'
					Type = [array]
					Position = 0
					Mandatory = $true
					ValidateSet = [System.Enum]::GetNames('System.IO.DriveType')
					ParameterSetName = 'DriveType'
				}
			)

			# Convert hashtables to PSObjects and pipe them to the New-DynamicParameter,
			# to create all dynamic paramters in one function call.
			$DynamicParameters | ForEach-Object {New-Object PSObject -Property $_} | New-DynamicParameter
		}
		Process
		{
			# Dynamic parameters don't have corresponding variables created,
			# you need to call New-DynamicParameter with CreateVariables switch to fix that.
			New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

			if($Drive)
			{
				$Filter = {$Drive -contains $_.Name}
			}
			elseif($DriveType)
			{
				$Filter =  {$DriveType -contains  $_.DriveType}
			}

			$DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object $Filter
			$DriveInfo |
				ForEach-Object {
					if(!$_.TotalFreeSpace)
					{
						$FreePct = 0
					}
					else
					{
						$FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), 2)
					}
					New-Object -TypeName psobject -Property @{
						Drive = $_.Name
						DriveType = $_.DriveType
						'Free(%)' = $FreePct
					}
				}
		}
	}

.EXAMPLE
	Create several dynamic parameters, with multiple Parameter Sets, not using custom RuntimeDefinedParameterDictionary (requires piping).

	In this example three dynamic parameters are created. Two of the parameters are belong to the different parameter set, so they are mutually exclusive.
	One of the parameters belongs to both parameter sets.

	The Drive's parameter ValidateSet is populated with all available volumes on the computer.
	The DriveType's parameter ValidateSet is populated with all available drive types.
	The DriveType's parameter ValidateSet is populated with all available drive types.
	The Precision's parameter controls number of digits after decimal separator for Free Space percentage.

	Usage: Get-FreeSpace -Drive <tab> -Precision 2
		or
	Usage: Get-FreeSpace -DriveType <tab> -Precision 2

	Parameters are defined in the array of hashtables, which is then piped through the New-Object to create PSObject and pass it to the New-DynamicParameter function.
	If parameter with the same name already exist in the RuntimeDefinedParameterDictionary, a new Parameter Set is added to it.
	Because of piping, New-DynamicParameter function is able to create all parameters at once, thus eliminating need for you to create and pass external RuntimeDefinedParameterDictionary to it.

	function Get-FreeSpace
	{
		[CmdletBinding()]
		Param()
		DynamicParam
		{
			# Array of hashtables that hold values for dynamic parameters
			$DynamicParameters = @(
				@{
					Name = 'Drive'
					Type = [array]
					Position = 0
					Mandatory = $true
					ValidateSet = ([System.IO.DriveInfo]::GetDrives()).Name
					ParameterSetName = 'Drive'
				},
				@{
					Name = 'DriveType'
					Type = [array]
					Position = 0
					Mandatory = $true
					ValidateSet = [System.Enum]::GetNames('System.IO.DriveType')
					ParameterSetName = 'DriveType'
				},
				@{
					Name = 'Precision'
					Type = [int]
					# This will add a Drive parameter set to the parameter
					Position = 1
					ParameterSetName = 'Drive'
				},
				@{
					Name = 'Precision'
					# Because the parameter already exits in the RuntimeDefinedParameterDictionary,
					# this will add a DriveType parameter set to the parameter.
					Position = 1
					ParameterSetName = 'DriveType'
				}
			)

			# Convert hashtables to PSObjects and pipe them to the New-DynamicParameter,
			# to create all dynamic paramters in one function call.
			$DynamicParameters | ForEach-Object {New-Object PSObject -Property $_} | New-DynamicParameter
		}
		Process
		{
			# Dynamic parameters don't have corresponding variables created,
			# you need to call New-DynamicParameter with CreateVariables switch to fix that.
			New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

			if($Drive)
			{
				$Filter = {$Drive -contains $_.Name}
			}
			elseif($DriveType)
			{
				$Filter = {$DriveType -contains  $_.DriveType}
			}

			if(!$Precision)
			{
				$Precision = 2
			}

			$DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object $Filter
			$DriveInfo |
				ForEach-Object {
					if(!$_.TotalFreeSpace)
					{
						$FreePct = 0
					}
					else
					{
						$FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), $Precision)
					}
					New-Object -TypeName psobject -Property @{
						Drive = $_.Name
						DriveType = $_.DriveType
						'Free(%)' = $FreePct
					}
				}
		}
	}

.Example
	Create dynamic parameters using custom dictionary.

	In case you need more control, use custom dictionary to precisely choose what dynamic parameters to create and when.
	The example below will create DriveType dynamic parameter only if today is not a Friday:

	function Get-FreeSpace
	{
		[CmdletBinding()]
		Param()
		DynamicParam
		{
			$Drive = @{
				Name = 'Drive'
				Type = [array]
				Position = 0
				Mandatory = $true
				ValidateSet = ([System.IO.DriveInfo]::GetDrives()).Name
				ParameterSetName = 'Drive'
			}

			$DriveType =  @{
				Name = 'DriveType'
				Type = [array]
				Position = 0
				Mandatory = $true
				ValidateSet = [System.Enum]::GetNames('System.IO.DriveType')
				ParameterSetName = 'DriveType'
			}

			# Create dictionary
			$DynamicParameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

			# Add new dynamic parameter to dictionary
			New-DynamicParameter @Drive -Dictionary $DynamicParameters

			# Add another dynamic parameter to dictionary, only if today is not a Friday
			if((Get-Date).DayOfWeek -ne [DayOfWeek]::Friday)
			{
				New-DynamicParameter @DriveType -Dictionary $DynamicParameters
			}

			# Return dictionary with dynamic parameters
			$DynamicParameters
		}
		Process
		{
			# Dynamic parameters don't have corresponding variables created,
			# you need to call New-DynamicParameter with CreateVariables switch to fix that.
			New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

			if($Drive)
			{
				$Filter = {$Drive -contains $_.Name}
			}
			elseif($DriveType)
			{
				$Filter =  {$DriveType -contains  $_.DriveType}
			}

			$DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object $Filter
			$DriveInfo |
				ForEach-Object {
					if(!$_.TotalFreeSpace)
					{
						$FreePct = 0
					}
					else
					{
						$FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), 2)
					}
					New-Object -TypeName psobject -Property @{
						Drive = $_.Name
						DriveType = $_.DriveType
						'Free(%)' = $FreePct
					}
				}
		}
	}
#>
Function New-DynamicParameter {
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = 'DynamicParameter')]
	Param
	(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[System.Type]$Type = [String],

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[string[]]$Alias,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$Mandatory,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[int]$Position,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[string]$HelpMessage,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$DontShow,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$ValueFromPipeline,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$ValueFromPipelineByPropertyName,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$ValueFromRemainingArguments,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[string]$ParameterSetName = '__AllParameterSets',

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$AllowNull,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$AllowEmptyString,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$AllowEmptyCollection,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$ValidateNotNull,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$ValidateNotNullOrEmpty,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateCount(2,2)]
		[int[]]$ValidateCount,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateCount(2,2)]
		[int[]]$ValidateRange,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateCount(2,2)]
		[int[]]$ValidateLength,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateNotNullOrEmpty()]
		[string]$ValidatePattern,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateNotNullOrEmpty()]
		[scriptblock]$ValidateScript,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateNotNullOrEmpty()]
		[string[]]$ValidateSet,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({
			if(!($_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary]))
			{
				Throw 'Dictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object'
			}
			$true
		})]
		$Dictionary = $false,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CreateVariables')]
		[switch]$CreateVariables,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CreateVariables')]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({
			# System.Management.Automation.PSBoundParametersDictionary is an internal sealed class,
			# so one can't use PowerShell's '-is' operator to validate type.
			if($_.GetType().Name -ne 'PSBoundParametersDictionary')
			{
				Throw 'BoundParameters must be a System.Management.Automation.PSBoundParametersDictionary object'
			}
			$true
		})]
		$BoundParameters
	)

	Begin
	{
		Write-Verbose 'Creating new dynamic parameters dictionary'
		$InternalDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

		Write-Verbose 'Getting common parameters'
		function _temp { [CmdletBinding()] Param() }
		$CommonParameters = (Get-Command _temp).Parameters.Keys
	}

	Process
	{
		if($CreateVariables)
		{
			Write-Verbose 'Creating variables from bound parameters'
			Write-Debug 'Picking out bound parameters that are not in common parameters set'
			$BoundKeys = $BoundParameters.Keys | Where-Object { $CommonParameters -notcontains $_ }

			foreach($Parameter in $BoundKeys)
			{
				Write-Debug "Setting existing variable for dynamic parameter '$Parameter' with value '$($BoundParameters.$Parameter)'"
				Set-Variable -Name $Parameter -Value $BoundParameters.$Parameter -Scope 1 -Force
			}
		}
		else
		{
			Write-Verbose 'Looking for cached bound parameters'
			Write-Debug 'More info: https://beatcracker.wordpress.com/2014/12/18/psboundparameters-pipeline-and-the-valuefrompipelinebypropertyname-parameter-attribute'
			$StaleKeys = @()
			$StaleKeys = $PSBoundParameters.GetEnumerator() |
						ForEach-Object {
							if($_.Value.PSobject.Methods.Name -match '^Equals$')
							{
								# If object has Equals, compare bound key and variable using it
								if(!$_.Value.Equals((Get-Variable -Name $_.Key -ValueOnly -Scope 0)))
								{
									$_.Key
								}
							}
							else
							{
								# If object doesn't has Equals (e.g. $null), fallback to the PowerShell's -ne operator
								if($_.Value -ne (Get-Variable -Name $_.Key -ValueOnly -Scope 0))
								{
									$_.Key
								}
							}
						}
			if($StaleKeys)
			{
				[string[]]"Found $($StaleKeys.Count) cached bound parameters:" +  $StaleKeys | Write-Debug
				Write-Verbose 'Removing cached bound parameters'
				$StaleKeys | ForEach-Object {[void]$PSBoundParameters.Remove($_)}
			}

			# Since we rely solely on $PSBoundParameters, we don't have access to default values for unbound parameters
			Write-Verbose 'Looking for unbound parameters with default values'

			Write-Debug 'Getting unbound parameters list'
			$UnboundParameters = (Get-Command -Name ($PSCmdlet.MyInvocation.InvocationName)).Parameters.GetEnumerator()  |
										# Find parameters that are belong to the current parameter set
										Where-Object { $_.Value.ParameterSets.Keys -contains $PsCmdlet.ParameterSetName } |
											Select-Object -ExpandProperty Key |
												# Find unbound parameters in the current parameter set
												Where-Object { $PSBoundParameters.Keys -notcontains $_ }

			# Even if parameter is not bound, corresponding variable is created with parameter's default value (if specified)
			Write-Debug 'Trying to get variables with default parameter value and create a new bound parameter''s'
			$tmp = $null
			foreach($Parameter in $UnboundParameters)
			{
				$DefaultValue = Get-Variable -Name $Parameter -ValueOnly -Scope 0
				if(!$PSBoundParameters.TryGetValue($Parameter, [ref]$tmp) -and $DefaultValue)
				{
					$PSBoundParameters.$Parameter = $DefaultValue
					Write-Debug "Added new parameter '$Parameter' with value '$DefaultValue'"
				}
			}

			if($Dictionary)
			{
				Write-Verbose 'Using external dynamic parameter dictionary'
				$DPDictionary = $Dictionary
			}
			else
			{
				Write-Verbose 'Using internal dynamic parameter dictionary'
				$DPDictionary = $InternalDictionary
			}

			Write-Verbose "Creating new dynamic parameter: $Name"

			# Shortcut for getting local variables
			$GetVar = {Get-Variable -Name $_ -ValueOnly -Scope 0}

			# Strings to match attributes and validation arguments
			$AttributeRegex = '^(Mandatory|Position|ParameterSetName|DontShow|HelpMessage|ValueFromPipeline|ValueFromPipelineByPropertyName|ValueFromRemainingArguments)$'
			$ValidationRegex = '^(AllowNull|AllowEmptyString|AllowEmptyCollection|ValidateCount|ValidateLength|ValidatePattern|ValidateRange|ValidateScript|ValidateSet|ValidateNotNull|ValidateNotNullOrEmpty)$'
			$AliasRegex = '^Alias$'

			Write-Debug 'Creating new parameter''s attirubutes object'
			$ParameterAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute

			Write-Debug 'Looping through the bound parameters, setting attirubutes...'
			switch -regex ($PSBoundParameters.Keys)
			{
				$AttributeRegex
				{
					Try
					{
						$ParameterAttribute.$_ = . $GetVar
						Write-Debug "Added new parameter attribute: $_"
					}
					Catch
					{
						$_
					}
					continue
				}
			}

			if($DPDictionary.Keys -contains $Name)
			{
				Write-Verbose "Dynamic parameter '$Name' already exist, adding another parameter set to it"
				$DPDictionary.$Name.Attributes.Add($ParameterAttribute)
			}
			else
			{
				Write-Verbose "Dynamic parameter '$Name' doesn't exist, creating"

				Write-Debug 'Creating new attribute collection object'
				$AttributeCollection = New-Object -TypeName Collections.ObjectModel.Collection[System.Attribute]

				Write-Debug 'Looping through bound parameters, adding attributes'
				switch -regex ($PSBoundParameters.Keys)
				{
					$ValidationRegex
					{
						Try
						{
							$ParameterOptions = New-Object -TypeName "System.Management.Automation.${_}Attribute" -ArgumentList (. $GetVar) -ErrorAction Stop
							$AttributeCollection.Add($ParameterOptions)
							Write-Debug "Added attribute: $_"
						}
						Catch
						{
							$_
						}
						continue
					}

					$AliasRegex
					{
						Try
						{
							$ParameterAlias = New-Object -TypeName System.Management.Automation.AliasAttribute -ArgumentList (. $GetVar) -ErrorAction Stop
							$AttributeCollection.Add($ParameterAlias)
							Write-Debug "Added alias: $_"
							continue
						}
						Catch
						{
							$_
						}
					}
				}

				Write-Debug 'Adding attributes to the attribute collection'
				$AttributeCollection.Add($ParameterAttribute)

				Write-Debug 'Finishing creation of the new dynamic parameter'
				$Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $Type, $AttributeCollection)

				Write-Debug 'Adding dynamic parameter to the dynamic parameter dictionary'
				$DPDictionary.Add($Name, $Parameter)
			}
		}
	}

	End
	{
		if(!$CreateVariables -and !$Dictionary)
		{
			Write-Verbose 'Writing dynamic parameter dictionary to the pipeline'
			$DPDictionary
		}
	}
}

#Use the following to generate the proxy function:
#$MetaData = New-Object System.Management.Automation.CommandMetaData (Get-Command Add-Member) 
#[System.Management.Automation.ProxyCommand]::Create($MetaData)

function Add-TervisMember {
	[CmdletBinding(DefaultParameterSetName='TypeNameSet', HelpUri='https://go.microsoft.com/fwlink/?LinkID=113280', RemotingCapability='None')]
	param(
		[Parameter(ParameterSetName='MemberSet', Mandatory=$true, ValueFromPipeline=$true)]
		[Parameter(ParameterSetName='TypeNameSet', Mandatory=$true, ValueFromPipeline=$true)]
		[Parameter(ParameterSetName='NotePropertySingleMemberSet', Mandatory=$true, ValueFromPipeline=$true)]
		[Parameter(ParameterSetName='NotePropertyMultiMemberSet', Mandatory=$true, ValueFromPipeline=$true)]
		[psobject]
		${InputObject},

		[Parameter(ParameterSetName='MemberSet', Mandatory=$true, Position=0)]
		[Alias('Type')]
		[System.Management.Automation.PSMemberTypes]
		${MemberType},

		[Parameter(ParameterSetName='MemberSet', Mandatory=$true, Position=1)]
		[string]
		${Name},

		[Parameter(ParameterSetName='MemberSet', Position=2)]
		[System.Object]
		${Value},

		[Parameter(ParameterSetName='MemberSet', Position=3)]
		[System.Object]
		${SecondValue},

		[Parameter(ParameterSetName='MemberSet')]
		[Parameter(ParameterSetName='TypeNameSet', Mandatory=$true)]
		[Parameter(ParameterSetName='NotePropertySingleMemberSet')]
		[Parameter(ParameterSetName='NotePropertyMultiMemberSet')]
		[ValidateNotNullOrEmpty()]
		[string]
		${TypeName},

		[Parameter(ParameterSetName='MemberSet')]
		[Parameter(ParameterSetName='NotePropertySingleMemberSet')]
		[Parameter(ParameterSetName='NotePropertyMultiMemberSet')]
		[switch]
		${Force},

		[Parameter(ParameterSetName='NotePropertySingleMemberSet')]
		[Parameter(ParameterSetName='TypeNameSet')]
		[Parameter(ParameterSetName='MemberSet')]
		[Parameter(ParameterSetName='NotePropertyMultiMemberSet')]
		[switch]
		${PassThru},

		[Parameter(ParameterSetName='NotePropertySingleMemberSet', Mandatory=$true, Position=0)]
		[ValidateNotNullOrEmpty()]
		[string]
		${NotePropertyName},

		[Parameter(ParameterSetName='NotePropertySingleMemberSet', Mandatory=$true, Position=1)]
		[AllowNull()]
		[System.Object]
		${NotePropertyValue},

		[Parameter(ParameterSetName='NotePropertyMultiMemberSet', Mandatory=$true, Position=0)]
		[ValidateNotNullOrEmpty()]
		[System.Collections.IDictionary]
		${NotePropertyMembers}
	)
	DynamicParam {
		$DynamicParameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
		if ($MemberType -eq "ScriptProperty") {
			New-DynamicParameter -Name CacheValue -Type switch -Dictionary $DynamicParameters
		}
		$DynamicParameters
	}

	begin
	{
		try {
			$outBuffer = $null
			if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
			{
				$PSBoundParameters['OutBuffer'] = 1
			}
			$wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Add-Member', [System.Management.Automation.CommandTypes]::Cmdlet)

			if ($PSBoundParameters.CacheValue) {
				$PSBoundParameters.Remove("CacheValue") | Out-Null
				$PSBoundParameters.Value = [ScriptBlock]::Create(@"
					`$This | Add-Member -MemberType NoteProperty -Name $Name -Force -Value `$(
						$($Value.ToString())
					)
					`$This.$Name
"@
				)
			}

			$scriptCmd = {& $wrappedCmd @PSBoundParameters }

			$steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
			$steppablePipeline.Begin($PSCmdlet)
		} catch {
			throw
		}
	}

	process
	{
		try {
			$steppablePipeline.Process($_)
		} catch {
			throw
		}
	}

	end
	{
		try {
			$steppablePipeline.End()
		} catch {
			throw
		}
	}
	<#

	.ForwardHelpTargetName Microsoft.PowerShell.Utility\Add-Member
	.ForwardHelpCategory Cmdlet

	#>
}