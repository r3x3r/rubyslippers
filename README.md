# rubyslippers
Raspberry pi autossh bash auto-ssh script utilizing google spreadsheets.

No outside ports are needed to be forwarded to client raspberry pi on remote network.

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
sshinport=686
vpsuser=pi
~~~~
----
4. Choose your virtual loopback ssh starting port.  Begins at 2200 and increments +1 for each unique hawrdware ID raspi remote client not found in google sheet online.  
~~~~
vloopstart=2200
~~~~

5. Create Google Sheet to use as a database.

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

Server (aka Home) side setup:

Edit rubyslippers.sh
* incomming ssh port
* Google web publish url
* Google live form url
Add to root crontab

Client (aka RemoteRaspi) side setup:
Edit rubyslippers.sh
* Google web publish url
* Google live form url
Add to vpsuser crontab


