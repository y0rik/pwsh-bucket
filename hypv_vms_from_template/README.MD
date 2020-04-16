## General
This is a simple script helping to deploy VMs from templates in a one-host Hyper-V installation

It's based on diffirential disk types, that helps to save space and improve performance by placing templates to faster storage

## Pre-requisites
* Copy the folder to your Hyper-V host

* _cfg_storage.txt - .csv files containing 2 fileds: VMs root folder path and type of storage. Please edit the file according to your setup

* _cfg_templ.txt - test file containing root path to templates folder. Please adjust the file according to your setup

* You need to create manually at least 1 virtual switch

* You need to create manually at least 1 VM template and place it into the folder according to _cfg_templ.txt

## How to use

Run the script from elevated powershell session to create a new VM from template

It's wizard-based and intuitive
```sh
PS> vm_from_template.ps1
```

Run the script from elevated powershell session to remove old folders without VM config/disk files
```sh
PS> cleanup_vm_folders.ps1
```