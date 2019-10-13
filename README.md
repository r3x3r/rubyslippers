# rubyslippers
Raspberry pi autossh bash script utilizing google spreadsheets.

No outside ports are needed to connect to th remote network

BsidesDFW 2019

Dependencies:
* Google sheet form
* app dependencies: autossh
* file dependencies (provided) : urlencode.sed urldecode.sed
* confiuration files:
* /opt/share/callhome.cfg				(google specific formIDs)
* /opt/share/callhome.homenet		(local raspberry pi information)

Minimum requirements: 
* Home router assign static IP raspberry pi.
* Home router port forward ssh to raspberry pi
* Raspberry pi with Rasbian Buster Lite image from [raspberrypi.org](https://www.raspberrypi.org/downloads/raspbian/ "raspberrypi.org")

1. Follow initial basic setup raspberry prefrences and configuration.
*	Set Locale
*	Set timezone
*	Set Keyboard
*	Under Interfacing Options select ssh
*	change the default pi password with #> passwd
	
----
2. Setup home router assigning static IP address. Be sure to get mac address of raspberry pi to boot up with the same IP address. [many how-to videos](https://www.google.com/search?q=setup+static+ip+home+router+raspberry+pi&source=lnms&tbm=vid "many how-to videos").
----
3. Create Google Sheet to use as a database.

* example: piConnectBack
* goto Tools menu, select Create form

Create with 8 short answer text, all required questions.

* Hostname
* HardwareID
* IPlocal
* OutsideIP
* Release
* SysArch
* Kernel
* Homenet
* ISPname

Form -> goto live form  and copy url 

edit rubyslippers.sh 
~~~~
gliveformurl="https://docs.google.com/forms/d/e/abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrst/viewform"
~~~~

File - > publish to Web
Link section
entire document - Tab-seperated values (.tsv)
expand Published Contents & settings
entire document 
checkbox 
~~~~
glivetsvurl="https://docs.google.com/spreadsheets/d/e/abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmn/pub?output=tsv"
~~~~

----

Server side setup:

Edit rubyslippers.sh
* incomming ssh port
* Google web publish url
* Google live form url

Client side:



Choose inbound port number on home router to point to your 
	refer to your manufacture to port forward inbound
