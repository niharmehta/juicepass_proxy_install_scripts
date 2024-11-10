JPP on dedicated Wired + Wireless AP Raspberry Pi 


Instructions to configure a Raspberry Pi to act as a dedicated Wireless AP for JB and connect to internal LAN using wired ethernet.   

*** Important: For reliable operation,  CONFIGURE YOUR JUICEBOX TO A NEW SSID THAT IS USED BETWEEN IT AND THE PI WHICH IS ACTING AS A WIFI ACCESS POINT.  



Packages and services installed and configured:  
Docker  
Portainer  
HostAPD (run access point on wlan0)  
DNSMasq  DHCP server and (DNS Intercept of directory API and jbv1.emotorwerks.com)  
IPforward – Routing between interfaces  
Iptables – Perform port intercept & rewrite for 8042 and 8047  
JuicePass Proxy - The main application container to interface  with Juicebox and your MQTT server (and more)   
iotop - disk diagnostics  
logrotate - creates an entry for rotating the log juicepassproxy log file 
journtald - moves log file to  ram  and limits size. 


This script also makes some changes to minimize writes to the SDCard to limit its wear over time. 
This includes:
* Moving journalctl logs to ram
* Moving /var/log to tmpfs ram and using aggressive logrotate sizes
* For the JuicePassProxy container, setting the log driver to none for docker logs. However...
* JuicepassProxy currenty writes to an internal log file built. So disabling driver does not eliminate writes.
* Mapping Container /log directory to /var/log tmpfs allows us to reduce writes.
* /var/log/juicepassproxy.log will contain the real time logs from JPP.  


Tested Hardware : RPi 3b   Should also owork on Pi 4b/5 .  Recommend at least 1GB or RAM. 
Stable Power supply.  
High endurance, good quality MicroSD.  (Genuine Samsung, SanDisk, Raspberry Pi brand)  



1)	Use Raspberry Pi install to image microsd for os.
Recommend to use 64bit ‘lite’ version (3b/4b/5) 
After, remove card from PC/Mac and insert and power on Pi. Wait 3-4 minutes for initial boot. 
<img width="535" alt="Screenshot 2024-11-09 at 12 34 51 AM" src="https://github.com/user-attachments/assets/21ddee12-b4f2-4b69-8076-72f3e6b4a9f5">




 


2)	Find IP address from your router. It is recommended you make this ip address a static dhcp reservation. 



3)	scp copy  the install script to your $HOME directory. It will be /home/$USER which is the user created during imaging...
You can also vi/nano the filename and paste the contents in.  
**!! YOU MUST REVIEW SCRIPT AND CONFIGURE THE OPTIONS SPECIFIC TO YOUR ENVIRONMENT  !!**  

ie.   scp install_jpp_pi_.sh  $USER@192.168.1.99:/home/$USER  

The script will run in two modes based on arguments passduring when running the script  --mode=nat and --mode=routing.  The NAT mode is default if no value is passed . 

* (Recommended & Default) The --mode=nat  argument  sets up a NAT for traffic from the wlan0 (where JB is connected) so that the outside sees it as the ip address of the eth0 interface.  However, only tcp/2000 is forwarded fallowing telnet to the JB from your LAN. No modifications on your home router configuration is necessary as the IP address of the JB will show up as eth0 interface on your Pi. 
  
* The --mode=routing argument does not do a NAT to the eth0 IP and allows full routing of all traffic between the wlan0 and eth0 intefaces. This allows you to ping the JB, or add other hosts on the wlan0. However it likely requires adding a static route on your home router for the 192.168.50.0/24 network pointing to the eth0 ip address of your pi . (Important that this address is the same every time it boots)  

Use your editor (ie. nano or vi)  to edit the configuration options for JB SSID/Password, JB MacAddres, and other options. Then save. 


4)	Connect to your Pi over ssh (ssh user@ipaddress) using the user/password set during imaging.

5)	Back on the ssh command line, set the script you installed  to be executable  
chmod +x install_jpp_pi.sh  


6)	run the script with optional arguments then reboot:  
sudo ./install_jpp_pi.sh  [--mode=nat or --mode=routing] 

** IF A netfilter/iptables persistant dialog box pops up asking if you want to save your netfilter rules (iptables rules) .. say NO as it is a new install . Rules will be added later in the script. This should not be neceessary as 


7)	When complete reboot.  
sudo reboot  

8) If you have not already, reconfigure your Juicebox to the new SSID and Passphrase configured in the hostapd section. 
9) Your Juicepassproxy is now ready to use. It should connect to your Juicebox and MQTT server. 



--------------
This script moves /logs and journald logs to memory to reduce sdcard wear.  By default, logs from the Juicepassproxy will be handled by the journald process in the host operating sytstem. The journald process has been configured to only log to memory, so it is not persistant across reboots, and caps the memory used by the logging to 32MB before the logs are trimmed.  If you need to review logs, these commands can be used to review logs:

Cat current logs related to the juicebox-commands container  
sudo journalctl CONTAINER_NAME=juicebox-commands  

Follow logs in real time.  
sudo journalctl -f CONTAINER_NAME=juicebox-commands  

Although not recommended and likely not needed, the $JPP_LOG_LOC can be set to '/log' which will then create a log file  /var/log/juicepassproxy.log . The script sets /var/log to tempfs (memory) and logrorate SHOULD rotate this log file.  Use the default journalctl method to handle logs if possible. 
