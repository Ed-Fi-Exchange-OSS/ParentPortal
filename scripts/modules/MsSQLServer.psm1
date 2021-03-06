# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

############################################################

# Author: Douglas Loyo, Sr. Solutions Architect @ MSDF

# Description: Module contains a collection of MsSQL Server utility functions.

# Note: This powershell has to be ran with Elevated Permissions (As Administrator) and in a x64 environment.

############################################################

function Install-SQLServerModule
{
    Write-Host "Ensuring the Powershell SQLModule is available."
    # Check to see if the module has been installed first.
    If(-Not (Get-InstalledModule | Where-Object -Property Name -eq SqlServer)) {
        Install-Module -Name SqlServer -Force
    }

    # Lets make sure we have the module imported.
    If(-Not (Get-Module SqlServer)) {
        Import-Module SqlServer -Force
    }
}

function Get-MsSQLServerDependency {
    # MsSQL Server
    if (!(Test-Path 'HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL')) { Write-Error "Error: Missing Prerequisites. The MsSQL Server Prerequisit is missing." -ErrorAction Stop }
}

function Get-MsSQLServerVersion($serverInstance) {
    If(Test-Path 'HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL') {
        $server = New-Object Microsoft.SqlServer.Management.Smo.Server $serverInstance
        return $server.Version.Major
    } else {return 0}
}

function Find-MsSQLServerDependency($serverInstance) {
    If(Test-Path 'HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL') {
        $ver = Get-MsSQLServerVersion $serverInstance
        If($ver -lt 14){
            Write-BigMessage "Detected SQL Server Version $ver Already Installed" "This Quick Start requires MsSQL Server 2017 or higher."
            Write-Error "Please install apropriate version of SQL Server." -ErrorAction Stop
        }
    } else { Write-Host "No Ms SQL Server Installed." }
}

function Get-MsSQLDataFileDestination {
    $2017Path = "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA"
    $2019Path = "C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA"
    if(Test-Path $2017Path){ return $2017Path }
    if(Test-Path $2019Path){ return $2019Path }
    #Write-Error "SQL Server Path not Found. Please Install MsSQL Server or review the path $2019Path" -ErrorAction Stop
}

function Get-MsSQLLogFileDestination {
    $2017Path = "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA"
    $2019Path = "C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA"
    if(Test-Path $2017Path){ return $2017Path }
    if(Test-Path $2019Path){ return $2019Path }
   #Write-Error "SQL Server Path not Found. Please Install MsSQL Server or review the path $2019Path" -ErrorAction Stop
}


function Install-MsSQLServerExpress {
    if(!(Test-Path 'HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL'))
    {
        Write-Host "Installing: MsSQL Server Express..."
        choco install sql-server-express -o -ia "'/IACCEPTSQLSERVERLICENSETERMS /Q /ACTION=install /INSTANCEID=MSSQLSERVER /INSTANCENAME=MSSQLSERVER /SECURITYMODE=SQL /SAPWD=EdfiUs3r /TCPENABLED=1 /UPDATEENABLED=FALSE'" -f -y
        #Refres env and reload path in the Shell
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        refreshenv
    } else {
        Write-Host "Skipping: MsSQL Express there is already a SQL Server installed."
    }
}
function Install-MsSSMS {
    if(!(Find-SoftwareInstalled 'SQL Server Management Studio'))
    {
        Write-Host "Installing: SSMS  Sql Server Management Studio..."
        choco install sql-server-management-studio -y
    }else{Write-Host "Skipping: SSMS  Sql Server Management Studio as it is already installed."}
}

Function Add-SQLUser($serverInstance, $User, $Role) {
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server $serverInstance
    if ($server.Logins.Contains($User)) { Write-Host "     Skipping: User '$User' already part of the MsSQL Logins" }
    else {
        # Add the WindowsUser
        $SqlUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $server, $User
        $SqlUser.LoginType = 'WindowsUser'
        $sqlUser.PasswordPolicyEnforced = $false
        $SqlUser.Create()

        # Add to the role.
        $serverRole = $server.Roles | where {$_.Name -eq $Role}
        $serverRole.AddMember("$User")
    }
}

Function Add-SQLUserWithPassword($serverInstance, $DatabaseName, $User, $Pass, $Role) {
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server $serverInstance

    if ($server.Logins.Contains($User)) { Write-Host "     Skipping: User '$User' already part of the MsSQL Logins" }
    else {
        Write-Host "Creating SQL server login $User..."
        # Create the SQL Login
        $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $server, $User
        $login.Name = $User
        $login.LoginType = 'SqlLogin'
        $login.PasswordPolicyEnforced = $false
        $login.PasswordExpirationEnabled = $false
        $login.Create($Pass)
    }

    $database = $server.Databases[$DatabaseName]
    if($database.Users.Contains($User)){Write-Host "     Skipping: Adding User '$User' to Db '$DatabaseName' as its already associated." }
    else {
        Write-Host "Adding $User to database $DatabaseName"
        # Add to DB with the role.
        $newUser =  New-Object Microsoft.SqlServer.Management.Smo.User($server.Databases[$DatabaseName], $User)
        $newUser.Login = $User
        $newUser.Create()
        $newUser.AddToRole($Role)
    }
}

Function Restore-Database($db, $dbDestinationName, $backupLocation, $dataFileDestination, $logFileDestination) {
    $originDbName = $db.src;
    $newDbName = $dbDestinationName;

	$dataFileOrigin = $originDbName
	$logFileOrigin  = $originDbName+"_log"
	$dataFileLocation = "$dataFileDestination\$newDbName.mdf"
	$logFileLocation  = "$logFileDestination\$newDbName"+"_log.ldf"

	Write-Host "     Restoring database $newDbName"

	#Some special cases...

	if($newDbName -like '*Populated_Template*' )
	{
	    $dataFileOrigin = "EdFi_Ods_Populated_Template"
	    $logFileOrigin = "EdFi_Ods_Populated_Template_log"
	}
    #TODO: Change DB in nuget $urlODSDatabase = "https://www.myget.org/F/ed-fi/api/v2/package/EdFi.Suite3.Ods.Populated.Template/5.1.0"
    if($newDbName -eq 'Ed-Fi_v5.1.0_ODS_FamilyEngagementQuickStart' )
	{
	    $dataFileOrigin = "EdFi_Ods_Populated_Template_Test"
	    $logFileOrigin = "EdFi_Ods_Populated_Template_Test_log"
	}
	#Some special cases...
	if($newDbName -like '*minimal*')
	{
	    $dataFileOrigin = "EdFi_Ods_Minimal_Template"
	    $logFileOrigin = "EdFi_Ods_Minimal_Template_log"
	}

	$RelocateData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($dataFileOrigin, $dataFileLocation)
    $RelocateLog = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($logFileOrigin, $logFileLocation)

    $DBServer = New-Object Microsoft.SqlServer.Management.Smo.Server '.'
    $DBServer.KillAllProcesses($newDbName)
    if (!($null -eq $DBServer.Databases[$newDbName].UserAccess)){
        $DBServer.Databases[$newDbName].UserAccess = [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]::Single #set to single user
    }

    # Write-Host "***Debugging***"
    # Write-Host "Data Relocation:"
    # Write-Host "        origin: $dataFileOrigin"
    # Write-Host "        destin: $dataFileLocation"
    # Write-Host "Log Relocation:"
    # Write-Host "        origin: $logFileOrigin"
    # Write-Host "        destin: $logFileLocation"
    # Write-Host "    Running Command:> Restore-SqlDatabase -ServerInstance '.' -Database $newDbName -BackupFile $backupLocation$originDbName.bak -RelocateFile @($RelocateData,$RelocateLog) -ReplaceDatabase"
    $ver = Get-MsSQLServerVersion "."
    Write-Host "MsSQL Server Version $ver"
    if($ver -eq 14) {
        Restore-SqlDatabase -ServerInstance "." -Database "$newDbName" -BackupFile "$backupLocation$originDbName.bak" -ReplaceDatabase
    }
    else {
        Restore-SqlDatabase -InputObject $DBServer -Database "$newDbName" -BackupFile "$backupLocation$originDbName.bak" -ReplaceDatabase -RelocateFile @($RelocateData,$RelocateLog)
    }
}

function Remove-SqlDatabase($databaseName) {
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server(".")
    $db = $server.databases[$databaseName]
    if ($db) {
      $server.KillAllprocesses($databaseName)
      $db.Drop()
    }
  }

Function Get-DestDbName($dbmetadata, $prefix, $sufix) {

    $dbname = if($dbmetadata.dest){ $dbmetadata.dest }else{ $dbmetadata.src }

    if($prefix -And $sufix){"$prefix$dbname$sufix"; return}
    if($prefix){"$prefix$dbname"; return}
    if($sufix){"$dbname$sufix"; return}

    $dbname
}

Function Enable-SQLServerTCPIP() {
    $wmi = new-object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer')
    $computerName = (get-item env:\computername).Value
    $uri = "ManagedComputer[@Name='$computerName']/ ServerInstance[@Name='MSSQLSERVER']/ServerProtocol[@Name='Tcp']"
    $Tcp = $wmi.GetSmoObject($uri)
    $Tcp.IsEnabled = $true
    $Tcp.Alter()
}