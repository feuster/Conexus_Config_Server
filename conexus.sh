#!/bin/bash
#-------------------------------------------------------
#CONEXUS CONFIGURATION. EDIT WITH CARE!
#-------------------------------------------------------
# allowed Conexus remote codes: SAT1 SAT2 TV1 VCR1 VCR2 TV2 ALL
code=ALL
# allowed Music Player Daemon remote codes: SAT1 SAT2 TV1 VCR1 VCR2 TV2 OFF(remote code2 may not be the same as the default Conexus remote code!) 
code2=OFF
# allowed URLs: IP or local domainname for e.g. radio.fritz.box
url=192.168.0.34
# allowed PINs: 4-digit numeric (default PIN should be 1234)
pin=1234

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

if [ "${1^^}" = "${code2^^}" ] ; then
gpio -g mode 23 out
gpio -g write 23 1
sleep 0.0075
gpio -g write 23 0
  if [ "${2^^}" != "BLINK" ] ; then
    if [ "${2^^}" == "PREVIOUS" ] || [ "${2^^}" == "PREVIOUSPRESET" ] ; then
      mpc prev
    elif [ "${2^^}" == "NEXT" ] || [ "${2^^}" == "NEXTPRESET" ] ; then
      mpc next
    elif [ "${2^^}" == "PLAYPAUSE" ] ; then
      mpc play
    elif [ "${2^^}" == "PAUSE" ] ; then
      mpc stop
    elif [ "${2^^}" == "MODE:9" ] ; then
      mpc pause
    elif [ "${2^^}" == "PRESETSELECT:0" ] ; then
      mpc play 1
    elif [ "${2^^}" == "PRESETSELECT:1" ] ; then
      mpc play 2
    elif [ "${2^^}" == "PRESETSELECT:2" ] ; then
      mpc play 3
    elif [ "${2^^}" == "PRESETSELECT:3" ] ; then
      mpc play 4
    elif [ "${2^^}" == "PRESETSELECT:4" ] ; then
      mpc play 5
    elif [ "${2^^}" == "PRESETSELECT:5" ] ; then
      mpc play 6
    elif [ "${2^^}" == "PRESETSELECT:6" ] ; then
      mpc play 7
    elif [ "${2^^}" == "PRESETSELECT:7" ] ; then
      mpc play 8
    elif [ "${2^^}" == "PRESETSELECT:8" ] ; then
      mpc play 9
    elif [ "${2^^}" == "PRESETSELECT:9" ] ; then
      mpc play 10
    elif [ "${2^^}" == "VOL+" ] ; then
      conexus -n -u $url -p $pin -c vol+
    elif [ "${2^^}" == "VOL-" ] ; then
      conexus -n -u $url -p $pin -c vol-
    elif [ "${2^^}" == "MUTE" ] ; then
      conexus -n -u $url -p $pin -c mute
    elif [ "${2^^}" == "SETSLEEPTIMER:900" ] ; then
      conexus -n -u $url -p $pin -c setsleeptimer:900
      sleep 900 && mpc stop &
    elif [ "${2^^}" == "MODE:SPOTIFY" ] ; then
      mpc repeat
    elif [ "${2^^}" == "MODE:AUXIN" ] ; then
      mpc single
    elif [ "${2^^}" == "MODE:DAB" ] ; then
      mpc random
    elif [ "${2^^}" == "MODE:IR" ] ; then
      mpc single
    elif [ "${2^^}" == "MODE:0" ] ; then
      mpc stop && mpc clear && mpc load playlist1 && mpc play
    elif [ "${2^^}" == "MODE:1" ] ; then
      mpc stop && mpc clear && mpc load playlist2 && mpc play
    elif [ "${2^^}" == "MODE:2" ] ; then
      mpc stop && mpc clear && mpc load playlist3 && mpc play
    elif [ "${2^^}" == "MODE:3" ] ; then
      mpc stop && mpc clear && mpc load playlist4 && mpc play
    elif [ "${2^^}" == "MODE:4" ] ; then
      mpc stop && mpc clear && mpc load playlist5 && mpc play
    elif [ "${2^^}" == "MODE:5" ] ; then
      mpc stop && mpc clear && mpc load playlist6 && mpc play
    elif [ "${2^^}" == "MODE:6" ] ; then
      mpc stop && mpc clear && mpc load playlist7 && mpc play
    elif [ "${2^^}" == "MODE:7" ] ; then
      mpc stop && mpc clear && mpc load playlist8 && mpc play
    elif [ "${2^^}" == "MODE:11" ] ; then
      find /home/pi/Documents/mpd/music/* -iname *.mp3 -type f | head -n 1000 > /home/pi/Documents/mpd/playlists/playlist8.m3u
      find /media/pi/* -iname *.mp3 -type f | head -n 1000 > /home/pi/Documents/mpd/playlists/playlist7.m3u
      mpc stop && mpc clear && mpc update
      if [ -s /home/pi/Documents/mpd/playlists/playlist7.m3u ]; then
        mpc load playlist7
      else
        mpc load playlist8
      fi
      mpc play
    elif [ "${2^^}" == "STANDBY" ] ; then
      if [ "$(conexus -n -u $url -p $pin -c standbystate | grep active)" == "" ] ; then
        conexus -n -u $url -p $pin -c on
        conexus -n -u $url -p $pin -c mode:auxin
        mpc play
      else
        conexus -n -u $url -p $pin -c off
        mpc stop
      fi
    fi
  else
  sleep 0.05
  gpio -g write 23 1
  sleep 0.0075
  gpio -g write 23 0
  fi
fi
