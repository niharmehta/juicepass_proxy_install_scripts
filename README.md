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

3)	Connect to your Pi over ssh (ssh user@ipaddress) using the user/password set during imaging.  
Let wireless 
sudo raspi-config
Localisation Options -> WLAN Country -> <select_country>

Finish and Exit



4)	scp copy your preferred install file to your $HOME directory. You can also vi/nano the filename and paste the contents in.  
**!! YOU MUST REVIEW SCRIPT AND CONFIGURE THE OPTIONS SPECIFIC TO YOUR ENVIRONMENT  !!**  

Select the deployment version appropriate for your environment: 

install_jpp_pi_nat.sh  
or:  
install_jpp_pi_routing.sh  

* (Recommended) The _nat.sh version sets up a NAT for traffic from the wlan0 (where JB is connected) so that the outside sees it as the ip address of the eth0 interface.  However, only tcp/2000 is forwarded fallowing telnet to the JB from your LAN. No modifications on your home router configuration is necessary as the IP address of the JB will show up as eth0 interface on your Pi. 
  
* The _routing.sh option does not do a NAT and allows full routing of all traffic between the wlan0 and eth0 intefaces. This allows you to ping the JB, or add other hosts on the wlan0. However it likely requires adding a static route on your home router for the 192.168.50.0/24 network pointing to the eth0 ip address . (Important that this address is the same every time it boots)  

Use your editor (ie. nano or vi)  to edit the configuration options for JB SSID/Password, JB MacAddres, and other options. Then save. 



5)	Back on the ssh command line, set the script you installed  to be executable  
chmod +x install_jpp_pi_[nat,routing].sh  


6)	run the script then reboot:  
sudo ./install_jpp_pi_[nat,routing].sh  

** When the blue dialog box pops up asking if you want to save your netfilter rules (iptables rules) .. say NO as it is a new install . Rules will be added later in the script.  


7)	When complete reboot.  
sudo reboot  

8) If you have not already, reconfigure your Juicebox to the new SSID and Passphrase configured in the hostapd section. 
9) Your Juicepassproxy is now ready to use. It should connect to your Juicebox and MQTT server. 
