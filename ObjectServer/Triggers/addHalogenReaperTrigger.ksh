#!/bin/ksh


# Usage addHalogenReaperTrigger.ksh -u<User Name>

SQL=${OMNIHOME}/bin/nco_sql
#OSNAME=		# This will be the Object Server name as configured in omni.dat
#SQLPRODUSER='janesch'	# THIS IS YOU...

# SERVERLIST - list of Netcool ObjectServers to be modified
SERVERLIST='LASER_P'


while getopts u: opt
do
	case "$opt" in
		u) # Sets User name for OS and GW login
			SQLPRODUSER="${OPTARG}";;
		*) # Unknown argument
			echo "Usage -u<User Name>"
			exit 1;;
		esac
done
shift `expr $OPTIND - 1`
# Define all functions to be used here.
##############################################################################################################
ContinueOrQuit () {
read CONTINUE?'Press <return> to continue or <CTRL C> to abort.. '
}

##############################################################################################################
SetPassword () {
# here we will prompt for the users password, and then clear the screen so that is not left displayed on the screen.
trap 'stty echo; exit' 0 1 2 3 15
stty -echo
read SQLPRODPWD?'Password? '
stty echo
print ""
}


##############################################################################################################

# This function adds trigger to OS - if in doubt RTFM

AddTrigger () {
SQLUSER=${SQLPRODUSER}
SQLPWD=${SQLPRODPWD}
print "Creating or Replacing new Trigger in Object Server ${OSNAME} ... Please wait"
${SQL} -server ${OSNAME} -user ${SQLUSER} -passwd ${SQLPWD} <<COF
CREATE  OR REPLACE  TRIGGER HalogenDecommReaper
GROUP Failover
DEBUG FALSE
ENABLED TRUE
PRIORITY 20
 COMMENT 'Chris Janes	20120215	Original'
EVERY 1  HOURS
BEGIN
for each row expire in alerts.status where expire.Class = 50000 and expire.InServiceStatus = 'De-commissioned'
        begin
                update alerts.status via expire.Identifier set Severity = 0, ExpireID = 999 ;
        end;
END;
go
quit
COF
}

##############################################################################################################
AddTriggersLoop () {
for OSNAME in ${SERVERLIST}
do
	AddTrigger
	print "Trigger Created or Replaced on Object Server ${OSNAME}.."
	sleep 5
done
}

##############################################################################################################

SetPassword
AddTriggersLoop
