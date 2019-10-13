#!/bin/bash

# Programmer:  @r3x3r
# BsidesDFW 2019

# SSH INBOUND PORT NUMBER
# sorry IPv4 only
isServer=no
sshinport=686

# client login username, usualy pi - default
vpsuser=pi

# checkfor homenetcfg file 
#  if not present, 
#     if syshwid online not recorded before,
#       get last sshid and + 1
#  			getoutside ipinfo
#  			(submit new info and exit)
#  present, homenet is contents of lastonline
# 
#  write currentconfig/homesshid to /tmp/currentenv
#  
#  export the google form to tsv and look for last connection
#  compare currentonline with lastknownonline
#  if diffrent
#     then submit existing homecfg with currentonline
#  exit

#dependencies: /usr/local/bin/urlencode.sed
#              /usr/local/bin/urldecode.sed

## explain how to get these urls..
# Create a google form with these Elements

# create a google sheet
# goto create create form
# create form input elements of 
# | Hostname | HardwareID | IPlocal | OutsideIP | Release | Kernel | SysArch | Homenet | ISPname |
# simple text one line user input
# Form -> goto live form  and copy url
gliveformurl="https://docs.google.com/forms/d/e/1FAIpQLSc9ENsLkGI6XffWFcj47NIKVFPAwkEUWGEGgWGHqlT_uALtAA/viewform"
#
# After creating personal google form with as formnamed entries
# File - > publish to Web
# Link section
# entire document - Tab-seperated values (.tsv)
# expand Published Contents & settings
# entire document 
# checkbox 
glivetsvurl="https://docs.google.com/spreadsheets/d/e/2PACX-1vRR6eIS7FYFpC5ehObdrIAJQ-TX13JgPe5pKm7UdcdiR66cqzmONKe2vFKH5qTlmsnc5E1_Cu3l7dEt/pub?output=tsv"
## end of Google Form Configuration 
## 

homenetcfg=/opt/share/callhome.homenet
homenetdb=/opt/share/homenet.db
callhomecfg=/opt/share/callhome.cfg
## formated > portnumber $syshwid

OptCmd=$1
sedencode="sed -f /usr/local/bin/urlencode.sed"
seddecode="sed -f /usr/local/bin/urldecode.sed"

nowtime="$(date +%Y%m%d-%H:%M)"
#
# shorten the wget 
#gformcat="wget -qO- https://docs.google.com/spreadsheets/d/$GFidfor/export?format=tsv&id=$GFidfor&gid=$GFuid"
gformcat="wget -qO- $glivetsvurl"

setup_server(){
deplist="wget curl md5sum awk cut grep"
for dep in $deplist ; do
  isinstalled=$(which $dep)
    if [ -z "$isinstalled" ] ; then
      notinstalled="$notinstalled $dep"
    fi
done
if [ -z "$notinstalled" ]; then
    echo "all ok: $deplist" > /dev/null
  else
  echo "not installed: $notinstalled"
fi

}

setup_client(){
deplist="wget curl md5sum awk cut grep autossh"
for dep in $deplist ; do
  isinstalled=$(which $dep)
    if [ -z "$isinstalled" ] ; then
#      notinstalled="$notinstalled $dep"
			echo "install $dep?"
			read installit
			case $installit in
				y|Y) apt install $dep;;
				n|N) echo "not install $dep";;
			esac
		fi
done
if [ -z "$notinstalled" ]; then
	echo "all ok: $deplist" > /dev/null
	else
	echo "not installed: $notinstalled"
fi
} ## end of setup_client

GetSysHwid(){  ## raspberry cpu serial number
#if [ $UID -ne 0 ]; then
# echo "must be root"
# exit 1
#fi
## check for syshwid, if syshwid cannot be determined, unknown cputype/enviornment and exit
## determine arm/intel/virtual
syshwid="$(cat /proc/cpuinfo | grep -i Serial | head -n 1 | awk '{ print ":"$3":" }' )"
#echo "ARM $syshwid"
if [ -z $syshwid  ]; then
	# if not ARM processor 
	echo "not ARPM raspberry pi cpu"
	exit 1
##for other cpu types looking for Serial Number or UUID virtual machines
##syshwid="$(/usr/sbin/dmidecode | grep "Serial Number:" | head -n 1 | awk '{ print ":"$3":" }' )"
## if not ARM processor look for INTEL $syshwid
# if [ "$syshwid" = ":Not:" ]; then
#   #Virtual cpu find partial UUID string
#   syshwid="$(/usr/sbin/dmidecode| grep UUID | head -n 1 | cut -d\- -f5 | awk '{ print ":"$1":" }' )"
#   #echo "VM $syshwid"
#   #vmuuid="$(/usr/sbin/dmidecode| grep UUID | head -n 1 | awk '{ print $2 }' )"
#   #echo "vmuuid $vmuuid"
#			if [ -z "$syshwid" ]; then
#				echo "unknown hardware: unable to get system hardware id"
#				exit 1
#			fi
# fi

fi

#if [ -z $syshwid ]; then
#  echo no syshwid
#  exit 1
#fi

}  # end of GetSysHwid


GetSysNetwork(){  ## system network interfaces
	if [ $UID -ne 0 ]; then
		echo "must be root"
		exit 1
	fi
	sysname="$(hostname | $sedencode )"
	gformhostname=$(grep Hostname $callhomecfg | cut -d\| -f1)
	sysnamegform="$gformhostname=$sysname"
	gformhwid=$(grep HardwareID $callhomecfg | cut -d\| -f2)
	syshwidgform="$gformhwid=$syshwid"
	localnet=""
  for i in $(seq 1 $(ip addr list| grep -w 'inet' | grep -v '127.0.0' | wc -l)); do
   localnet="$localnet $(ip addr list | grep -w inet | grep -v '127.0.0' | head -n $i | tail -n 1 | cut -d\/ -f1 | awk '
{ print $2 }')"
  done
	localip="$(echo $localnet | $sedencode)"
	gformlocalip=$(grep IPlocal $callhomecfg | cut -d\| -f1)
	localipgform="$gformlocalip=$localip"
	lsbrelease="$(lsb_release -a 2>&1 | grep Description | cut -d\: -f2- | cut -c2- | $sedencode )"
	if [ -z $lsbrelease ]; then
		lsbrelease="$(lsb_release 2>&1 | sed -n 1p | $sedencode )"
	fi
	if [ -z $lsbrelease ]; then
		lsbrelease="no-lsb-release"
    exit 1
  fi
	gformrelease=$(grep Release $callhomecfg | cut -d\| -f1)
  lsbreleasegform="$gformrelease=$lsbrelease"
  syskernel="$(cat /proc/version | awk '{ print $3 }' | $sedencode )"
	gformkernel=$(grep Kernel $callhomecfg | cut -d\| -f1)
  syskernelgform="$gformkernel=$syskernel"
  sysarch="$(cat /proc/cpuinfo | grep -w 'model name' | tail -n 1 | cut -d\: -f2-|cut -c2- | $sedencode )"
	gformsysarch=$(grep SysArch $callhomecfg | cut -d\| -f1)
  sysarchgform="$gformsysarch=$sysarch"

	echo "$sysname $localip $lsbrelease $syskernel $sysarch" | $seddecode 
}  # end of GetSysNetwork interfaces


createTunnel() {
  #/usr/bin/ssh -N -R rexer@$rexnet 
  #/usr/bin/ssh -N -R $homenet:localhost:22 -p $rexnetport rexer@$rexnet 
  #autossh -M 0 homeserver01 -p 9991 -N -R 8081:localhost:9991 -vvv
  #sudo -u autossh bash -c '/usr/local/bin/autossh -M 0 -f autossh@homeserver01 -p 9991 -N -o "ExitOnForwardFailure=yes" -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -R 8081:localhost:9991'
  #note  autossh -M pi3_checking_port -fN -o "PubkeyAuthentication=yes" -o "StrictHostKeyChecking=false" -o "PasswordAuthentication=no" -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -R vps_ip:vps_port:localhost:pi_port -i /home/pi/.ssh/id_rsa vps_user@vps_port

if [ -z "$rexnet" -o -z "$rexnetport" -o -z "$homenet" ]; then
  echo "no rexnet or rexnetport or homenet"
  exit 1
fi
 echo " autossh -M 0 -f $vpsuser@$rexnet -p $rexnetport -N -o \"StrictHostKeyChecking=false\" -o \"PasswordAuthentication=no\" -o \"ExitonForwardFailure=yes\" -o \"ServerAliveInterval 60\" -o \"ServerAliveCountMax 3\" -R $homenet:localhost:22 -vvv "
#  autossh -M 0 -f $vpsuser@$rexnet -p $rexnetport -N -o "StrictHostKeyChecking=false" -o "PasswordAuthentication=no" -o "ExitonForwardFailure=yes" -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -R $homenet:localhost:22 -vvv
if [[ $? -eq 0 ]]; then
# send info to homeserver
  echo "homenet|$homenet|rexnet|$rexnet|rexnetport|$rexnetport|sysname|$sysname|vpsuser|$vpsuser|" 
  echo "rsh -p $rexnetport $vpsuser@$rexnet \"/usr/local/bin/rubyslippers.sh join $nowtime $vpsuser $sysname $homenet\" "
  echo "called home $nowtime"
  exit 0
 else
  echo "homenet|$homenet|rexnet|$rexnet|rexnetport|$rexnetport|sysname|$sysname|vpsuser|$vpsuser|" 
  echo "An error occurred calling home.  code $?"
  exit 1
fi

}

GetOutSideNet(){ ## Outside IP information
wget -qO- https://www.ip-adress.com/what-is-my-ip-address | sed -e 's/<tr>/|/g' -e 's/<td>/|/g' | sed "s/<[^>]\+>//g" | grep '^|' > /tmp/findipaddress

if [ -z /tmp/findipaddress ]; then
  echo "could not contact https://www.ip-address.com"
  exit 1
fi

MyIPAddress=$(grep -w "IP Address" /tmp/findipaddress | cut -d\| -f 3)
CName=$(grep -w "Country" /tmp/findipaddress | grep -v Code | cut -d\| -f 3 | sed -e 's/ //g')
Region=$(grep -w "State" /tmp/findipaddress | grep -v Code | cut -d\| -f3 | sed -e 's/ //g')
City=$(grep -w "City" /tmp/findipaddress | cut -d\| -f3 | sed -e 's/ //g')
Zipcode=$(grep -w "Postal Code" /tmp/findipaddress | cut -d\| -f3 | sed -e 's/ //g')
Latitude="($(grep -w "Latitude" /tmp/findipaddress | cut -d\| -f3- | cut -d\& -f1))"
Longtitude="($(grep -w "Longitude" /tmp/findipaddress | cut -d\| -f3- | cut -d\& -f1))"
MyISP=$(grep -w "ISP" /tmp/findipaddress | cut -d\| -f3- | sed -e 's/ //g' )

#echo "IP Address=$MyIPAddress"
outsideip=$MyIPAddress
#echo "$CName,$Region,$City,$Zipcode,$MyISP,$Latitude/$Longtitude"
#ispnameURL="$(echo $CName,$Region,$City,$Zipcode,$MyISP,$Latitude/$Longtitude | sed -f /usr/lib/cgi-bin/urlencode.sed)"
ispnameURL="$(echo $CName,$Region,$City,$Zipcode,$MyISP,$Latitude/$Longtitude | $sedencode )"
gformispname=$(grep ISPname $callhomecfg | cut -d\| -f1 )
ispnamegform="$gformispname=$ispnameURL"
#ispnamegform="entry.588822800=$ispnameURL"
#HOMENET is supoosed to be defined now
gformhomenet=$(grep Homenet $callhomecfg | cut -d\| -f1 )
homenetgform="$gformhomenet=$homenet"
#homenetgform="entry.1018460793=$homenet"
gformpubaddr=$(grep OutsideIP $callhomecfg | cut -d\| -f1)
outsideipgform="$gformpubaddr=$outsideip"
#outsideipgform="entry.1222643190=$outsideip"

#if [ $1 == "debuginfo" ]; then
echo "MyIPAddress $MyIPAddress"
echo "sysname $sysnamegform" | $seddecode
echo "syshwid $syshwidgform" | $seddecode
echo "localip $localipgform" | $seddecode
echo "lsbrelease $lsbreleasegform" | $seddecode
echo "syskernel $syskernelgform" | $seddecode
echo "homenet $homenetgform" | $seddecode
echo "outsideip $outsideipgform" | $seddecode
echo "ispname $ispnamegform" | $seddecode
echo "sysarch $sysarchgform" | $seddecode
#read anykeyedpressed

#fi
}


#if [ ! -f $homenetcfg ]; then
#  echo "please run setup for $homenetcfg"
#  exit 1
#fi
#if [ ! -f $callhomecfg ]; then
#  echo "please run setup for $callhomecfg"
#  exit 1
#fi

ReadHomenetCFG(){
if [ -f $homenetcfg ]; then
	homenet=$(head -n 1 $homenetcfg | awk '{print $1}')
	syshwid=$(head -n 1 $homenetcfg | awk '{print $2}')
else
	#	echo "$homenetcfg not present find online by syshwid"
		lasthomenet=$( $gformcat | grep $syshwid | sed 's/\r//'| cut -f 9 | grep . | tail -n 1 )
		homenet=$lasthomenet
		if [ -z $lasthomenet ]; then
		#	echo "$homenetcfg NEW syshwid"
		#	echo "lasthomenet null"
			lastonessh=$( $gformcat | sed 's/\r//'| cut -f 9 | grep . | sort -n |  tail -n 1 )
			nexthomenet=$(( $lastonessh + 1 ))
			homenet=$nexthomenet
			echo "$nexthomenet $syshwid" > $homenetcfg
		fi # nexthomenet
		mkdir -p $(dirname $homenetcfg)
		echo "$lasthomenet $syshwid" > $homenetcfg
fi # file not exists
}  ## end of ReadHomenetCFG

#GetSysNetwork;
#GetOutSideNet;


## main shell program options variables
if [ $OptCmd ]; then
 case $OptCmd in
  installfiles) # setup files in /usr/local/bin  must be root
		echo "must be root"
		echo "copy files to /usr/local/bin"
		echo "cp rubyslippers.sh /usr/local/bin"
		echo "cp url*code.sed /usr/local/bin"
		exit 0
	;;
  setupServer) # initial server setup must be root
    GetSysHwid;
    setup_server;
    exit 0
  ;;
  setupClient) # initial setup must be root
    GetSysHwid;
    setup_client;
		ReadHomenetCFG;
    if [ ! -f $callhomecfg ]; then
      curl -s $gliveformurl | grep 'entry.[0-9]*' | sed -e 's/ /\n/g' > /tmp/gliveform
       for i in $(grep 'entry.[0-9]*' /tmp/gliveform | cut -d\" -f2 | sed -e 's/"//g'); do
         echo "|$i|$(grep "$i" /tmp/gliveform -B 3 | head -n 1 | cut -d\" -f2)|" | tee -a $callhomecfg
       done
     rm /tmp/gliveform
    else
      echo "google form: $gliveformurl"
      cat $callhomecfg
    fi
    exit 0
   ;;
  showconnected) # show machies connected to server
    if [ $isServer = "yes" ]; then
      echo "| Time | User | hostname | ssh port  "
      #wiki format cat $homenetdb | sed -e 's/ / |\^ /g' -e 's/^/|\^ /g' -e 's/$/|\n/g'
      cat $homenetdb | sed -e 's/ / | /g'
    else
      echo "not a server"
    fi
    exit 0
  ;;
  tapshoes) # no place like home
    GetSysHwid;
		ReadHomenetCFG;
    echo "tick tock auto-ssh connect home"
                                                  # check for master $homenet IP address
    echo "$vpsuser $homenet"
    isrunning=$(ps ax | grep autossh | grep $vpsuser | grep "$homenet" | grep -v grep | head -n 1 | awk '{ print $1 }')
    if [ -z $isrunning ]; then
            #createTunnel
            echo "create Tunnel sub process $vpsuser $homenet"
    fi
    exit 0
  ;;
  logged) # All machines output logged to google tsv to screen
    $gformcat
    echo " "
    exit 0
   ;;
  lsshids) # list sshid port
    echo "Port  Hostname" 
    echo "-----|----------"
    $gformcat 2>&1 | cut -f 2,9 | sed 1,1d | awk '{ print $2"\t"$1 }' | sort -nu | grep '^[0-9]'
    exit 0
  ;;
  join) #join network
    echo "establish connection needed parms (join) nowtime vpsuser sysname homenet"
    echo "($1) $2 $3 $4 $5"
    nowtime=$2
    vpsuser=$3
    sysname=$4
    homenet=$5
    echo "/usr/local/bin/rubyslippers.sh (join) $nowtime $vpsuser $sysname $homenet"
    exit 0
  ;;
  allsshids )# list all shhids only
    $gformcat 2>&1 | cut -f 9 | sed 1,1d | sort -nu | grep .
    exit 0
  ;;
  myinfo) # last cpuinfo info
    GetSysHwid;
    if [ -z $syshwid ]; then
      echo nosyshwid
      exit 1
    fi
    echo "syshwid=$syshwid"
    GetSysNetwork debuginfo   ###
    $gformcat 2>&1 | grep "$syshwid" | tail -n 3
    echo " "
    exit 0
  ;;
  mysshid) # cpuinfo and sshid
    $gformcat 2>&1 | grep "$syshwid" | tail -n 1 | cut -f 9  # last sshid port number tunnel
    exit 0
  ;;
  *) # help
    echo "$(basename $0): (options) "
    grep "[a-z]) # " $(dirname $0)/$(basename "$0")
    exit 0
  ;;
esac
fi


if [ $isServer = "yes" ]; then
	echo "$sysname,$syshwid,$localip,$outsideip:$sshinport,$lsbrelease,$sysarch,$syskernel,$homenet,$CName,$Region,$City,$Zipcode,$MyISP,$Latitude/$Longtitude" | $seddecode  > /tmp/currentenv 
else
	echo "$sysname,$syshwid,$localip,$outsideip,$lsbrelease,$sysarch,$syskernel,$homenet,$CName,$Region,$City,$Zipcode,$MyISP,$Latitude/$Longtitude" | $seddecode  > /tmp/currentenv 
fi
# get last known based on syshwid
$gformcat | grep "$syshwid"  | cut -f2- | tail -n 1 | sed 's/\r//' | sed -e 's/\t/,/g' > /tmp/lastknown

envcurrent="$(md5sum /tmp/currentenv | awk '{ print $1 }')"
knownlast="$(md5sum /tmp/lastknown | awk '{ print $1 }')"
#cat /tmp/currentenv
#cat /tmp/lastknown
##echo "last    = $knownlast"
if [[ "$knownlast" = "$envcurrent" ]]; then
	echo "nothing changed" >> /dev/null
else
	echo "something changed!!!" >> /dev/null
#	echo "curl https://docs.google.com/forms/d/$GFormID/formResponse -d ifq -d $sysnamegform -d $syshwidgform -d $localipgform -d $lsbreleasegform -d $syskernelgform -d $homenetgform -d $outsideipgform -d $ispnamegform -d $sysarchgform -d submit=Submit "
	if [[ "$isServer" = "yes" ]]; then
		#outsideipgformSPORT=$(echo $outsideipgform:$sshinport | sed -f /usr/lib/cgi-bin/urlencode.sed)
		outsideipgformSPORT=$(echo $outsideipgform:$sshinport | sed -f /usr/lib/cgi-bin/urlencode.sed)
		curl -s https://docs.google.com/forms/d/$GFormID/formResponse -d ifq -d $sysnamegform -d $syshwidgform -d $localipgform -d $lsbreleasegform -d $syskernelgform -d $homenetgform -d $outsideipgformSPORT -d $ispnamegform -d $sysarchgform -d submit=Submit 2>&1 >> /dev/null
	else
		curl -s https://docs.google.com/forms/d/$GFormID/formResponse -d ifq -d $sysnamegform -d $syshwidgform -d $localipgform -d $lsbreleasegform -d $syskernelgform -d $homenetgform -d $outsideipgform -d $ispnamegform -d $sysarchgform -d submit=Submit 2>&1 >> /dev/null
	fi

fi
##
## cleanup
rm /tmp/findipaddress
rm /tmp/currentenv
rm /tmp/lastknown


