#!/bin/bash

# Programmer:  Rex Tran @r3x3r
# BsidesDFW 2019
# Review your environments security policy. External facing open network ports are vulerability risks.
#
# TLDR: Remote shell callback with Rasbian use at own risk. *no warrenty *no takebacks


# SSH INBOUND PORT NUMBER
# sorry IPv4 only
isServer=no

# Important:identifier here
# Obfuscated choose your own "random" incomming home port number from your google sheet
sshinport=4000

# client login username, usualy pi - default
vpsuser=rexer

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

# Create a google sheet form with these Elements
# form input questions are: 
#  Hostname   HardwareID   IPlocal   OutsideIP   Release   Kernel   SysArch   Homenet   ISPname  RpiModel
# simple text one line user input
# Form -> goto live form  and copy url
gliveformurl="https://docs.google.com/forms/d/e/GOOGLELIVEFORMKEY/viewform"
#
gliveformurlsubmit="$(echo $gliveformurl | sed -e 's/viewform/formResponse/g')"

#
# After creating personal google form with as formnamed entries
# File - > publish to Web
# Link section
# entire document - Tab-seperated values (.tsv)
# expand Published Contents & settings
# entire document 
# checkbox 
#
#glivetsvurl="https://docs.google.com/spreadsheets/d/GOOGLETSVOUTPUTKEY/pub?output=tsv"
glivetsvurl="https://docs.google.com/spreadsheets/d/GOOGLETSVOUTPUTKEY/export?format=tsv&id=GOOGLETSVOUTPUTKEY&gid=GOOGLEUSERID"
#
## end of Google Form Configuration 
## 

# Virtual loopback sshport start number to connect into remote raspberry pi
# additional clients will increment by 1
# example server=2200
# 	rpi1=2201
#		rpi2=2202
vloopstart=2200

# default config files
homenetcfg=/opt/share/callhome.homenet
homenetdb=/opt/share/homenet.db
callhomecfg=/opt/share/callhome.cfg
## formated > portnumber $syshwid

#  main program action 
OptCmd=$1

#  extra files used for sed encode/decode 
sedencode="sed -f /usr/local/bin/urlencode.sed"
seddecode="sed -f /usr/local/bin/urldecode.sed"


# get execution date time stamp
nowtime="$(date +%Y%m%d-%H:%M)"

# shorten the wget command to dump database to STDOUT
gformcat="wget -qO- $glivetsvurl"


# Am I new raspberry pi on gsheets based on :SerialNumber:
#syshwid="$(cat /proc/cpuinfo | grep -i Serial | head -n 1 | awk '{ print ":"$3":" }' )"
#anewrpi="$(curl -s $glivetsvurl | grep $syshwid | tail -n 1)"
#if [ -z $anewrpi]; then
#	echo "A new raspberry pi!!"
#	lastknownvloop="$($gformcat | cut -f 9 | grep -v Homenet | sort -u  | tail -n 1)"
#	#echo "lastallknownvloop|$lastknownvloop|"
#	if [ -z "$lastknownvloop" ]; then
#	#	echo "sshinport $sshinport"
#		homenet=$(( $sshinport + 1 ))
#	#	echo "my new $homenet"
#	fi
#	homenet=$(( $lastknownvloop + 1 ))
##	homenet=$lastknownvloop
#fi
#echo "my homenet is $homenet"
#exit 0


amiroot(){
  if [ $UID -ne 0 ]; then
    echo "Must be root or sudo module $1 "
    exit 1
  fi

}
# should be root
GetSysHwid(){  ## raspberry cpu serial number
# optional 
#amiroot syshwid
## check for syshwid, if syshwid cannot be determined, unknown cputype/enviornment and exit
## determine arm/intel/virtual
syshwid="$(cat /proc/cpuinfo | grep -i Serial | head -n 1 | awk '{ print ":"$3":" }' )"
rpimodel="$(dtc -I fs /sys/firmware/devicetree/base 2>&1 | grep 'model = ' | cut -d\" -f2 )"
#echo "ARM $syshwid"
if [ -z "$rpimodel" ]; then
  echo "unknown raspberry pi model"
  exit 1
fi
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
#     if [ -z "$syshwid" ]; then
#       echo "unknown hardware: unable to get system hardware id"
#       exit 1
#     fi
# fi

fi
}  # end of GetSysHwid

# minimum additional software packages for home server
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

# minimum additional software packages for client remote
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




GetSysNetwork(){  ## system and network information
# sed encode the output for google url 
	amiroot getsysnetwork
		#echo "callhomecfg not exists. please run setupClient"
		#exit 1
	
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
	#anew feature?
	rpimodel="$(dtc -I fs /sys/firmware/devicetree/base 2>&1 | grep 'model = ' | cut -d\" -f2 | $sedencode )"
	gformrpimodel=$(grep RpiModel $callhomecfg | cut -d\| -f1 )
	rpimodelgform="$gformrpimodel=$rpimodel" ##newinfo

# remember to decode back to plain txt
	echo "$sysname|$localip|$lsbrelease|$syskernel|$sysarch|$rpimodel|" | $seddecode 
}  # end of GetSysNetwork interfaces

# using ouput of gform and incoming obfuscated port number defined 
GetHomenetIPaddr() { 
# looking for outside HomeIP with PORTNUMBER preceeded with :   ":4000"
homenetall="$($gformcat | grep ":$sshinport" | cut -f 5 | tail -n 1 | awk '{ print $1 }')"
homenet="$(echo $homenetall | cut -d\: -f1)"
homenetport="$(echo $homenetall | cut -d\: -f2)"

echo "|$homenetall|$homenet|$homenetport|vpsuser $vpsuser|"

}

# clickshoes to call home

createTunnel() {
  #autossh -M 0 homeserver01 -p 9991 -N -R 8081:localhost:9991 -vvv
  #sudo -u autossh bash -c '/usr/local/bin/autossh -M 0 -f autossh@homeserver01 -p 9991 -N -o "ExitOnForwardFailure=yes" -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -R 8081:localhost:9991'
  #note  autossh -M pi3_checking_port -fN -o "PubkeyAuthentication=yes" -o "StrictHostKeyChecking=false" -o "PasswordAuthentication=no" -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -R vps_ip:vps_port:localhost:pi_port -i /home/pi/.ssh/id_rsa vps_user@vps_port

#sub local vars
vpsuser=$1
homenet=$2
homenetport=$3


##if [ -z "$rexnet" -o -z "$rexnetport" -o -z "$homenet" ]; then
if [ -z "$vpsuser" -o -z "$homenet" -o -z "$homenetport" ]; then
	echo "find home network IP from google sheet tsv data"
  echo "no vpsuser $vpsuser or homenet $homenet or homenetport $homenetport"
  exit 1
fi
## apply security model risks here
 ##** autossh -M 0 -f $vpsuser@$homenet -p $homenetport -N -o \"StrictHostKeyChecking=false\" -o \"PasswordAuthentication=no\" -o \"ExitonForwardFailure=yes\" -o \"ServerAliveInterval 60\" -o \"ServerAliveCountMax 3\" -R $homenet:localhost:22 -vvv "
 #echo " autossh -M 0 -f $vpsuser@$rexnet -p $rexnetport -N -o \"StrictHostKeyChecking=false\" -o \"PasswordAuthentication=no\" -o \"ExitonForwardFailure=yes\" -o \"ServerAliveInterval 60\" -o \"ServerAliveCountMax 3\" -R $homenet:localhost:22 -vvv "

  autossh -M 0 -f $vpsuser@$homenet -p $homenetport -N -o "StrictHostKeyChecking=false" -o "PasswordAuthentication=no" -o "ExitonForwardFailure=yes" -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -R $homenet:localhost:22 -vvv

if [[ $? -eq 0 ]]; then
# send info to homeserver
  echo "homenet|$homenet|homenetport|$homenetport|sysname|$sysname|vpsuser|$vpsuser|" 
# default install location in /usr/local/bin?
# default remote shell to homenet and run # usr/local/bin/rubyslippers.sh join nowtime vpsuser sysname homenet
  rsh -p $homenetport $vpsuser@$homenet \"/usr/local/bin/rubyslippers.sh join $nowtime $vpsuser $sysname $homenet\" 
  echo "/usr/local/bin/rubyslippers.sh join $nowtime $vpsuser $sysname $homenet $homenetport "
  exit 0
 else
  echo "homenet|$homenet|homenetport|$homenetport|sysname|$sysname|vpsuser|$vpsuser|" 
  echo "An error occurred calling home.  code $?"
  exit 1
fi

}

GetOutSideNet(){ ## Outside IP information from https://www.ip-adress.com/index*
wget -qO- https://www.ip-adress.com/what-is-my-ip-address | sed -e 's/<tr>/|/g' -e 's/<td>/|/g' | sed "s/<[^>]\+>//g" | grep '^|' > /tmp/findipaddress

if [ -z /tmp/findipaddress ]; then
  echo "could not contact https://www.ip-address.com"
  exit 1
fi

#parse the output of urlsite
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
#HOMENET is supoosed to be defined now
gformhomenet=$(grep Homenet $callhomecfg | cut -d\| -f1 )
homenetgform="$gformhomenet=$homenet"
gformpubaddr=$(grep OutsideIP $callhomecfg | cut -d\| -f1)
outsideipgform="$gformpubaddr=$outsideip"

#if [ $1 = debuginfo ]; then
echo "MyIPAddress = $MyIPAddress"
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


NewRpiDetect(){
# Am I new raspberry pi on gsheets based on :SerialNumber:
syshwid="$(cat /proc/cpuinfo | grep -i Serial | head -n 1 | awk '{ print ":"$3":" }' )"
anewrpi="$(curl -s $glivetsvurl | grep $syshwid | tail -n 1)"
if [ -z $anewrpi]; then
  echo "A new raspberry pi!!"
  lastknownvloop="$($gformcat | cut -f 9 | grep -v Homenet | sort -u  | tail -n 1)"
  #echo "lastallknownvloop|$lastknownvloop|"
  if [ -z "$lastknownvloop" ]; then
  # echo "sshinport $sshinport"
    homenet=$(( $sshinport + 1 ))
  # echo "my new $homenet"
  fi
  homenet=$(( $lastknownvloop + 1 ))
# homenet=$lastknownvloop
fi
echo "my homenet is $homenet"

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
syshwid="$(cat /proc/cpuinfo | grep -i Serial | head -n 1 | awk '{ print ":"$3":" }' )"
#lasthomenet=$( $gformcat | grep $syshwid | grep -v HardwareID | sed 's/\r//'| cut -f 9 | grep . | tail -n 1 )
if [ -f $homenetcfg ]; then
	homenet=$(head -n 1 $homenetcfg | awk '{print $1}')
	#lasthomenet="$(cat $homenetcfg | awk '{ print $2 }')"
	syshwid=$(head -n 1 $homenetcfg | awk '{print $2}' | cut -d\: -f2 )
	if [ -z $homenet ]; then
		# i am a newpi
		NewRpiDetect
	fi
else # create a new $homenetcfg
#	NewRpiDetect
	#echo "$homenetcfg not present find online by syshwid"
	#check for $syshwid if not present
	echo "newhomenet $homenet $syshwid"
#		NewRpiDetect
#		echo "no syshwid "
#		exit 1
fi
	#lasthomenet=$( $gformcat | grep $syshwid | grep -v HardwareID | sed 's/\r//'| cut -f 9 | grep . | tail -n 1 )
#	NewRpiDetect
	echo "newhomenet $homenet $syshwid"
	#if [ -z $lasthomenet ]; then
	#	echo "$homenetcfg NEW syshwid"
	# vloopstart=2200
	#NewRpiDetect
	#	echo "lasthomenet null"
#		lastonessh=$( $gformcat | sed 's/\r//'| cut -f 9  | grep -v Homenet | grep -v $vloopstart | grep . | sort -n |  tail -n 1 )
#		if [ -z $lastonessh ]; then
#			homenet=$(( $vloopplus + 1 ))
#		fi
	echo "$homenet $syshwid" > $homenetcfg

#fi

#	else
#		nexthomenet=$(( $lastonessh + 1 ))
#			lasthomenet=$( $gformcat | grep $syshwid | grep -v HardwareID | sed 's/\r//'| cut -f 9 | grep . | sort -n | tail -n 1 )
#			nexthomenet=$(( $lastonessh + 1 ))
#			NewRpiDetect
			if [ -z $lasthomenet ]; then
				echo "no lasthomenet found"
				echo "get last known"
				exit 1
			fi
			echo "$lasthomenet $syshwid" > $homenetcfg
		#homenet=$nexthomenet
#	fi # nexthomenet
	#homenet=$lasthomenet
	#touch -p $(dirname $homenetcfg)
	if [ -z $homenet ]; then
			echo "homenet not found"
			exit 1
	fi
	mkdir -p $(dirname $homenetcfg)
	echo "$homenet $syshwid" > $homenetcfg

#fi # file not exists

}  ## end of ReadHomenetCFG

DidMyinfoChange(){
# must have parsed system information earlier
## getsysinfo for the vars
if [ $isServer = "yes" ]; then  #add :sshinport to home IP
  echo "$sysname,$syshwid,$localip,$outsideip:$sshinport,$lsbrelease,$sysarch,$syskernel,$homenet,$CName,$Region,$City,$Zipcode,$MyISP,$Latitude/$Longtitude" | $seddecode  > /tmp/currentenv
else
  echo "$sysname,$syshwid,$localip,$outsideip,$lsbrelease,$sysarch,$syskernel,$homenet,$CName,$Region,$City,$Zipcode,$MyISP,$Latitude/$Longtitude" | $seddecode  > /tmp/currentenv
fi
# get last known based on syshwid
$gformcat | grep "$syshwid"  | cut -f2- | tail -n 1 | sed 's/\r//' | sed -e 's/\t/,/g' > /tmp/lastknown

envcurrent="$(md5sum /tmp/currentenv | awk '{ print $1 }')"
knownlast="$(md5sum /tmp/lastknown | awk '{ print $1 }')"
#cat /tmp/currentenv /tmp/lastknown
##echo "last    = $knownlast"
if [[ "$knownlast" == "$envcurrent" ]]; then
  #echo "nothing changed" >> /dev/null
  echo "nothing changed"
else
  #echo "something changed!!!" >> /dev/null
  echo "something changed!!!" 
## read cfg gform entrie config file

# echo "curl https://docs.google.com/forms/d/$GFormID/formResponse -d ifq -d $sysnamegform -d $syshwidgform -d $localipgform -d $lsbreleasegform -d $syskernelgform -d $homenetgform -d $outsideipgform -d $ispnamegform -d $sysarchgform -d submit=Submit "
GetHomenetIPaddr
  gformhostname=$(grep Hostname $callhomecfg | cut -d\| -f2)
  sysnamegform="$gformhostname=$sysname"

  gformhwid=$(grep HardwareID $callhomecfg | cut -d\| -f2)
  syshwidgform="$gformhwid=$syshwid"

  gformlocalip=$(grep IPlocal $callhomecfg | cut -d\| -f2)
  localipgform="$gformlocalip=$localip"

  gformrelease=$(grep Release $callhomecfg | cut -d\| -f2)
  lsbreleasegform="$gformrelease=$lsbrelease"

  gformkernel=$(grep Kernel $callhomecfg | cut -d\| -f2)
  syskernelgform="$gformkernel=$syskernel"

  gformsysarch=$(grep SysArch $callhomecfg | cut -d\| -f2)
  sysarchgform="$gformsysarch=$sysarch"

 gformrpimodel=$(grep RpiModel $callhomecfg | cut -d\| -f2 )
  rpimodelgform="$gformrpimodel=$rpimodel" ##newinfo

	gformispname=$(grep ISPname $callhomecfg | cut -d\| -f2 )
	ispnamegform="$gformispname=$ispnameURL"

	gformhomenet=$(cat $homenetcfg | awk '{ print $1 }')
	homenetgform="$gformhomenet=$gformhomenet"


  if [[ "$isServer" = "yes" ]]; then
	#gethomenet
    #outsideipgformSPORT=$(echo $outsideipgform:$sshinport | sed -f /usr/lib/cgi-bin/urlencode.sed)
    outsideipgformSPORT=$(echo $outsideipgform:$sshinport | $sedencode)
    echo "curl -s https://docs.google.com/forms/d/$GFormID/formResponse -d ifq -d $sysnamegform -d $syshwidgform -d $localipgform -d $lsbreleasegform -d $syskernelgform -d $homenetgform -d $outsideipgformSPORT -d $ispnamegform -d $sysarchgform -d submit=Submit 2>&1 >> /dev/null"

  else
		### is a client submit
	echo "curl -s $gliveformurlsubmit -d ifq -d $sysnamegform -d $syshwidgform -d $localipgform -d $lsbreleasegform -d $syskernelgform -d $homenetgform -d $outsideipgform -d $ispnamegform -d $sysarchgform -d $ispnameURL -d submit=Submit"
    ##curl -s https://docs.google.com/forms/d/$GFormID/formResponse -d ifq -d $sysnamegform -d $syshwidgform -d $localipgform -d $lsbreleasegform -d $syskernelgform -d $homenetgform -d $outsideipgform -d $ispnamegform -d $sysarchgform -d submit=Submit 2>&1 >> /dev/null
  fi

fi


}

#GetSysNetwork;
#GetOutSideNet;
#GetHomenetIPaddr;


## main shell execution (verb) options and variables
if [ $OptCmd ]; then
 case $OptCmd in
  installfiles) # copy files in /usr/local/bin  must be root
		amiroot toinstallfiles
		echo "installing to /usr/local/bin"
		cp urlencode.sed /usr/local/bin
		cp urldecode.sed /usr/local/bin
		cp rubyslippers.sh /usr/local/bin
		echo "copy rubyslippers.sh and files to /usr/local/bin"
		echo "next run setupClient ID google entrie indexes in Google form"
		echo "-> $gliveformurl"
		echo " "
		exit 0
	;;
  setupServer) # initial server setup must be root
		amiroot setupserveropts
    GetSysHwid;
    setup_server;
		echo "using $gliveform"
    exit 0
  ;;
  setupClient) # initial setup must be root
		amiroot setupClient
		NewRpiDetect
#    GetSysHwid;
		GetSysNetwork;
    setup_client;
		ReadHomenetCFG;
		echo "google form: $gliveformurl"
#    if [ ! -f $callhomecfg ]; then
      curl -s $gliveformurl | grep 'entry.[0-9]*' | sed -e 's/ /\n/g' > /tmp/gliveform
       for i in $(grep 'entry.[0-9]*' /tmp/gliveform | cut -d\" -f2 | sed -e 's/"//g'); do
         echo "|$i|$(grep "$i" /tmp/gliveform -B 3 | head -n 1 | cut -d\" -f2)|" | tee -a $callhomecfg
       done
			rm /tmp/gliveform
#    else
      cat $callhomecfg
#    fi
    exit 0
   ;;
  callhomefirst) # callhome first to test ssh call home
		echo "callhome first ssh to save password and ssh keys here"
		exit 0
	;;
  showconnected) # show machies connected to server
    if [ $isServer = "yes" ]; then
			if [ -f $homenetdb ]; then
	      echo "| Time | User | hostname | ssh port  "
					#wiki format cat $homenetdb | sed -e 's/ / |\^ /g' -e 's/^/|\^ /g' -e 's/$/|\n/g'
					cat $homenetdb | sed -e 's/ / | /g'
				else
					echo "no nohomenetdb"
					exit 1
			fi
    else
      echo "not a server"
    fi
    exit 0
  ;;
  tapshoes) # no place like home
    GetSysHwid;
		ReadHomenetCFG;
		GetHomenetIPaddr;
    #echo "tick tock auto-ssh connect home"
		if [ -z $vpsuser -o -z $homenet -o -z $homenetport ]; then
			echo "missing vpsuser|$vpsuser|homenet|$homenet|homenetport|$homenetport|"
			exit 0
		fi
		isautosshrunning=$(pidof autossh)
    if [ -z $isautosshrunning ]; then
		 echo "sub-createTunnel  $vpsuser $homenet $homenetport"
		 #createTunnel  $vpsuser $homenet $homenetport
		else
			echo "autossh already running at pid $isautosshrunning"
		fi
			
    exit 0
  ;;
  logged) # All machines output logged to google tsv to screen
    $gformcat
    echo " "
    exit 0
   ;;
  lsshids) # list sshid port
    echo "VirtPort  Hostname" 
    echo "------------------"
    $gformcat 2>&1 | cut -f 2,9 | sed 1,1d | awk '{ print $2"\t"$1 }' | sort -nu | grep '^[0-9]'
    exit 0
  ;;
  join) # join network $1 $2 $3 $4 $5  (server side only)
		ReadHomenetCFG;
#/usr/local/bin/rubyslippers.sh join $nowtime $vpsuser $sysname $homenet $homenetport 
    echo "establish connection needed parms (join) nowtime vpsuser sysname homenet"
    echo "($1) $2 $3 $4 $5"
    nowtime=$2
    vpsuser=$3
    sysname=$4
    homenet=$5
		if [ $isServer = yes ]; then
    	echo "$nowtime $vpsuser $sysname $homenet" >> $homenetdb
			echo "/usr/local/bin/rubyslippers.sh join $nowtime $vpsuser $sysname $homenet"
		fi
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
		echo "==== last 3 lines ======="
    $gformcat 2>&1 | grep "$syshwid" | tail -n 3
    echo " "
    exit 0
  ;;
  mysshid) # cpuinfo and sshid
    $gformcat 2>&1 | grep "$syshwid" | tail -n 1 | cut -f 9  # last sshid port number tunnel
    exit 0
  ;;
  cleantmp) # cleantmpfiles
		rm /tmp/findipaddress
		rm /tmp/currentenv
		rm /tmp/lastknown
	;;
  heartbeat) # find anything changed and submit to google form
		#amiroot heartbeat
    GetSysHwid
		GetSysNetwork
		GetHomenetIPaddr
		GetOutSideNet
		DidMyinfoChange
		exit 0
	;;
  *) # help
    echo "$(basename $0): (options) "
    grep "[a-z]) # " $(dirname $0)/$(basename "$0")
    exit 0
  ;;
esac
fi

##
## cleanup
#rm /tmp/findipaddress
#rm /tmp/currentenv
#rm /tmp/lastknown


