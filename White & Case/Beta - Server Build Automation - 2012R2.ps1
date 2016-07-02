﻿#######################
#Function Declarations#
#######################
Function Write-Log
{
	<#
	.SYNOPSIS
		A function to write ouput messages to a logfile.
	
	.DESCRIPTION
		This function is designed to send timestamped messages to a logfile of your choosing.
		Use it to replace something like write-host for a more long term log.
	
	.PARAMETER Message
		The message being written to the log file.
	
	.EXAMPLE
		PS C:\> Write-Log -Message 'This is the message being written out to the log.' 
	
	.NOTES
		N/A
#>
	
	Param
	(
		[Parameter(Mandatory = $True, Position = 0)]
		[String]$Message
	)

    
	add-content -path $LogFilePath -value ($Message)
}


#######################
#Variable Declarations#
#######################

$secpasswd = ConvertTo-SecureString $ENV:ADMPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($ENV:ADMUsername, $secpasswd)
$Target = $ENV:Targetmachine
$LogFilePath = ''


#####################################
#Begin Remote Machine Code Execution#
#####################################

Invoke-command -scriptblock {

######################
#Step 1 - Disable UAC#
######################
	
	New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system `
					 -Name EnableLUA `
					 -PropertyType DWord `
					 -Value 0 `
					 -Force
	
	Write-Log -Message "UAC Disabled."

###########################
#Step 2 - Set Audit policy#
###########################

    auditpol /set /category:"account logon" /success:enable /failure:enable | out-null
    auditpol /set /category:"Account Management" /success:enable /failure:enable | out-null
    auditpol /set /category:"logon/logoff" /success:enable /failure:enable | out-null
    auditpol /set /category:"Object Access" /success:enable /failure:enable | out-null
    auditpol /set /category:"Policy Change" /success:enable /failure:disable | out-null
    auditpol /set /category:"Privilege Use" /success:disable /failure:enable | out-null
	auditpol /set /category:"System" /success:enable /failure:disable | out-null
	
	Write-Log -Message "Audit Policy Set"


#############################
#Step 3 - Set Event Log Size#
#############################
	
	New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\Eventlog\Application' `
					 -Name MaxSize -PropertyType Dword `
					 -Value 100663296 `
					 -Force
	
	New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\Eventlog\Security' `
					 -Name MaxSize `
					 -PropertyType Dword `
					 -Value 100663296 `
					 -Force
	
	New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\Eventlog\System' `
					 -Name MaxSize `
					 -PropertyType Dword `
					 -Value 100663296 `
					 -Force
	
	Write-Log -Message "Event Log Size Set."

################################
#Step 4 - Disable Print Spooler#
################################

    Stop-Service spooler
	Set-Service -Name spooler -StartupType Disabled
	Write-Log -Message "Sprint Spooler Disabled"

##############################
#Step 5 - Disable Hibernation#
##############################
	
	powercfg.exe /hibernate off
	Write-Log -Message "Hibernation Disabled"

#############################
#Step 6 - Config Memory Dump#
#############################
	
	New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\CrashControl\' `
					 -Name CrashDumpEnabled `
					 -PropertyType Dword `
					 -Value 3 `
					 -Force
	
	New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\CrashControl\' `
					 -Name MinidumpDir `
					 -PropertyType ExpandString  `
					 -Value "c:\" `
					 -Force
	
	Write-Log -Message "Memory Dump Settings Configured"

######################################
#Step 7 - Rename My Computer Shortcut#
######################################

    $My_Computer = 17
    $Shell = new-object -comobject shell.application
    $NSComputer = $Shell.Namespace($My_Computer)
	$NSComputer.self.name = $env:COMPUTERNAME
	
	Write-Log -Message "'My Computer' shortcut renamed."

##########################################
#Step 8 - Set PowerShell Execution policy#
##########################################
	
	New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Powershell\1\ShellIds\Microsoft.Powershell\' `
					 -Name ExecutionPolicy `
					 -PropertyType String `
					 -Value Unrestricted `
					 -Force
	
	New-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell\' `
					 -Name ExecutionPolicy `
					 -PropertyType String `
					 -Value Unrestricted `
					 -Force
	
	Write-Log -Message "PowerShell execution policy set."

###########################################
#Step 9 - Create Software and Scripts Dirs#
###########################################
	
	New-Item -ItemType Directory `
			 -Path "$env:windir\Software" `
			 -Force
	
	New-Item -ItemType Directory `
			 -Path "$env:windir\Software\Scripts" `
			 -Force
	
	Write-Log -Message "Software and Scripts Directory Created"

################################################
#Step 10 - Sets the Temp Environmental Variable#
################################################

    [Environment]::SetEnvironmentVariable("Temp", "$env:windir\Temp", "User")
	[Environment]::SetEnvironmentVariable("Tmp", "$env:windir\Temp", "User")
	
	Write-Log -Message "Temp Environmental Variables Set."

##############################
#Step 11 - Edits Manufacturer#
##############################
	
	New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation\' `
					 -Name Manufacturer `
					 -PropertyType String `
					 -Value "Server 2012 R2 Build Procedure v2.0, Build Automation Script v2.0" `
					 -Force
	
	Write-Log -Message " Manufacturer Set to Custom Value."
	
######################################
#Step 12 - Disabled Automatic Updates#
######################################
	
	New-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU' `
					 -Name NoAutoUpdate `
					 -PropertyType DWord `
					 -Value 1 `
					 -Force
	
	Write-Log -Message "Automatic updates Disabled"

###################################
#Step 13 - Sets Disk Timeout Value#
###################################
	
	New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Disk' `
					 -Name TimeoutValue `
					 -PropertyType DWord `
					 -Value 190 `
					 -Force
	
	Write-Log -Message "Disk Timeout Value Set"

################################
#Step 14 - Sets Console Options#
################################
	
	New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Disk' `
					 -Name TimeoutValue `
					 -PropertyType DWord `
					 -Value 190 `
					 -Force
	
	Write-Log -Message "Console Options Set."

################################
#Step 15 - Remove Desktop Icons#
################################
	
	New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' `
					 -Name { 20D04FE0-3AEA-1069-A2D8-08002B30309D } `
					 -PropertyType DWord `
					 -Value 0 `
					 -Force
	
	New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' `
					 -Name { F02C1A0D-BE21-4350-88B0-7367FC96EF3C } `
					 -PropertyType DWord `
					 -Value 0 `
					 -Force
	
	Write-Log -Message "Specific Desktop Icons Hidden."

###############################
#Step 16 - Disable logon Tasks#
###############################
	
	New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager' `
					 -Name DoNotOpenServerManagerAtLogon `
					 -PropertyType DWord `
					 -Value 1 `
					 -Force
	
	New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe' `
					 -Name DoNotOpenInitialConfigurationTasksAtLogon `
					 -PropertyType DWord `
					 -Value 1 `
					 -Force
	
	Write-Log -Message "Specific Logon Tasks Disabled."

#######################################
#Step 17 - Enable RDP from all clients#
#######################################
	
	New-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\Control\Terminal Server' `
					 -Name fDenyTSConnections `
					 -PropertyType DWord `
					 -Value 0 `
					 -Force
	
	New-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\Control\Terminal Server\WinStations\RDP-Tcp' `
					 -Name UserAuthentication `
					 -PropertyType DWord `
					 -Value 0 `
					 -Force
	
	Write-Log -Message "RDP Enabled for all clients."

############################################
#Step 18 - Disables IPV6 For all Interfaces#
############################################
	
	New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' `
					 -Name DisabledComponents `
					 -PropertyType DWord `
					 -Value 0xFFFFFFFF `
					 -Force
	
	Write-Log -Message "IPV6 Disabled for all interfaces."

#######################################
#Step 19 - Set DNS search suffix Order#
#######################################
	
	New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\TCPIP\Parameters' `
					 -Name SearchList `
					 -PropertyType String `
					 -Value "wcnet.whitecase.com,americas.whitecase.com,emea.whitecase.com,asiapac.whitecase.com,nm.whitecase.com,whitecase.com" `
					 -Force
	
	Write-Log -Message "DNS Suffix Search Order Set"

####################################
#Step 20 - Disable Windows Firewall#
####################################
	
	netsh advfirewall set allprofiles state off
	
	Write-Log -Message "Windows Firewall Disabled."

################################
#Step 21 - Add Windows Features#
################################

    Import-Module Servermanager -DisableNameChecking
    Add-WindowsFeature SNMP-Services
	Add-WindowsFeature Telnet-Client
	
	Write-Log -Message "SNMP Services and Telnet Client enabled."

################################
#Step 22 - Rename Admin Account#
################################

    $admin=[adsi]("WinNT://./administrator, user")
	$admin.psbase.rename("WC")
	
	Write-Log -Message "Admin account renamed."

###############################
#Step 23 - Creates Dummy Admin#
###############################

    $computer = [ADSI]"WinNT://."
    $user = $computer.Create("user", "Administrator")
    $user.SetPassword("SuperPassword123!elugeu74ufj74")
    $user.SetInfo()
    $user.psbase.InvokeSet('AccountDisabled', $true)
	$user.SetInfo()
	
	Write-Log -Message "Dummy Admin Account Created."

} -ComputerName $Target -Credential $Credential

