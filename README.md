# rubyslippers
Raspberry pi autossh bash auto-ssh script utilizing google spreadsheets.

No outside ports are needed to be forwarded to remote client raspberry pi on remote network.

Review your network security policy. External facing open network ports are vulerability risks.

TLDR: Remote shell callback with Rasbian and google sheets. Use at own risk. No warrenty No takebacks


----
BsidesDFW 2019
----

Dependencies:
* Google sheet form
* app dependencies: autossh
* provided file dependencies: urlencode.sed and urldecode.sed
* confiuration files:
* /opt/share/callhome.cfg				(google specific formIDs)
* /opt/share/callhome.homenet		(local raspberry pi information)
* connection to https://www.ip-adress.com/what-is-my-ip-address for parsing outside network information

Minimum requirements: 
* Home router assign static IP raspberry pi.
* Home router port forward ssh to raspberry pi
* Raspberry pi with Rasbian Buster Lite image from [raspberrypi.org](https://www.raspberrypi.org/downloads/raspbian/ "raspberrypi.org")
* developed on rpi1b

----
1. Follow initial basic setup raspberry prefrences and configuration.  [raspi-config](https://www.raspberrypi.org/documentation/configuration/raspi-config.md)
*	Set Locale Language
*	Set timezone
*	Set Keyboard
*	Under Interfacing Options select ssh
*	change the default pi password with #> passwd
	
----
2. Configure home router to staticly assign raspberry IP address. Use the mac address of raspberry pi to boot up with the same IP address. [many how-to videos](https://www.google.com/search?q=setup+static+ip+home+router+raspberry+pi&source=lnms&tbm=vid "many how-to videos").
----
3. *security risk assesment here* Configure home router port forward outside network to raspberry pi IP address. (reference your specific manufacture/brand and choose a non-standard number of obfuscation)
~~~~
isServer=yes
sshinport=10686
vpsuser=pi
~~~~
----
4. Choose your virtual loopback ssh starting port.  Begins at 2200 and increments +1 for each unique hawrdware ID raspi remote client not found in google sheet online.  
~~~~
vloopstart=2200
~~~~

5. Login to [Google Sheets](http://sheets.google.com) to create a sheet for database of your pi inventory.

* example: piConnectBack
* goto Tools menu, select Create form

Create with 8 short answer text, all required questions in specified order.

* Hostname
* HardwareID
* IPlocal
* OutsideIP
* Release
* SysArch
* RpiModel
* Kernel
* Homenet
* ISPname

In your google sheet goto Form and copy url key. 
~~~~
gliveformurl="https://docs.google.com/forms/d/e/GOOGLELIVEFORMKEY/viewform"
~~~~

* File - > publish to Web
* Link section
* Entire document - Tab-seperated values (.tsv)
* Expand Published Contents & settings
* Put a checkbox in entire document 

~~~~
glivetsvurl="https://docs.google.com/spreadsheets/d/e/GOOGLETSVOUTPUTKEY/pub?output=tsv"
~~~~

----
Program help (output mono text example)

~~~~
  rubyslippers.sh: (options) 
    installfiles) # copy files in /usr/local/bin  must be root
    setupServer) # initial server setup must be root
    setupClient) # initial setup must be root
    callhomefirst) # callhome first to test ssh call home
    showconnected) # show machies connected to server
    tapshoes) # no place like home
    logged) # All machines output logged to google tsv to screen
    lsshids) # list sshid port
    join) # join network $1 $2 $3 $4 $5  (server side only)
    myinfo) # last cpuinfo info
    mysshid) # cpuinfo and sshid
    cleantmp) # cleantmpfiles
    heartbeat) # find anything changed and submit to google form
~~~~


Home Server (aka Home) side setup: needed vpsusername


Crontab scheduler permissions

crontab -l root

crontab -l pi (vpsuser) 


Edit rubyslippers.sh
* inbound ssh port needed
* Google web publish url
* Google live form url
Add @root crontab -l


Client (aka RemoteRaspi) side setup:
Edit rubyslippers.sh
* Google web publish url
* Google live form url
Add @vpsuser crontab -l




Credits:
(https://eureka.ykyuen.info/2014/07/30/submit-google-forms-by-curl-command/)
A Brief Tunneling Tutorial by s0ke - 2600 issue 35 Winter 2019
Inspiration:
#telesploit @altbier

