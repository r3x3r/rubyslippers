# rubyslippers
Raspberry pi autossh bash script utilizing google spreadsheets.

* Dependencies:
* Google sheet form
* app dependencies: autossh
* file dependencies (provided) : urlencode.sed urldecode.sed
* confiuration files saved as
	/opt/share/callhome.cfg				(formIDs to submit)
	/opt/share/callhome.homenet		(local raspberry pi information)

Minimum requirements: 
* Home router to port forward ssh incomming port to static IP raspberry pi.
* Raspberry pi with Rasbian Buster Lite image [https://www.raspberrypi.org/downloads/raspbian/]
	Follow initial setup raspberry configuration preferences.
	Set Locale
	Set timezone
	Set Keyboard
	Under Interfacing Options select ssh
	change the default pi password
	
----
Create Google Sheet to use as a database
* example: piConnectBack
Then goto Tools menu, select Create form

Create with 8 short answer text questions make them all required answered
* Hostname
* HardwareID
* IPlocal
* OutsideIP
* Release
* SysArch
* Kernel
* Homenet
* ISPname



Choose inbound port number on home router to point to your 
	refer to your manufacture to port forward inbound
