
Import-Module Hyper-V

$strScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#get template locations
$arrTemplateLocations = Get-Content -Path "$strScriptPath\_cfg_templ.txt"
$arrTemplates = @()
#collect template names
$arrTemplateLocations | foreach {Get-ChildItem -Path "$_"} | foreach {$arrTemplates = $arrTemplates + $_.FullName}

#get storage profiles
$arrStorageProfiles = Import-Csv -Path "$strScriptPath\_cfg_storage.txt"

#[array]::indexof($a.Path,"F:\VMs")

cls

[string]$strVMName = ""
$arrVMs = Get-VM
#get VM name
While (($($arrVMs | where {$_.Name -like "$strVMName"}).Count -ne 0) -or ($strVMName -eq ""))
{
    If ($strVMName -ne "") {Write-Host -ForegroundColor Red "VM exists! Enter another name"}
    $strVMName = Read-Host -Prompt "Enter VM name"
}
cls

#ask for vm generation
[int]$intReturn = Read-Host -Prompt "Choose VM Generation(1 or 2)"

While ($True)
{
	If (($intReturn -le 1) -or ($intReturn -ge 3))
	{
		Write-Host -ForegroundColor Red "Incorect number! Please, try again"
		[int]$intReturn = Read-Host -Prompt "Choose VM Generation(1 or 2)"
	}
	Else
	{
		$intVMGen = $intReturn
		Break
	}
}
cls

#write available templates
Write-Host -ForegroundColor Yellow "Templates:"
$i=0
Foreach ($strTemplate In $arrTemplates)
{
	Write-Host "|$i| $strTemplate"
	$i++
}
#ask for number
[int]$intReturn = Read-Host -Prompt "Choose template"

While ($True)
{
	If (($intReturn -lt 0) -or ($intReturn -gt $i))
	{
		Write-Host -ForegroundColor Red "Incorect number! Please, try again"
		[int]$intReturn = Read-Host -Prompt "Choose template"
	}
	Else
	{
		$intTemplateIndex = $intReturn
		Break
	}
}
cls


#choose CPU cores
[int]$intReturn = Read-Host -Prompt "Enter number of CPU cores(press ENTER if default-1)"
If ($intReturn -eq 0) {$intReturn = 1}
$intCPUNumber = $intReturn
cls


#choose RAM
[int]$intReturn = Read-Host -Prompt "Enter amount of RAM in MB(press ENTER if default-2048)"
If ($intReturn -eq 0) {$intReturn = 2048}
$intRAMAmount = $intReturn
cls


#choose disks
#[int]$intReturn = Read-Host -Prompt "Enter number of additional disks if required(press ENTER if default-0)"
#$intNumberOfAddDisks = $intReturn
#cls

#choose storage profile for disks
$i=0
Write-Host -ForegroundColor Yellow "Storage profiles:"
Foreach ($objStorageProfile In $arrStorageProfiles)
{
	Write-Host "|$i| $($objStorageProfile.path) | $($objStorageProfile.storage_type)"
	$i++
}
#ask for number
[int]$intReturn = Read-Host -Prompt "Choose storage profile"

While ($True)
{
	If (($intReturn -lt 0) -or ($intReturn -gt $i))
	{
		Write-Host -ForegroundColor Red "Incorect number! Please, try again"
		[int]$intReturn = Read-Host -Prompt "Choose storage profile"
	}
	Else
	{
		$intStorageProfileIndex = $intReturn
		Break
	}
}
cls


#ask for disk type

Write-Host "Disk types:"
Write-Host "|0| Differencing"
Write-Host "|1| Dynamic"
Write-Host "|2| Fixed"

[int]$intReturn = Read-Host -Prompt "Choose disk type(default 0)"

While ($True)
{
	If (($intReturn -lt 0) -or ($intReturn -ge 2))
	{
		Write-Host -ForegroundColor Red "Incorect number! Please, try again"
		[int]$intReturn = Read-Host -Prompt "Choose disk type(default 0)"
	}
	Else
	{
		$intDiskType = $intReturn
		Break
	}
}
cls

#choose NICs
$arrVMSwitches = Get-VMSwitch
$i=0
Write-Host -ForegroundColor Yellow "Virtual switches:"
Foreach ($objVMSwitch In $arrVMSwitches)
{
	Write-Host "|$i| $($objVMSwitch.Name)"
	$i++
}
#ask for number
[int]$intReturn = Read-Host -Prompt "Choose virtual switch for default NIC"

While ($True)
{
	If (($intReturn -lt 0) -or ($intReturn -gt $i))
	{
		Write-Host -ForegroundColor Red "Incorect number! Please, try again"
		[int]$intReturn = Read-Host -Prompt "Choose virtual switch for default NIC"
	}
	Else
	{
		$intVMSwitchIndex = $intReturn
		Break
	}
}
cls

#build path to VM hard drive
$strDiskPath = "$($arrStorageProfiles[$intStorageProfileIndex].Path)\$strVMName\Virtual Hard Disks\00.vhdx"
#build parent path to VM hard drive
$strDiskParentPath = "$($arrStorageProfiles[$intStorageProfileIndex].Path)\$strVMName\Virtual Hard Disks"

##build path to parent hard drive
$strParentDiskPath = "$($arrTemplates[$intTemplateIndex])"
#build path to VM
$strVMPath = "$($arrStorageProfiles[$intStorageProfileIndex].Path)"

#check if the VHD exists
If (Test-Path -Path "$strDiskPath")
{
    Write-Host -ForegroundColor Yellow "VHD exists:$strDiskPath"
    Write-Host -ForegroundColor Yellow "Do you want to replace?"
    [string]$strReturn=""
    While (($strReturn -notlike "y") -and ($strReturn -notlike "n"))
    {
        $strReturn = Read-Host -Prompt "(y/n)"
        #Write-Host $($strReturn -notlike "y")
        #Write-Host $($strReturn -notlike "n")
    }
    If ($strReturn -like "y")
    {
        Write-Host -ForegroundColor Yellow "Deleting..."
        Remove-Item -Path "$strDiskPath"
    }
    If ($strReturn -like "n")
    {
        Write-Host -ForegroundColor Yellow "Exiting..."
        quit
    }

}
else{
    if (-not (Test-Path -Path "$strDiskParentPath")){mkdir "$strDiskParentPath"}
}

#create VHD
Write-Host -ForegroundColor Yellow "Creating VHD..."
Write-Host ""
switch ($intDiskType){
    0 {$strDiskType = 'Differencing';break}
    1 {$strDiskType = 'Dynamic';break}
    2 {$strDiskType = 'Fixed';break}
}

if ("$strDiskType" -like 'Differencing'){
    New-VHD -Path "$strDiskPath" -ParentPath "$strParentDiskPath" -Differencing
}
else{
    $strParentDiskType = (Get-VHD -Path "$strParentDiskPath").VhdType
    Copy-Item -Path "$strParentDiskPath" -Destination "$strDiskPath"
    if ("$strDiskType" -notlike "$strParentDiskType"){Convert-VHD -Path "$strDiskPath" -VHDType "$strDiskType"}

}

#create VM
Write-Host -ForegroundColor Yellow "Creating VM..."
Write-Host ""
New-VM -Name "$strVMName" -MemoryStartupBytes $($intRAMAmount*1024*1024) -Generation $intVMGen -Path "$strVMPath" -SwitchName "$($arrVMSwitches[$intVMSwitchIndex].Name)" -VHDPath "$strDiskPath"
Set-VMProcessor -Count $intCPUNumber -VMName "$strVMName"

Write-Host -ForegroundColor Yellow "Script completed!"