# Copyright (c) 2019 Kevin Ott
# Licensed under the MIT License
# See the LICENSE file in the project root for more information.


<# 
.SYNOPSIS
	Redistributes all failed packages on a single DP.
.DESCRIPTION
    Redistributes any packages for the specified DP which are in state 3,
    which is failed content distribution.
.EXAMPLE
    & '.\Redistribute Failed Packages on Single DP.ps1' -SiteCode EX1 -SiteServer server1.example.com -DP Server2
.PARAMETER SiteCode
    Three letter SiteCode for the targeted site.
.PARAMETER SiteServer
    FQDN of the primary site server of the targeted site.
.PARAMETER DP
    Short name of the DP targeted for redistribution
.PARAMETER WarningThreshhold
    Number of packages at which the user will be prompted to redistribute, default 50.
.NOTES
    Filename: Redistribute All Failed Packages on Single DP.ps1
    Version: 
    Date: 9/20/2019
    Author: Kevin Ott
.LINK
#> 
Param(
    [Parameter(Mandatory=$true)]
    [string]$SiteCode,
    [Parameter(Mandatory=$true)]
    [string]$SiteServer,
    [Parameter(Mandatory=$true)]
    [string]$DP,
    [int]$WarningThreshhold = 50
    )

# Get all failed packages for specified DP
$PackageList = Get-WmiObject -ComputerName $SiteServer -Namespace "root/SMS/Site_$SiteCode" `
-Class SMS_packagestatusdistpointssummarizer -Filter ('State=3 AND ServerNALPath LIKE ' + ("'%" + $DP + "%'"))

if($Null -eq $PackageList){
    Throw "No package information returned for $DP"
    }
elseif($PackageList.PackageID.Count -le 0){
    Write-Warning "No failed packaged returned for $DP" -WarningAction Continue
    exit 0
    }

# Check packaged numbers, prompt user with package numbers
if($PackageList.Count -ge $WarningThreshhold){
    Write-Warning ($PackageList.Count.ToString() + ' packages will be redistributed, continue?') -WarningAction Inquire 
    }

# Redistribute each package.
$PackageList | ForEach-Object {
    Write-Output $_.PackageID
    $pkgid = $_.PackageID
    $pkg = Get-WmiObject -ComputerName $SiteServer -Namespace "root/SMS/Site_$SiteCode" `
    -Class SMS_DistributionPoint -Filter ("PackageID='$pkgid' AND ServerNALPath LIKE " + ("'%" + $DP + "%'"))
    $pkg.RefreshNow = $true
    $pkg.Put()
    }
