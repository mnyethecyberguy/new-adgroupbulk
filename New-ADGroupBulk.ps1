# Author:		Michael Nye
# Date:         11-08-2013
# Script Name:  New-ADGroupBulk
# Version:      1.0
# Description:  Script to create new group objects in Active Directory.
# Change Log:	v1.0:	Initial Release

# ------------------- NOTES -----------------------------------------------
# SAMPLE INPUTFILE
# --- First row is the column headers and must match below!
# --- Values with commas or space must be in quotes " ".
# --- Inputfile name should match script name and be located in same directory as script.
# -------------------------------------------------------------------------
# SamAccountName,GroupType,GroupScope,CreateOU,Description,DisplayName
# TestGroup1,Security,Global,"OU=Groups,DC=mydomain,DC=com","Test group description",TestGroup1
#
# INPUTFILE HEADER		VALUES								MAPPING
# ----------------		------								-------
# SamAccountName		TestGroup1							SamAccountName
# GroupType				Security/Distribution				GroupCategory
# GroupScope			DomainLocal/Global/Universal		GroupScope
# CreateOU			    OU=Groups,DC=mydomain,DC=com		(Target OU to create the group)
# Description			"My Description"					description
# DisplayName			TestGroup1						    displayName
# -------------------------------------------------------------------------

# ------------------- IMPORT AD MODULE (IF NEEDED) ------------------------
Import-Module ActiveDirectory


# ------------------- BEGIN USER DEFINED VARIABLES ------------------------
$SCRIPTNAME    	= "New-ADGroupBulk"
$SCRIPTVERSION 	= "1.0"

# Server attribute to set which domain to create users
$domainFQDN     = "mydomain.com"

# ------------------- END OF USER DEFINED VARIABLES -----------------------


# ------------------- BEGIN MAIN SCRIPT VARIABLES -------------------------
# Establish variable with date/time of script start
$Scriptstart = Get-Date -Format G

$strCurrDir 	= split-path $MyInvocation.MyCommand.Path
$strLogFolder 	= "$SCRIPTNAME -{0} {1}" -f ($_.name -replace ", ","-"),($Scriptstart -replace ":","-" -replace "/","-")
$strLogPath 	= "$strCurrDir\logs"
$INPUTFILE 		= "$strCurrDir\$SCRIPTNAME.csv"

# Create log folder for run and logfile name
New-Item -Path $strLogPath -name $strLogFolder -itemtype "directory" -Force > $NULL
$LOGFILE 		= "$strLogPath\$strLogFolder\$SCRIPTNAME.log"

# ------------------- END MAIN SCRIPT VARIABLES ---------------------------


# ------------------- DEFINE FUNCTIONS - DO NOT MODIFY --------------------

Function Writelog ($LogText)
{
	$date = Get-Date -format G
	
    write-host "$date $LogText"
	write-host ""
	
    "$date $LogText" >> $LOGFILE
	"" >> $LOGFILE
}

Function GetString ($obj)
{
	if($null -eq $obj)
	{
		return ''
	}
	
	$string = $obj.ToString()
	return $string.Trim()
}

Function BeginScript () {
    Writelog "-------------------------------------------------------------------------------------"
    Writelog "**** BEGIN SCRIPT AT $Scriptstart ****"
    Writelog "**** Script Name:     $SCRIPTNAME"
    Writelog "**** Script Version:  $SCRIPTVERSION"
    Writelog "**** Input File:      $INPUTFILE"
    Writelog "-------------------------------------------------------------------------------------"

    $error.clear()
}

Function EndScript () {
    Writelog "-------------------------------------------------------------------------------------"
    Writelog "**** SCRIPT RESULTS ****"
    Writelog "**** SUCCESS Count = $CountSuccess"
    Writelog "**** ERROR Count   = $CountError"
    Writelog "-------------------------------------------------------------------------------------"

	$Scriptfinish = Get-Date -Format G
	$span = New-TimeSpan $Scriptstart $Scriptfinish
	
  	Writelog "-------------------------------------------------------------------------------------"
  	Writelog "**** $SCRIPTNAME script COMPLETED at $Scriptfinish ****"
	Writelog $("**** Total Runtime: {0:00} hours, {1:00} minutes, and {2:00} seconds ****" -f $span.Hours,$span.Minutes,$span.Seconds)
	Writelog "-------------------------------------------------------------------------------------"
}

# ------------------- END OF FUNCTION DEFINITIONS -------------------------


# ------------------- SCRIPT MAIN - DO NOT MODIFY -------------------------

BeginScript

$CountError = 0
$CountSuccess = 0


Import-Csv $INPUTFILE | ForEach-Object -Process {

	# Check to see if the group already exists before trying to create
	Try
	{
		$exists = Get-ADGroup -Server $domainFQDN -LDAPFilter "(sAMAccountName=$($_.SamAccountName))"
	}
	Catch { }
	
	If (!$exists)
	{
		$samName 		= GetString($_.SamAccountName)
		$groupType 		= GetString($_.GroupType)
		$groupScope 	= GetString($_.GroupScope)
		$createOU 	    = GetString($_.CreateOU)
		$description 	= GetString($_.Description)
		$displayName	= GetString($_.DisplayName)
		
		# Create group object and populate attributes based off the input CSV.
		$group = New-ADGroup -Server $domainFQDN -SamAccountName $samName -Name $samName -GroupScope $groupScope -GroupCategory $groupType -DisplayName $displayName -Description $description -Path $createOU
		
		Writelog $("SUCCESS	Group created: " + $samName)
		$CountSuccess++
	}
	
	Else
	{
		Writelog $("ERROR	Group already exists.  SamAccountName: " + $_.SamAccountName)
		$CountError++
	}
}


# ------------------- END OF SCRIPT MAIN ----------------------------------


# ------------------- CLEANUP ---------------------------------------------


# ------------------- SCRIPT END ------------------------------------------
$error.clear()

EndScript
