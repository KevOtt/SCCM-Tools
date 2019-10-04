# Copyright (c) 2019 Kevin Ott
# Licensed under the MIT License
# See the LICENSE file in the project root for more information.


<# 
.SYNOPSIS
    Creates a report of configurations for all Distribution Points for a given site.
.DESCRIPTION
    Pulls a report of various configurations for all Distribution Points on a given
    site. Can be piped to a file or to an appropriate output format.
.EXAMPLE
    & '.\Generate DP Config Report.ps1' -Site 'EX1' -SiteServer Server1.example.com
.EXAMPLE
    & '.\Generate DP Config Report.ps1' -Site 'EX1' -SiteServer Server1.example.com | Export-CSV C:\DistributionPoints.csv
.PARAMETER Site
    The three letter site code of the site which you are generating seed data for.
    You will be prompted for one if not provided.  
.NOTES
    Filename: Generate DP Config Report.ps1
    Version: 1.0
    Date: 10/2/2019
    Author: Kevin Ott
#> 

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteCode,
    [Parameter(Mandatory=$true)]
    [string]$SiteServer
)



# Create new custom object with needed properties
Function Create-DPObject{
    New-Object -TypeName PSObject -Property ([ordered]@{
        'ServerName'='';`
        'Version'='';`
        'Description'='';`
        'DPType'='';`
        'PXEEnabled'='';`
        'PXEDelay'='';`
        'UnknownSupport'='';`
        'MultiCast'='';`
        'SSLState'='';`
        'DPGroupCount'='';`
        'BoundaryGroups'='';`
        'OS'='';`
        'IP'='';`
        'ADSite'='';`
        'PackagesAssigned'='';`
        'PackagesInProgress'='';`
        'PackagesFailed'=''})
}

# Get Data
TRY{
    $DPInfo = Get-WmiObject -ComputerName $SiteServer -Namespace "root/sms/site_$SiteCode" -Class SMS_DistributionPointInfo -ErrorAction Stop -ErrorVariable e | Select-Object *
    $DPStatus = Get-WmiObject -ComputerName $SiteServer -Namespace "root/sms/site_$SiteCode" -Class SMS_DPStatusInfo -ErrorAction Stop -ErrorVariable e
    $BoundaryGroups = Get-WmiObject -ComputerName $SiteServer -Namespace "root/sms/site_$SiteCode" -Class SMS_BoundaryGroup -ErrorAction Stop -ErrorVariable e
    $BoundarySiteSystems = Get-WmiObject -ComputerName $SiteServer -Namespace "root/sms/site_$SiteCode" -Class SMS_BoundaryGroupSiteSystems -ErrorAction Stop -ErrorVariable e
    }
CATCH{
    throw "Unable to retrieve some or all DP data, exception: `n`n $e"
    }

if(@($DPInfo).Count -le 0){
    Throw "No DP data returned from site $SiteCode"
    }

# Pull the data we want
$DPList= @()
$DPInfo | ForEach-Object{
    $p = $_
    $dp = Create-DPObject
    
    $dp.ServerName = $p.ServerName
    $dp.Version = $p.Properties.Item('Version').Value
    $dp.Description = $p.Description


    if($p.Properties.Item('ispulldp').Value -eq $true){
        $dp.DPType = 'PullDP'
        }
    else{$dp.DPType = 'StandardDP'}

    $dp.PXEEnabled = $p.Properties.Item('ispxe').Value.ToString()
    $dp.PXEDelay = $p.ResponseDelay.ToString()
    $dp.UnknownSupport = $p.SupportUnknownMachines.ToString()
    $dp.MultiCast = $p.Properties.Item('ismulticast').Value.ToString()
    
    if($p.Communication -eq 0){
        $dp.SSLState = 'Http'
        }
    else{$dp.SSLState = 'Https'}

    $dp.DPGroupCount = $p.Properties.Item('GroupCount').Value.ToString()
    
    # Boundary Groups
    $groupNames = @()
    $bids = @($BoundarySiteSystems | Where-Object {$_.ServerNALPath -eq $p.NALPath} | Select-Object -ExpandProperty GroupID)
    foreach($bid in $bids){
        $groupNames += (($BoundaryGroups | Where-Object {$_.GroupID -eq $bid} | Select-Object -ExpandProperty Name).ToString())
        }
    $dp.BoundaryGroups = $groupNames -join ', '

    # Package Status
    $s = $DPStatus | Where-Object {$_.NALPath -eq $p.NALPath} 
    if($null -ne $s){
        $dp.PackagesAssigned = $s.NumberInstalled
        $dp.PackagesFailed = $s.NumberErrors
        $dp.PackagesInProgress = $s.NumberInProgress
        }
    else{$dp.PackagesAssigned = $dp.packagesFailed = $dp.PackagesInProgress = 'Unknown'}


    # Get client system details
    $r = Get-WmiObject -ComputerName $SiteServer -Namespace "root/sms/site_$SiteCode" -Query ('SELECT * FROM SMS_R_System WHERE Name = ' + '"' + $p.Name.Split('.')[0] + '"') -ErrorAction SilentlyContinue

    if($null -eq $r -or @($r).Count -gt 1){
        $dp.IP = $dp.ADSite = $dp.OS = 'Unknown'
        }
    else{
        $dp.IP = $r.IPAddresses -join ';'
        $dp.ADSite = $r.ADSiteName
        $dp.OS = $r.OperatingSystemNameandVersion
        }



    $DPList += $dp
    }


return $DPList