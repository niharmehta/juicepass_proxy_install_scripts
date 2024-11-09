JPP on dedicated Wired + Wireless AP Raspberry Pi 


Instructions to configure a Raspberry Pi to act as a dedicated Wireless AP for JB and connect to internal LAN using wired ethernet. 

Packages and services
JuicePassProxy
Docker
Portainer
HostAPD (run access point on wlan0)
DNSMasq  DHCP server and (DNS Intercept of directory API and jbv1.emotorwerks.com)
IPforward – Routing between interfaces
Iptables – Perform port intercept & rewrite for 8042 and 8047
Journtlctl – Tune journal to minimize disk writes for logs


Hardware : RPi 3b.
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

* (Recommended) The _nat.sh version sets up a NAT for traffic from the wlan0 (where JB is connected) so that the outside sees it as the ip address of the eth0 interface.  However, only tcp/2000 is forwarded fallowing telnet to the JB from your LAN. No modifications on your home router configuration is necessary as the IP address of the JB will show upas eth0 interface on your Pi. 
  
* The _routing.sh option does not do a NAT and allows full routing of all traffic between the wlan0 and eth0 intefaces. This allows you to ping the JB, or add other hosts on the wlan0. However it likely requires adding a static route on your home router for the 192.168.50.0/24 network pointing to the eth0 ip address . (Important that this address is the same every time it boots) 

Use your editor (ie. nano or vi)  to edit the configuration options for JB SSID/Password, JB MacAddres, and other options. Then save. 



5)	Back on the ssh command line, set the script you installed  to be executable
chmod +x install_jpp_pi_[nat,routing].sh





6)	run the script then reboot :
sudo ./install_jpp_pi_[nat,routing].sh

** When the blue dialogue box pops up asking if you want to save your netfilter rules (iptables rules) .. say NO as it is a new install . Rules will be added later in the script.


7)	When complete reboot.
sudo reboot


8)	Install JPP container via command line, docker-compose, or within portainer
https://github.com/JuiceRescue/juicepassproxy/pull/69 
https://github.com/ivanfmartinez/juicepassproxy/tree/juicebox_commands
(using ghcr.io/niharmehta/juicepassproxy:latest) 

You can also use portainer ( http://eth0_ipaddres:9000)


In case JPP logs are not showing data from the JB, 
Try mapping ports udp 8042:8047 and udp 8047:8047 may help. 

Also for NAT mode, you may want to set JPP_Host to the wlan0 IP address : 192.168.50.1 

Network Mode: bridge  
Port Mapping : 8047:8047 udp

Volumes:
/etc/localhost : /etc/localhost - Read-Only
/config : /config - Writable

Sample env values for JPP container:
DEBUG = true  
ENELX_IP = 158.47.1.128:8042  
EXPERIMENTAL = true  
IGNORE_ENELX = true  
JPP_HOST = <eth0_ip_address>   (if this does not work, try 192.168.50.1 wlan0 interface) 
JUICEBOX_HOST = 192.168.50.5  
JUICEBOX_ID = <juicebox serial/device id>   
MQTT_HOST = <mqtt_ip_address>  
MQTT_PASS = <mqtt_password>  
MQTT_USER = <mqtt_user>  
UPDATE_UDPC = false  


