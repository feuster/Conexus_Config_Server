#!/bin/bash
#-------------------------------------------------------
#CONEXUS CONFIGURATION. EDIT WITH CARE!
#-------------------------------------------------------
# allowed remote codes: SAT1 SAT2 TV1 VCR1 VCR2 TV2 ALL
CODE=SAT2
# allowed URLs: IP or local domainname for e.g. audiomaster-mr3.fritz.box
URL=192.168.0.37
# allow PINs: 4-digit numeric (default PIN should be 1234)
PIN=1234

#-------------------------------------------------------
#DO NOT CHANGE ANYTHING BELOW THIS LINE!!!
#-------------------------------------------------------

if [ "${1^^}" = "${code^^}" ] || [ "${code^^}" = "ALL" ] ; then
gpio -g mode 23 out
gpio -g write 23 1
sleep 0.0075
gpio -g write 23 0
  if [ "${2^^}" != "BLINK" ] ; then
  conexus -n -u $url -p $pin -c $2
  fi
fi
