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
* Home router to port forward incomming port to static IP raspberry pi.
* raspberry pi
*



----
Create Google Sheet to use as a database
* example: piConnectBack

Create with 8 short answer text questions make them all required answered
Goto Tools menu, select Create form
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
