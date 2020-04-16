#get script path
$strScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#get template locations
$arrTemplateLocations = Get-Content -Path "$strScriptPath\_cfg_templ.txt"
#get storage profiles
$arrStorageProfiles = Import-Csv -Path "$strScriptPath\_cfg_storage.txt"

Cls
Write-Host ""
Write-Host -ForegroundColor Gray "Starting cleanup process..."
Write-Host ""

Foreach ($objStorageProfile In $arrStorageProfiles)
{
    $arrVMFolders = Get-ChildItem -Path "$($objStorageProfile.Path)"
    Foreach ($objVMFolder In $arrVMFolders)
    {
        #check if this folder is template folder
        $booTemplateLocation = $false
        Foreach ($strTemplateLocation In $arrTemplateLocations) {If ("$($objVMFolder.FullName)" -like "$strTemplateLocation") {$booTemplateLocation = $true} }

        If (-not $booTemplateLocation) {
            $booHddExists = $true
            $booVMConfigExists = $true
            #set HDDs path
            $strHddPath = "$($objVMFolder.FullName)\Virtual Hard Disks"
            #set VM config path
            $strVMConfigPath = "$($objVMFolder.FullName)\Virtual Machines"

            #searching for HDDs
            If (Test-Path -Path "$strHddPath")
            {
                If ($(Get-ChildItem -Path "$strHddPath").Count -gt 0)
                {
                    $booHddExists = $true
                }
                Else
                {
                    $booHddExists = $false
                }
            }
            Else
            {
                $booHddExists = $false
            }

            #searching for VM config
            If (Test-Path -Path "$strVMConfigPath")
            {
                If ($(Get-ChildItem -Path "$strVMConfigPath").Count -gt 0)
                {
                    $booVMConfigExists = $true
                }
                Else
                {
                    $booVMConfigExists = $false
                }
            }
            Else
            {
                $booVMConfigExists = $false
            }

            If ($booHddExists -or $booVMConfigExists)
            {
                Write-Host -ForegroundColor Yellow -NoNewline "$($objVMFolder.FullName)"
                Write-Host " - Won't be deleted"
            }
            Else
            {
                Write-Host -ForegroundColor Yellow -NoNewline "$($objVMFolder.FullName)"
                Write-Host " - Deleting..."
                Remove-Item -Path "$($objVMFolder.FullName)" -Recurse -Confirm:$false
                If (-not $(Test-Path -Path "$($objVMFolder.FullName)")) {Write-Host -ForegroundColor Green "Deleted!"}
            }
        }

    }
}

Write-Host ""
Write-Host -ForegroundColor Green "Cleanup process completed successfully!"