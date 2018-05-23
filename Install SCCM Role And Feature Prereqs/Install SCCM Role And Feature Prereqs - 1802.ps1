<# 
.SYNOPSIS
	Installs prerequisite Windows Server roles & features for SCCM site server roles. Multiple SCCM Server roles
    can be specified and the appropriate prereq Server roles & features will be installed. Last updated based on MS 
    documentation for SCCM 1802.
.DESCRIPTION
    This script automates the process of installing prerequisite Windows Server roles and features needed prior
    to installing an SCCM site server role. This script will need to be run as administrator on the server. Multiple SCCM
    site server roles can be specified as a comma separated set for the parameter SCCMRoles (or one per prompted line if running from ISE)
    tab for auto-completion of names. Provided switches will control the installation of IIS logging and the IIS console. Descriptions 
    of prereqs for each sccm role are listed in the provided link. Prerequisite features are assuming a Server 2012 or higher OS, if 
    you are installing prerequisites on Server 2008 R2 or lower, you should reevaluate your current employment choices. 
.EXAMPLE 
    & '.\Install SCCM Role And Feature Prereqs - 1802.ps1' -SCCMRoles 'Primary Site Server','Distribution Point','Management Point' -InstallIISLogging
.EXAMPLE
    & '.\Install SCCM Role And Feature Prereqs - 1802.ps1' -SCCMRoles 'Distribution Point' -InstallIISManager $False
.EXAMPLE
    & '.\Install SCCM Role And Feature Prereqs - 1802.ps1' -SCCMRoles 'Distribution Point' -Whatif
.PARAMETER SCCMRoles
    Array specifying each of the SCCM roles we want to install prerequisite Roles and Features for. If running from ISE,
    specify each in the provided prompts, if running from command line specify the role names as a comma separated list.
    Role names will need to be exact matches for the full SCCM role name, tab for auto-completion.
.PARAMETER InstallIISManager
    Default value is true; when InstallIISManager is specified as true, the IIS GUI Management console will
    be installed only if one of the prereqs being installed is an IIS role.
.PARAMETER InstallIISLogging
    Specifying the InstallIISLogging parameter will install the IIS Logging only if one of the prereqs being
    installed is an IIS Role. Otherwise we will not install this Role. **Important**: note that selecting 
    "Install and Configure IIS" when installing an SCCM DP will still cause logging to be installed and enabled.
.PARAMETER Whatif
    Specify the switch to run the feature install in whatif mode; i.e. test the feature install only.
.NOTES
    Filename: Install SCCM Role and Feature Preqs - 1802
    Version: 1.0
    Date: 5/23/2018
    Author: Kevin Ott
.LINK
    https://github.com/kevott
    https://docs.microsoft.com/en-us/sccm/core/plan-design/configs/site-and-site-system-prerequisites
#> 

param(
    [ValidateSet('Primary Site Server','Central Site Server', 'Secondary Site Server', 'Application Catalog Website Point', `
    'Application Catalog Web Service Point', 'Fallback Status Point', 'Software Update Point', 'Distribution Point (No PXE)', `
    'Distribution Point', 'Management Point', 'Enrollment Point', 'Enrollment Proxy Point', 'Certificate Registration Point', `
    'Asset Intelligence Synchronization Point', 'Endpoint Protection Point', 'Reporting Services Point', 'State Migration Point',`
    'Service Connection Point')]  
    [Parameter(Mandatory=$true)]
    [array]$SCCMRoles,
    [bool]$InstallIISManager = $true,
    [switch]$InstallIISLogging,
    [switch]$Whatif
)

# Import server manager for powershell 2 compatibility and to ensure we error out if not installed
Import-Module ServerManager -ErrorAction Stop

# Clear variable in case we are running from ISE
$InstallFeatures = @()


# Loop through each SCCM Role specified and add prereq to Install Features based on the SCCM Role
foreach($role in $SCCMRoles){
    Switch($role){

    {'Primary Site Server' -or 'Central Site Server' -or 'Secondary Site Server'}{
        $InstallFeatures += ('NET-Framework-45-Core', 'NET-Framework-Core', 'RDC')
        }

    'Application Catalog Website Point' {
        $InstallFeatures += ('NET-Framework-45-Core', 'NET-Framework-Core', 'NET-Framework-45-ASPNET', `
        'Web-Default-Doc', 'Web-Static-Content', 'Web-Asp-Net', 'Web-Net-Ext', 'Web-Asp-Net45', 'Web-Net-Ext45', `
        'WEB-WINDOWS-AUTH', 'Web-Metabase')
        }

    'Application Catalog Web Service Point'{
        $InstallFeatures += ('NET-Framework-45-Core', 'NET-Framework-Core', 'NET-Framework-45-ASPNET', `
        'NET-WCF-HTTP-Activation45', 'Web-Default-Doc', 'Web-Asp-Net', 'Web-Net-Ext', 'Web-Asp-Net45', `
        'Web-Net-Ext45', 'Web-Metabase')
        }

    'Asset Intelligence Synchronization Point'{
        $InstallFeatures += ('NET-Framework-45-Core')
        }

    'Certificate Registration Point'{
        $InstallFeatures += ('NET-Framework-45-Core', 'NET-WCF-HTTP-Activation45', 'Web-Asp-Net', `
        'Web-Asp-Net45', 'Web-Metabase', 'WEB-WMI')
        }

    'Distribution Point (No PXE)'{
        $InstallFeatures += ('RDC', 'WEB-ISAPI-EXT', 'WEB-WINDOWS-AUTH', 'WEB-METABASE', 'WEB-WMI')
        }

    'Distribution Point'{
        $InstallFeatures += ('RDC', 'WDS', 'WEB-ISAPI-EXT', 'WEB-WINDOWS-AUTH', 'WEB-METABASE', 'WEB-WMI')
        }
    
    'Endpoint Protection Point'{
        $InstallFeatures += ('NET-Framework-Core')
        }

    'Enrollment Point'{
        $InstallFeatures += ('NET-Framework-45-Core', 'NET-Framework-Core', 'NET-WCF-HTTP-Activation45', `
        'NET-Framework-45-ASPNET', 'Web-Default-Doc', 'Web-Asp-Net', 'Web-Net-Ext', 'Web-Asp-Net45', `
        'Web-Net-Ext45', 'Web-Metabase')
        }

    'Enrollment Proxy Point'{
        $InstallFeatures += ('NET-Framework-45-Core', 'NET-Framework-Core', 'Web-Default-Doc', 'Web-Static-Content', `
        'Web-Asp-Net', 'Web-Net-Ext', 'Web-Asp-Net45', 'Web-Net-Ext45', 'WEB-WINDOWS-AUTH', 'Web-Metabase')
        }

    'Fallback Status Point'{
        $InstallFeatures += ('WEB-METABASE')
        }

    'Management Point'{
        $InstallFeatures += ('NET-Framework-45-Core', 'BITS-IIS-Ext', 'WEB-ISAPI-EXT', 'WEB-WINDOWS-AUTH', `
        'WEB-METABASE', 'WEB-WMI', 'Web-Asp-Net45')
        }
    
    'Reporting Services Point'{
        $InstallFeatures += ('NET-Framework-45-Core')
        }

    'Service Connection Point'{
        $InstallFeatures += ('NET-Framework-45-Core')
        }

    'Software Update Point'{
        $InstallFeatures += ('NET-Framework-45-Core', 'NET-Framework-Core', 'UpdateServices', 'UpdateServices-RSAT')
        # Throwing a warning here since WSUS won't actually work until it's been separately configured
        Write-Warning -Message 'Additional Configuration of Update Services will be required after install' -WarningAction Continue
        }
    
    'State Migration Point'{
        $InstallFeatures += @('Web-Server')
        }
    }
}


# Check if we have any webserver roles installed, and if so check if we are planning to install logging
if(($InstallFeatures -match 'web*') -and ($InstallIISLogging)){
    $InstallFeatures += ('Web-Http-Logging')
}

# Same deal, do we have web server roles and if so are we going to install the IIS GUI console
if(($InstallFeatures -match 'web*') -and ($InstallIISManager)){
    $InstallFeatures += ('Web-Mgmt-Console')
}


# Attempt install of roles, pass in the appropriate whatif
# Install-WindowsFeature should just ignore multiple instances of the same role
Install-WindowsFeature -Name $InstallFeatures -Verbose -whatif:$Whatif -ErrorAction Stop