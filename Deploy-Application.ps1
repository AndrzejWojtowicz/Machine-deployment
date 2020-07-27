<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows. 
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. 
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
---------------------------------------------------------------------------------------------------
Script (Template) created by: Wojciech Aksamit
Date: 22.08.2019
	
Changelog:

1.2.0	Version
    
    ***
    ## Danone Variable was moved below PowerShell App Deployment Toolkit Variables after "endregion"

    ***
    ## The Instal Parameters option was added to the MSI instalaltion variables:
    #The MSI installation file and parameter for the unanatended installation

    [string]$MSI_ApplicationFileToInstall1 = ""
    [string]$MSI_InstallTransform1 = ""

    [string]$MSP_ApplicationFileToInstall1 = ""

	change to
	
	#The MSI installation file and parameter for the unanatended installation

    [string]$MSI_ApplicationFileToInstall1 = ""
    [string]$MSI_InstallParams1 = "REBOOT=ReallySuppress /QN"
    [string]$MSI_InstallTransform1 = ""

    [string]$MSP_ApplicationFileToInstall1 = ""

1.3.0	Version	

    ***
    ## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt         
    Show-InstallationWelcome -CloseApps $AppsToClose -PersistPrompt

    change to

    ## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt         
    Show-InstallationWelcome -CloseApps $AppsToClose -PersistPrompt -BlockExecution

    ***
    ## Display a message at the end of the install
	If (-not $useDefaultMsi -and $DeployMode -eq 'Interactive') {Show-DialogBox -Title 'Installation Notice' -Text $TextAfterInstallation -Buttons 'OK' -Icon Information -Timeout 5}

    change to
    
    If (-not $useDefaultMsi -and $DeployMode -eq 'Interactive') {Show-InstallationPrompt -Message $TextAfterInstallation -ButtonRightText 'OK' -Icon Information -Timeout 5 -NoWait}

    ***
    If (-not $useDefaultMsi -and $DeployMode -eq 'Interactive') {Show-DialogBox -Title 'Uninstallation Notice' -Text $TextAfterUninstallation -Buttons 'OK' -Icon Information -Timeout 5}
	
    change to	

    If (-not $useDefaultMsi -and $DeployMode -eq 'Interactive') {Show-InstallationPrompt -Message $TextAfterUninstallation -ButtonRightText 'OK' -Icon Information -Timeout 5 -NoWait }

    ***
    AppDeployToolkitMain.ps1 was changed:
    https://github.com/SierraEcoBravo/PSAppDeployToolkit/pull/1/commits/67a144efc9ca1c698fe482f5b32f4e4d924c1dc1
    https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/compare/v3.7.0...master#diff-9c4bf12c6d73e8748e58440c16dfe489

1.4.0	Version	

    ***
    # Show Ballon Notification was off

    <ShowBalloonNotifications>True</ShowBalloonNotifications>

    change to

    <ShowBalloonNotifications>False</ShowBalloonNotifications>

1.5.0	Version	

    ***The Logo was changed  - clearned info about ITCC EMEA DA***
    ***The icon was changed to Danone logo***
---------------------------------------------------------------------------------------------------	
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = ''
	[string]$appName = ''
	[string]$appVersion = ''
	[string]$appArch = ''
	[string]$appLang = ''
	[string]$appRegion = ''
	[string]$appCBS = ''
	[string]$appCountry = ''
	[string]$appCreationDate = ''
    [string]$appType = 'Applications'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.5.0'
	[string]$appScriptDate = '22/08/2019'
    [string]$appScriptAuthor = ''
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''

	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.7.0'
	[string]$deployAppScriptDate = '02/13/2018'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
	#endregion
	
    ##*===============================================
	##* DANONE VARIABLE
	##*===============================================
    
    ##*-------------------------------------------------------------------------------------------------------------------
    ## Danone Variables: Main Package Variable
    # only those variables can be modified by the person who prepare application for deployment!


    #Apps to close before the start of the installation and deinstallation. e.g "iexplore,TeamViewer"
    [string]$AppsToClose = 'InsertAppNameToClose'


    ##*-----------------------------------------------
    ##* EXE Files
    ##*-----------------------------------------------

    #The EXE installation file and parameter for the unanatended installation

    [string]$EXE_ApplicationFileToInstall1 = ""
    [string]$InstallParams1 = ""

    [string]$EXE_ApplicationFileToInstall2 = ""
    [string]$InstallParams2 = ""

    [string]$EXE_ApplicationFileToInstall3 = ""
    [string]$InstallParams3 = ""
    

    #The EXE uninstallation file and parameter for the unanatended uninstallation
    
    [string]$EXE_ApplicationFileToUninstall1 = ""
    [string]$EXE_UninstallParams1 = ""

    [string]$EXE_ApplicationFileToUninstall2 = ""
    [string]$EXE_UninstallParams2 = ""

    [string]$EXE_ApplicationFileToUninstall3 = ""
    [string]$EXE_UninstallParams3 =


    ##*-----------------------------------------------
    ##* MSI Files
    ##*-----------------------------------------------

    #The MSI installation file and parameter for the unanatended installation

    [string]$MSI_ApplicationFileToInstall1 = ""
    [string]$MSI_InstallParams1 = "REBOOT=ReallySuppress /QN"
    [string]$MSI_InstallTransform1 = ""

    [string]$MSP_ApplicationFileToInstall1 = ""


    [string]$MSI_ApplicationFileToInstall2 = ""
    [string]$MSI_InstallParams2 = "REBOOT=ReallySuppress /QN"
    [string]$MSI_InstallTransform2 = ""
    
    [string]$MSP_ApplicationFileToInstall2 = ""


    [string]$MSI_ApplicationFileToInstall3 = ""
    [string]$MSI_InstallParams3 = "REBOOT=ReallySuppress /QN"
    [string]$MSI_InstallTransform3 = ""

    [string]$MSP_ApplicationFileToInstall3 = ""
    

    #The MSI uninstallation file and parameter for the unanatended uninstallation
    
    [string]$MSI_ApplicationNameToUninstall1 = ""
    [string]$MSI_UninstallPath1 = ""

    [string]$MSI_ApplicationNameToUninstall2 = ""
    [string]$MSI_UninstallPath2 = ""

    [string]$MSI_ApplicationNameToUninstall3 = ""
    [string]$MSI_UninstallPath3 =


    ##*-----------------------------------------------
    ##* Previous Applciations to Uninstall
    ##*-----------------------------------------------

    #The uninstallation file, parameters, paths for the unanatended uninstallation for previous applications

    $ApplicationPreviousUninstall1 = ""
    $ApplicationPreviousUninstallParams1 = ""

    $ApplicationPreviousUninstall2 = ""
    $ApplicationPreviousUninstallParams2 = ""

    $ApplicationPreviousUninstall3 = ""
    $ApplicationPreviousUninstallParams3 = ""

    $MSI_ApplicationPreviousUninstallPath1 = ""

    $MSI_ApplicationPreviousUninstallPath2 = ""

    $MSI_ApplicationPreviousUninstallPath3 = ""


    ##*-------------------------------------------------------------------------------------------------------------------






    ##* Do not modify section above

	##*===============================================
	##* DANONE VARIABLE - DO NOT MODIFY
	##*===============================================
  
    [string]$registryApplicationHistory = 'HKLM:\SOFTWARE\DANONE\Applications\'
    [string]$registryDriverHistory = 'HKLM:\Software\DANONE\Drivers\'

    [string]$StandardFolder = $envWinDir+"\DANONE\"

    $installDic = @{E="Error";PreI="Preinstall";Inst="Install";PostI="Postinstall";Installed="Installed";PreU="Preuninstall";Unst="Uninstall";PostU="Postuninstall";Uninstalled="Uninstalled"}
    
    [string]$installDate=Get-Date -Format "yyyy-MM-dd_HH:mm:ss"

    ## Application Deployment Name

    if ($appCBS) {
                if ($appCountry) 
                        {
                        [string]$appFullName=$appVendor+"_"+$appName+"_"+$appVersion+"_"+$appArch+"_"+$appLang+"_"+$appRegion+"_"+$appCBS+"_"+$appCountry+"_"+$appCreationDate
                        }
                        else 
                            {
                            [string]$appFullName=$appVendor+"_"+$appName+"_"+$appVersion+"_"+$appArch+"_"+$appLang+"_"+$appRegion+"_"+$appCBS+"_"+$appCreationDate
                            } 
                }
                else
                {
                [string]$appFullName=$appVendor+"_"+$appName+"_"+$appVersion+"_"+$appArch+"_"+$appLang+"_"+$appRegion+"_"+$appCreationDate
                }

    ## Registry Deployment Name

    if ($appType -eq 'Drivers') {
                    [string]$registryPathHistory = $registryDriverHistory
                    [string]$registryPathPackages = $registryDriverHistory+$appFullName
                }
                else
                {
                [string]$registryPathHistory = $registryApplicationHistory
                [string]$registryPathPackages = $registryApplicationHistory+$appFullName
                }

    [string]$registryValuePackagesName=$appFullName

    [string]$registryNameDate="Date"
    [string]$registryNameDeploymentName="DeploymentName"
    [string]$registrynameResult="Result"
    [string]$registryNameVersion="Version"
    [string]$registryNameResultCode="ResultCode"
    [string]$registryNameInstallCommand1="InstallCommand1"
    [string]$registryNameInstallCommand2="InstallCommand2"
    [string]$registryNameInstallCommand3="InstallCommand3"


    ## Variables: Notifications

    [string]$InstallationText="Installing application "+$appFullName+". Please Wait..."
    [string]$UninstallationText="Uninstalling application "+$appFullName+". Please Wait..."

    [string]$TextAfterInstallation="Application "+$appFullName+" was installed!"
    [string]$TextAfterUninstallation="Application "+$appFullName+" was uninstalled!"

    ##Get the commandline how the program was executed.

    [string]$utilsEXEInstCmdDir1 = $dirFiles+"\"+$EXE_ApplicationFileToInstall1+" "+$InstallParams1
    [string]$utilsEXEInstCmdDir2 = $dirFiles+"\"+$EXE_ApplicationFileToInstall2+" "+$InstallParams2
    [string]$utilsEXEInstCmdDir3 = $dirFiles+"\"+$EXE_ApplicationFileToInstall3+" "+$InstallParams3

    [string]$utilsEXEUninstCmdDir1 = $dirFiles+"\"+$EXE_ApplicationFileToUninstall1+" "+$EXE_UninstallParams1
    [string]$utilsEXEUninstCmdDir2 = $dirFiles+"\"+$EXE_ApplicationFileToUninstall2+" "+$EXE_UninstallParams2
    [string]$utilsEXEUninstCmdDir3 = $dirFiles+"\"+$EXE_ApplicationFileToUninstall3+" "+$EXE_UninstallParams3

    [string]$utilsMSIInstCmdDir1 = "C:\windows\system32\msiexec.exe /i"+" "+$dirFiles+"\"+$MSI_ApplicationFileToInstall1+" "+$MSI_InstallParams1
    [string]$utilsMSIInstCmdDir11 = "C:\windows\system32\msiexec.exe /i"+" "+$dirFiles+"\"+$MSI_ApplicationFileToInstall1+" "+"TRANSFORMS="+$MSI_InstallTransform1+" "+$MSI_InstallParams1
    [string]$utilsMSIInstCmdDir111 = "C:\windows\system32\msiexec.exe /p"+" "+$dirFiles+"\"+$MSP_ApplicationFileToInstall1+" "+$MSI_InstallParams1
    [string]$utilsMSIInstCmdDir2 = "C:\windows\system32\msiexec.exe /i"+" "+$dirFiles+"\"+$MSI_ApplicationFileToInstall2+" "+$MSI_InstallParams2
    [string]$utilsMSIInstCmdDir22 = "C:\windows\system32\msiexec.exe /i"+" "+$dirFiles+"\"+$MSI_ApplicationFileToInstall2+" "+"TRANSFORMS="+$MSI_InstallTransform1+" "+$MSI_InstallParams2
    [string]$utilsMSIInstCmdDir222 = "C:\windows\system32\msiexec.exe /p"+" "+$dirFiles+"\"+$MSP_ApplicationFileToInstall2+" "+$MSI_InstallParams2
    [string]$utilsMSIInstCmdDir3 = "C:\windows\system32\msiexec.exe /i"+" "+$dirFiles+"\"+$MSI_ApplicationFileToInstall3+" "+$MSI_InstallParams3
    [string]$utilsMSIInstCmdDir33 = "C:\windows\system32\msiexec.exe /i"+" "+$dirFiles+"\"+$MSI_ApplicationFileToInstall3+" "+"TRANSFORMS="+$MSI_InstallTransform1+" "+$MSI_InstallParams3
    [string]$utilsMSIInstCmdDir333 = "C:\windows\system32\msiexec.exe /p"+" "+$dirFiles+"\"+$MSP_ApplicationFileToInstall3+" "+$MSI_InstallParams3
    
    [string]$utilsMSIUninstCmdDir1 = "MSIAppName: "+$MSI_ApplicationNameToUninstall1
    [string]$utilsMSIUninstCmdDir11 = "MSIPath: "+$MSI_UninstallPath1
    [string]$utilsMSIUninstCmdDir2 = "MSIAppName: "+$MSI_ApplicationNameToUninstall2
    [string]$utilsMSIUninstCmdDir22 = "MSIPath: "+$MSI_UninstallPath2
    [string]$utilsMSIUninstCmdDir3 = "MSIAppName: "+$MSI_ApplicationNameToUninstall3
    [string]$utilsMSIUninstCmdDir33 = "MSIPath: "+$MSI_UninstallPath3

    ## Set the core registry keys of the program that will be installed

    if(!(Test-Path $registryApplicationHistory))
        {
        New-Item -Path $registryApplicationHistory -Force | Out-Null
        }

    if(!(Test-Path $registryDriverHistory))
        {
        New-Item -Path $registryDriverHistory -Force | Out-Null
        }

    if(!(Test-Path $registryPathPackages))
        {
        New-Item -Path $registryPathPackages -Force | Out-Null
        }

        New-ItemProperty -Path $registryPathPackages -Name $registryNameDate -Value $installDate -PropertyType String -Force | Out-Null   
        New-ItemProperty -Path $registryPathPackages -Name $registryNameDeploymentName -Value $appFullName -PropertyType String -Force | Out-Null              
        New-ItemProperty -Path $registryPathPackages -Name $registryNameVersion -Value $appVersion -PropertyType String -Force | Out-Null 
        
    ## Set the core Danone folder	            

    if(!(Test-Path $StandardFolder))
        {
        New-Item -Path $StandardFolder -Force -ItemType "directory" | Out-Null
        }
        

	##*===============================================
	##* END DANONE VARIABLE
	##*===============================================  

	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

        ##Set the History to PreInstallation
		 New-ItemProperty -Path $registryPathHistory -Name ${installDate}_${appFullName} -Value "$($installDic.PreI)_${installDate}" -PropertyType String -Force | Out-Null
		 
        ## Show Welcome Message, close application if required, and persist the prompt, block application execution       
         Show-InstallationWelcome -CloseApps $AppsToClose -PersistPrompt -BlockExecution

		 New-ItemProperty -Path $registryPathPackages -Name $registryNameResult -Value $installDic.E -PropertyType String -Force | Out-Null
		
		## Show Progress Message (with the default message)
		 Show-InstallationProgress -StatusMessage $InstallationText
		
		## <Perform Pre-Installation tasks here>
        New-ItemProperty -Path $registryPathPackages -Name $registrynameResult -Value $installDic.E -PropertyType String -Force | Out-Null

        New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand1 -Value '' -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand2 -Value '' -PropertyType String -Force | Out-Null
		New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand3 -Value '' -PropertyType String -Force | Out-Null
		

        # EXE Current Application - Uninstall

        if($EXE_ApplicationFileToUninstall1 -or $EXE_ApplicationFileToUninstall2 -or $EXE_ApplicationFileToUninstall3)
        {
        Write-Log -Message "*** Current EXE Applciation Uninstall Phase ***"
            if(!([string]::IsNullOrEmpty($EXE_ApplicationFileToUninstall1)))
            {
                if(Test-Path $EXE_ApplicationFileToUninstall1)
                {
                Write-Log -Message "Current Application Uninstallation String : $EXE_ApplicationFileToUninstall1 $EXE_UninstallParams1"
                Execute-Process -Path $EXE_ApplicationFileToUninstall1 -Parameters $EXE_UninstallParams1
                }
            }
            if(!([string]::IsNullOrEmpty($EXE_ApplicationFileToUninstall2)))
            {
                if(Test-Path $EXE_ApplicationFileToUninstall2)
                {
                Write-Log -Message "Current Application Uninstallation String : $EXE_ApplicationFileToUninstall2 $EXE_UninstallParams2"
                Execute-Process -Path $EXE_ApplicationFileToUninstall2 -Parameters $EXE_UninstallParams2
                }
            }
            if(!([string]::IsNullOrEmpty($EXE_ApplicationFileToUninstall3)))
            {
                if(Test-Path $EXE_ApplicationFileToUninstall3)
                {
                Write-Log -Message "Current Application Uninstallation String : $EXE_ApplicationFileToUninstall3 $EXE_UninstallParams3"
                Execute-Process -Path $EXE_ApplicationFileToUninstall3 -Parameters $EXE_UninstallParams3
                }
            }
        }
        # MSI Current Application - Uninstall

        if($MSI_ApplicationNameToUninstall1 -or $MSI_ApplicationNameToUninstall2 -or $MSI_ApplicationNameToUninstall3 -or $MSI_UninstallPath1 -or $MSI_UninstallPath2 -or $MSI_UninstallPath3)
        {
        Write-Log -Message "*** Current MSI Applciation Uninstall Phase ***" 
            if ($MSI_ApplicationNameToUninstall1) 
            {
            Write-Log -Message "Current Application To Uninstall - Name : $MSI_ApplicationNameToUninstall1"	    
            Remove-MSIApplications -Name $MSI_ApplicationNameToUninstall1
		    }
            else
                {
                if ($MSI_UninstallPath1)
                    {
                    Write-Log -Message "Current Application To Uninstall - Path : $MSI_UninstallPath1"
                    Execute-MSI -Action 'Uninstall' -Path $MSI_UninstallPath1
                    }
                }		 
            if ($MSI_ApplicationNameToUninstall2) 
            {
	        Write-Log -Message "Current Application To Uninstall - Name : $MSI_ApplicationNameToUninstall2"
            Remove-MSIApplications -Name $MSI_ApplicationNameToUninstall2
	    	}
            else
                {
                if ($MSI_UninstallPath2)
                    {
                    Write-Log -Message "Current Application To Uninstall - Path : $MSI_UninstallPath2"
                    Execute-MSI -Action 'Uninstall' -Path $MSI_UninstallPath2
                    }
                }		 
            if ($MSI_ApplicationNameToUninstall3) 
            {
            Write-Log -Message "Current Application To Uninstall - Name : $MSI_ApplicationNameToUninstall3"
            Remove-MSIApplications -Name $MSI_ApplicationNameToUninstall3
		    }
            else
                {
                if ($MSI_UninstallPath3)
                    {
                    Write-Log -Message "Current Application To Uninstall - Path : $MSI_UninstallPath3"
                    Execute-MSI -Action 'Uninstall' -Path $MSI_UninstallPath3
                    }
                }		 
        }

        # EXE Previous Application - Uninstall

        if($ApplicationPreviousUninstall1 -or $ApplicationPreviousUninstall2 -or $ApplicationPreviousUninstall3)
        {
        Write-Log -Message "*** Previous EXE Applciation Uninstall Phase ***"
            if(!([string]::IsNullOrEmpty($ApplicationPreviousUninstall1)))
            {
                if(Test-Path $ApplicationPreviousUninstall1)
                {
                Write-Log -Message "Previous Application Uninstallation String : $ApplicationPreviousUninstall1 $ApplicationPreviousUninstallParams1"
                Execute-Process -Path $ApplicationPreviousUninstall1 -Parameters $ApplicationPreviousUninstallParams1
                }
            }
            if(!([string]::IsNullOrEmpty($ApplicationPreviousUninstall2)))
                {
                if(Test-Path $ApplicationPreviousUninstall2)
                    {
                    Write-Log -Message "Previous Application Uninstallation String : $ApplicationPreviousUninstall2 $ApplicationPreviousUninstallParams2"
                    Execute-Process -Path $ApplicationPreviousUninstall2 -Parameters $ApplicationPreviousUninstallParams2
                    }
                }
            if(!([string]::IsNullOrEmpty($ApplicationPreviousUninstall3)))
                {
                if(Test-Path $ApplicationPreviousUninstall3)
                    {
                    Write-Log -Message "Previous Application Uninstallation String : $ApplicationPreviousUninstall3 $ApplicationPreviousUninstallParams3"
                    Execute-Process -Path $ApplicationPreviousUninstall3 -Parameters $ApplicationPreviousUninstallParams3
                    }
                }
        }

        # MSI Previous Application - Uninstall

        if($MSI_ApplicationPreviousUninstallPath1 -or $MSI_ApplicationPreviousUninstallPath2 -or $MSI_ApplicationPreviousUninstallPath3 -or $MSI_UninstallPath1 -or $MSI_UninstallPath2 -or $MSI_UninstallPath3)
        {
        Write-Log -Message "*** Previous MSI Applciation Uninstall Phase ***"
            if($MSI_ApplicationPreviousUninstallPath1)
            {
            Write-Log -Message "Previous MSI Application Uninstallation Path : $MSI_ApplicationPreviousUninstallPath1"
            Execute-MSI -Action 'Uninstall' -Path $MSI_ApplicationPreviousUninstallPath1
            }
            if($MSI_ApplicationPreviousUninstallPath2)
            {
            Write-Log -Message "Previous MSI Application Uninstallation Path : $MSI_ApplicationPreviousUninstallPath2"
            Execute-MSI -Action 'Uninstall' -Path $MSI_ApplicationPreviousUninstallPath2
            }
            if($MSI_ApplicationPreviousUninstallPath3)
            {
            Write-Log -Message "Previous MSI Application Uninstallation Path : $MSI_ApplicationPreviousUninstallPath3"
            Execute-MSI -Action 'Uninstall' -Path $MSI_ApplicationPreviousUninstallPath3
            }        
        }

		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
        ##Set the History to Installation
		New-ItemProperty -Path $registryPathHistory -Name ${installDate}_${appFullName} -Value "$($installDic.Inst)_${installDate}" -PropertyType String -Force | Out-Null

		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}
		
        ## <Perform Installation tasks here>
 
        # EXE Current Application - Install

        if($EXE_ApplicationFileToInstall1 -or $EXE_ApplicationFileToInstall2 -or $EXE_ApplicationFileToInstall3)
        {
        Write-Log -Message "*** EXE Applciation Install Phase ***"
            if($EXE_ApplicationFileToInstall1)
            {
            Write-Log -Message "Application to Install First String : $EXE_ApplicationFileToInstall1 $InstallParams1"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand1 -Value $utilsEXEInstCmdDir1 -PropertyType String -Force | Out-Null 
            Execute-Process -Path $EXE_ApplicationFileToInstall1 -Parameters $InstallParams1
            }
            if($EXE_ApplicationFileToInstall2)
            {
            Write-Log -Message "Application to Install Second String : $EXE_ApplicationFileToInstall2 $InstallParams2"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand2 -Value $utilsEXEInstCmdDir2 -PropertyType String -Force | Out-Null 
            Execute-Process -Path $EXE_ApplicationFileToInstall2 -Parameters $InstallParams2
            }
            if($EXE_ApplicationFileToInstall3)
            {
            Write-Log -Message "Application to Install Second String : $EXE_ApplicationFileToInstall3 $InstallParams3"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand3 -Value $utilsEXEInstCmdDir3 -PropertyType String -Force | Out-Null 
            Execute-Process -Path $EXE_ApplicationFileToInstall3 -Parameters $InstallParams3
            }
        }

        # MSI Current Application - Install

        if($MSI_ApplicationFileToInstall1 -or $MSI_ApplicationFileToInstall2 -or $MSI_ApplicationFileToInstall3)
        {
        Write-Log -Message "*** MSI Applciation Install Phase ***"
            if($MSI_ApplicationFileToInstall1)
            {
            if($MSI_InstallTransform1)
                {
                Write-Log -Message "MSI Application to Install First String information : $MSI_ApplicationFileToInstall1 TRANSFORMS=$MSI_InstallTransform1 $MSI_InstallParams1"
                New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand1 -Value $utilsMSIInstCmdDir11 -PropertyType String -Force | Out-Null 
                Execute-MSI -Action 'Install' -Path $MSI_ApplicationFileToInstall1 -Transform $MSI_InstallTransform1 -Parameters $MSI_InstallParams1
                }
                else
                    {
                    Write-Log -Message "MSI Application to Install First String information : $MSI_ApplicationFileToInstall1 $MSI_InstallParams1"
                    New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand1 -Value $utilsMSIInstCmdDir1 -PropertyType String -Force | Out-Null 
                    Execute-MSI -Action 'Install' -Path $MSI_ApplicationFileToInstall1 -Parameters $MSI_InstallParams1
                    }
            }
            if($MSP_ApplicationFileToInstall1)
            {
            Write-Log -Message "MSP Application to Install First information : $MSP_ApplicationFileToInstall1"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand1 -Value $utilsMSIInstCmdDir111 -PropertyType String -Force | Out-Null     
            Execute-MSP -Path $MSP_ApplicationFileToInstall1
            }
            if($MSI_ApplicationFileToInstall2)
            {
            if($MSI_InstallTransform2)
                {
                Write-Log -Message "MSI Application to Install First String information : $MSI_ApplicationFileToInstall2 TRANSFORMS=$MSI_InstallTransform2 $MSI_InstallParams2"
                New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand2 -Value $utilsMSIInstCmdDir22 -PropertyType String -Force | Out-Null     
                Execute-MSI -Action 'Install' -Path $MSI_ApplicationFileToInstall2 -Transform $MSI_InstallTransform2 -Parameters $MSI_InstallParams2
                }
                else
                    {
                    Write-Log -Message "MSI Application to Install First String information : $MSI_ApplicationFileToInstall2 $MSI_InstallParams2"
                    New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand2 -Value $utilsMSIInstCmdDir2 -PropertyType String -Force | Out-Null     
                    Execute-MSI -Action 'Install' -Path $MSI_ApplicationFileToInstall2 -Parameters $MSI_InstallParams2
                    }
            }
            if($MSP_ApplicationFileToInstall2)
            {
            Write-Log -Message "MSP Application to Install First information : $MSP_ApplicationFileToInstall2"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand2 -Value $utilsMSIInstCmdDir222 -PropertyType String -Force | Out-Null     
            Execute-MSP -Path $MSP_ApplicationFileToInstall2
            }
            if($MSI_ApplicationFileToInstall3)
            {
            if($MSI_InstallTransform3)
                {
                Write-Log -Message "MSI Application to Install First String information : $MSI_ApplicationFileToInstall3 TRANSFORMS=$MSI_InstallTransform3 $MSI_InstallParams3"
                New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand3 -Value $utilsMSIInstCmdDir33 -PropertyType String -Force | Out-Null     
                Execute-MSI -Action 'Install' -Path $MSI_ApplicationFileToInstall3 -Transform $MSI_InstallTransform3 -Parameters $MSI_InstallParams3
                }
                else
                    {
                    Write-Log -Message "MSI Application to Install First String information : $MSI_ApplicationFileToInstall3 $MSI_InstallParams3"
                    New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand3 -Value $utilsMSIInstCmdDir3 -PropertyType String -Force | Out-Null     
                    Execute-MSI -Action 'Install' -Path $MSI_ApplicationFileToInstall3 -Parameters $MSI_InstallParams3
                    }
            }
            if($MSP_ApplicationFileToInstall3)
            {
            Write-Log -Message "MSP Application to Install First information : $MSP_ApplicationFileToInstall3"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand3 -Value $utilsMSIInstCmdDir333 -PropertyType String -Force | Out-Null
            Execute-MSP -Path $MSP_ApplicationFileToInstall3
            }
        }

		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
        ##Set the History to PostInstallation
        New-ItemProperty -Path $registryPathHistory -Name ${installDate}_${appFullName} -Value "$($installDic.PostI)_${installDate}" -PropertyType String -Force | Out-Null

		## <Perform Post-Installation tasks here>

        if ($mainExitCode -eq 0 -Or $mainExitCode -eq 1707 -Or $mainExitCode -eq 3010 -Or $mainExitCode -eq 1641) 
            {               
            New-ItemProperty -Path $registryPathPackages -Name $registrynameResult -Value $installDic.Installed -PropertyType String -Force | Out-Null                
            New-ItemProperty -Path $registryPathPackages -Name $registryNameResultCode -Value $mainExitCode -PropertyType String -Force | Out-Null
            #Creates the history in DANONE\Applications
            New-ItemProperty -Path $registryPathHistory -Name ${installDate}_${appFullName} -Value "$($installDic.Installed)_${installDate}" -PropertyType String -Force | Out-Null           
            }
            else
                {                
                New-ItemProperty -Path $registryPathPackages -Name $registrynameResult -Value $installDic.E -PropertyType String -Force | Out-Null                 
                New-ItemProperty -Path $registryPathPackages -Name $registryNameResultCode -Value $mainExitCode -PropertyType String -Force | Out-Null                
                #Creates the history in DANONE\Applications
                New-ItemProperty -Path $registryPathHistory -Name ${installDate}_${appFullName} -Value "$($installDic.Installed)_${installDate}" -PropertyType String -Force | Out-Null
                }

		
		## Display a message at the end of the install
		If (-not $useDefaultMsi -and $DeployMode -eq 'Interactive') {Show-InstallationPrompt -Message $TextAfterInstallation -ButtonRightText 'OK' -Icon Information -Timeout 5 -NoWait}
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
        ##Set the History to PostUninstallation
		New-ItemProperty -Path $registryPathHistory -Name ${installDate}_${appFullName} -Value "$($installDic.PreU)_${installDate}" -PropertyType String -Force | Out-Null

		## Show Welcome Message, close application if required, and persist the prompt, block application execution
        Show-InstallationWelcome -CloseApps $AppsToClose -PersistPrompt -BlockExecution

		## Show Progress Message (with the default message)
		Show-InstallationProgress -StatusMessage $UninstallationText
		
		## <Perform Pre-Uninstallation tasks here>
		New-ItemProperty -Path $registryPathPackages -Name $registrynameResult -Value $installDic.E -PropertyType String -Force | Out-Null

        New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand1 -Value '' -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand2 -Value '' -PropertyType String -Force | Out-Null
		New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand3 -Value '' -PropertyType String -Force | Out-Null
				

		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
        ##Set the History to PostUninstallation
		 New-ItemProperty -Path $registryPathHistory -Name ${installDate}_${appFullName} -Value "$($installDic.Unst)_${installDate}" -PropertyType String -Force | Out-Null
		
		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		
        # <Perform Uninstallation tasks here>

        # EXE Current Application - Uninstall

        if($EXE_ApplicationFileToUninstall1 -or $EXE_ApplicationFileToUninstall2 -or $EXE_ApplicationFileToUninstall3)
        {
        Write-Log -Message "*** EXE Applciation Uninstall Phase ***"
            if($EXE_ApplicationFileToUninstall1)
            {
            Write-Log -Message "Current Application Uninstallation String : $EXE_ApplicationFileToUninstall1 $EXE_UninstallParams1"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand1 -Value $utilsEXEUninstCmdDir1 -PropertyType String -Force | Out-Null
            Execute-Process -Path $EXE_ApplicationFileToUninstall1 -Parameters $EXE_UninstallParams1
            }
            if($EXE_ApplicationFileToUninstall2)
            {
            Write-Log -Message "Current Application Uninstallation String : $EXE_ApplicationFileToUninstall2 $EXE_UninstallParams2"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand2 -Value $utilsEXEUninstCmdDir2 -PropertyType String -Force | Out-Null
            Execute-Process -Path $EXE_ApplicationFileToUninstall2 -Parameters $EXE_UninstallParams2
            }
            if($EXE_ApplicationFileToUninstall3)
            {
            Write-Log -Message "Current Application Uninstallation String : $EXE_ApplicationFileToUninstall3 $EXE_UninstallParams3"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand3 -Value $utilsEXEUninstCmdDir3 -PropertyType String -Force | Out-Null
            Execute-Process -Path $EXE_ApplicationFileToUninstall3 -Parameters $EXE_UninstallParams3
            }
        }
        # MSI Current Application - Uninstall

        if($MSI_ApplicationNameToUninstall1 -or $MSI_ApplicationNameToUninstall2 -or $MSI_ApplicationNameToUninstall3 -or $MSI_UninstallPath1 -or $MSI_UninstallPath2 -or $MSI_UninstallPath3)
        {
        Write-Log -Message "*** MSI Applciation Uninstall Phase ***"
            if ($MSI_ApplicationNameToUninstall1) 
            {
            Write-Log -Message "Current Application To Uninstall - Name : $MSI_ApplicationNameToUninstall1"	    
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand1 -Value $utilsMSIUninstCmdDir1 -PropertyType String -Force | Out-Null
            Remove-MSIApplications -Name $MSI_ApplicationNameToUninstall1
    		}
            else
                {
                if ($MSI_UninstallPath1)
                    {
                    Write-Log -Message "Current Application To Uninstall - Path : $MSI_UninstallPath1"
                    New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand1 -Value $utilsMSIUninstCmdDir11 -PropertyType String -Force | Out-Null
                    Execute-MSI -Action 'Uninstall' -Path $MSI_UninstallPath1
                    }
                }		 
            if ($MSI_ApplicationNameToUninstall2) 
            {
	        Write-Log -Message "Current Application To Uninstall - Name : $MSI_ApplicationNameToUninstall2"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand2 -Value $utilsMSIUninstCmdDir2 -PropertyType String -Force | Out-Null
            Remove-MSIApplications -Name $MSI_ApplicationNameToUninstall2
	    	}
            else
                {
                if ($MSI_UninstallPath2)
                    {
                    Write-Log -Message "Current Application To Uninstall - Path : $MSI_UninstallPath2"
                    New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand2 -Value $utilsMSIUninstCmdDir22 -PropertyType String -Force | Out-Null
                    Execute-MSI -Action 'Uninstall' -Path $MSI_UninstallPath2
                    }
                }		 
            if ($MSI_ApplicationNameToUninstall3) 
            {
            Write-Log -Message "Current Application To Uninstall - Name : $MSI_ApplicationNameToUninstall3"
            New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand3 -Value $utilsMSIUninstCmdDir3 -PropertyType String -Force | Out-Null
            Remove-MSIApplications -Name $MSI_ApplicationNameToUninstall3
	    	}
            else
                {
                if ($MSI_UninstallPath3)
                    {
                    Write-Log -Message "Current Application To Uninstall - Path : $MSI_UninstallPath3"
                    New-ItemProperty -Path $registryPathPackages -Name $registryNameInstallCommand3 -Value $utilsMSIUninstCmdDir33 -PropertyType String -Force | Out-Null
                    Execute-MSI -Action 'Uninstall' -Path $MSI_UninstallPath3
                    }
                }		 
        }

		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
        ##Set the History to PostUninstallation
		New-ItemProperty -Path $registryPathHistory -Name ${installDate}_${appFullName} -Value "$($installDic.PostU)_${installDate}" -PropertyType String -Force | Out-Null
		
		## <Perform Post-Uninstallation tasks here>
		#Show-InstallationProgress -StatusMessage $TextAfterUninstallation

       if ($mainExitCode -eq 0 -Or $mainExitCode -eq 1707 -Or $mainExitCode -eq 3010 -Or $mainExitCode -eq 1641) {           
            New-ItemProperty -Path $registryPathPackages -Name $registrynameResult -Value $installDic.Uninstalled -PropertyType String -Force | Out-Null            
            New-ItemProperty -Path $registryPathPackages -Name $registryNameResultCode -Value $mainExitCode -PropertyType String -Force | Out-Null
		    
            #Creates the history in DANONE\Applications
            New-ItemProperty -Path $registryPathHistory -Name ${installDate}_${appFullName} -Value "$($installDic.Uninstalled)_${installDate}" -PropertyType String -Force | Out-Null
            
        }else {            
            New-ItemProperty -Path $registryPathPackages -Name $registrynameResult -Value $installDic.E -PropertyType String -Force | Out-Null            
            New-ItemProperty -Path $registryPathPackages -Name $registryNameResultCode -Value $mainExitCode -PropertyType String -Force | Out-Null
                
            #Creates the history in DANONE\Applications
            New-ItemProperty -Path $registryPathHistory -Name ${installDate}_${appFullName} -Value "$($installDic.Uninstalled)_${installDate}" -PropertyType String -Force | Out-Null
         }
        
        If (-not $useDefaultMsi -and $DeployMode -eq 'Interactive') {Show-InstallationPrompt -Message $TextAfterUninstallation -ButtonRightText 'OK' -Icon Information -Timeout 5 -NoWait }
		
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}