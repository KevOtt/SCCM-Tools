Function Import-CMModule{
<# 
.SYNOPSIS
    A standard wrapper for importing the CM Module to eliminate certain issues.
.DESCRIPTION
    This is a function intended to be used as a wrapper for importing the Configuration
    Manager Powershell module. By default, the module has a number of issues in how it
    deals with saved site connections including writing false non-terminating errors and
    a possibility of creating an incorrect connection. Some of these issues have been fixed
    in CB releases, some have not. By prompting for a site code and primary site server name,
    we can ensure that the correct PS drives are always created and no improper error are
    presented to the user. Multiple sites can be specified as per code examples.  The function
    will return error code 1 in the event of a failure.
.EXAMPLE
    Import-CMModule -SiteCode EX1 -SiteServer server1.example.com
.EXAMPLE
    Import-CMModule -SiteCode EX1, EX2 -SiteServer primary1.example.com, primary2.example.com
.PARAMETER SiteCode
    Array of site codes that we want to connect to. Needs to be specified with the corrisponding
    primary site server name in the same order. This is used to ensure the PS drives for all required 
    sites exist.
.PARAMETER ServerName
    Array of primary site server names that we want to connect to.  Needs to be specified with the 
    corrisponding site code in the same order.  FQDN is not required, but is reccomended per best
    practice. This is used to ensure the PS drives for all required sites exist.
.PARAMETER UserModulePath
    Location of the CM Module File, use only if the environment variable 
    SMS_ADMIN_UI_PATH is not populated or is not correct.
.NOTES
    Date: 5/20/2018
    Author: Kevin Ott
.LINK
    https://github.com/kevott
#>
    param(
        [Parameter(Mandatory=$true)]
        [array]$SiteCode,
        [Parameter(Mandatory=$true)]
        [array]$SiteServer,
        [string]$UserModulePath = $NULL
        )


    # Verify the number of provided site codes matches the number of site servers.
    if($SiteCode.count -ne $SiteServer.Count){
        Write-Error -Exception 'Parameter Mismatch' -Category 'InvalidArgument' `
        -Message 'Number of provided site codes does not match number of provided site server names.' `
        -RecommendedAction 'Verify function arguments'
        return 1
        }
        
    # Checking if user defined a module path
    if($UserModulePath -eq [string]$NULL){
            # No defined module path, check if the env variable exists
            if($env:SMS_ADMIN_UI_PATH -ne $NULL){
                # Use env variable
                $ModulePath = (($env:SMS_ADMIN_UI_PATH | Split-Path) +  "\ConfigurationManager.psd1")
            }
            # No defined module path, no env variable, try default location
            Else{
                $ModulePath = 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
                }
        }
    Else{
        # Use user defined path
        $ModulePath = $UserModulePath
        }
    
    # Test if selected path exists, if not write-error and return 1.
    if((test-path -Path $ModulePath) -eq $False){
        Write-Error -Exception "Invalid Path"  -Category "ObjectNotFound" `
        -Message "Directory $ModulePath does not exist or cannot be accessed" `
        -RecommendedAction "Verify the ConfigMgr Powereshell Module is installed in the default location or specify path."
        return 1
        }

    # Try to import module, ignore exceptions related to incorrect MRUs
    
    <# All site connection attempts are stored as MRUs, previous to 2012 CU3 *any*
    attempted connection would be saved under MRU in the registry, post CU2 only connections that
    passed a connection test (not necessary even a site server) would be saved. All of these
    invalid conneciton attemps can write various useless errors, we will redirect most to 
    write-verbose here.#>

    TRY{
        Import-Module $ModulePath -ErrorAction Stop
        }
    CATCH [System.ArgumentException]{
        # Generally this is caused by an existing MRU that is invalid, can safely ignore.
        Write-Verbose 'Ignoring exception caused by invalid MRU'
        Write-Verbose $_.Exception
        }
    CATCH [System.UnauthorizedAccessException]{
        # No Access to WMI on some server in one of the MRUs, should be ignored
        Write-Verbose 'Ignoring exception caused by lack of WMI access'
        Write-Verbose $_.Exception
        }
    CATCH [Microsoft.ConfigurationManagement.ManagementProvider.SmsConnectionException]{
        # Server Not Reachable, possible invalid MRU or server is offline>
        Write-Verbose 'Ignoring exception caused by unreachable server'
        Write-Verbose $_.Exception
        }
    CATCH [System.Management.Automation.ProviderInvocationException]{
        # PS Drive already exists and module is trying to re-create it.
        Write-Verbose 'Ignoring exception caused by already-existing PS Drive'
        Write-Verbose $_.Exception
        }
    CATCH{
        # Catch for any other errors, likely not related to MRU issues.
        Write-Error -Exception 'Import Failed' -Category 'ObjectNotFound' `
        -Message ("Unable to import module: `n" + $_.Exception.Message)
        return 1
        }

    # Create PS Drives

    $i = 0
    foreach($entry in $SiteCode){
        # Check Site Server set for PSdrive, if exists but not matched to arguments remove the PS drive.
        # Will prevent inaccurate MRUs from causing issues.
        if(((get-PSDrive).Name -contains $entry) -and ((get-PSDrive | Where-Object{$_.Name -eq $entry} | select Root).Root).Split(".")[0] `
        -ne $SiteServer[$i].Split(".")[0]){
            Remove-PSDrive $entry
            }

        # Checks if the PS drive exists for the site code
        if((get-PSDrive).Name -notcontains $entry){
            # Create PS Drive for configuration manager.
            TRY{
                New-PSDrive -Name $entry -PSProvider CMSite -Root $SiteServer[$i] -Scope Global -ErrorAction STOP | Out-Null
                }
            CATCH{
                Write-Error -Exception 'PS Drive Creation Failed' `
                -Message ("Failure creating Configuration Manager drive: `n" + $_.Exception.Message) `
                -RecommendedAction 'Validate site code and servername'
                return 1
                }
            }
        $i++
    }
    return 0
}
