#!/bin/bash

# Note. This version NATs the traffic from JB to the external inteface. It should foward tcp 2000 (telnet interface of JB) to the static 192.168.50.5 IP assigned to JB. 
# Change the dhcp-host= entry to match the mac address of your juicebox
# Change any ip address ranges for the wlan0 AP inteface facing the juicebox or leave default
# Change 'server=' entries to reflect any upstream forwarding dns you wish to use. 
# Change the hostapd section with ssid= and wpa_passphrase= matching your environment

# Update package list and install required packages
echo "Installing required packages and updates..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y hostapd dnsmasq iptables-persistent telnet

# Stop dnsmasq and hostapd if they're already running
sudo systemctl stop dnsmasq
sudo systemctl stop hostapd

# Set up static IP configuration for wlan0 in /etc/network/interfaces
echo "Configuring static IP for wlan0..."
sudo bash -c 'cat << EOF > /etc/network/interfaces
# Loopback interface
auto lo
iface lo inet loopback

# Ethernet interface
auto eth0
iface eth0 inet dhcp

# Configure wlan0 interface with a static IP
auto wlan0
iface wlan0 inet static
    address 192.168.50.1
    netmask 255.255.255.0
    network 192.168.50.0
    broadcast 192.168.50.255
EOF'


# Configure hostapd with the specified settings
echo "Configuring hostapd..."
sudo bash -c 'cat << EOF > /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
ssid=<wlan_for_jb>
hw_mode=g
channel=1
ieee80211n=1
wmm_enabled=1
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=<wlan_password>
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
EOF'


# Configure dnsmasq for DHCP and DNS
echo "Configuring dnsmasq..."
sudo bash -c 'cat << EOF > /etc/dnsmasq.conf
# Listen on wlan0 for DHCP and DNS
interface=wlan0

# DHCP configuration
dhcp-range=192.168.50.10,192.168.50.100,12h
dhcp-option=3,192.168.50.1      # Default gateway
dhcp-option=6,192.168.50.1      # DNS server
dhcp-host=xx:xx:xx:xx:xx:xx,192.168.50.5  # Reserved IP for specific MAC

# Set OpenDNS as the upstream DNS servers
server=208.67.222.222
server=208.67.220.220


# DNS redirection entries
address=/directory-api.emotorwerks.com/127.0.0.1
address=/jbv1.emotorwerks.com/192.168.50.1
address=/juicenet-udp-prod5-usa.enelx.com/192.168.50.1
EOF'


# Enable IP forwarding
echo "Enabling IP forwarding..."
sudo sed -i '/^#net.ipv4.ip_forward=1/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
sudo sysctl -p

# Set up iptables rules for NAT and port forwarding
echo "Setting up iptables rules..."
# Port forwarding rule for TCP traffic on port 2000 to 192.168.50.5
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 2000 -j DNAT --to-destination 192.168.50.5:2000

# forward and redirect JB UDP ports to JPP container service
sudo iptables -t nat -A PREROUTING -p udp -m multiport --dports 8042,8043,8047 -j DNAT --to-destination 192.168.50.1:8047

# Masquerade rule for outbound traffic from 192.168.50.0/24 going out on eth0
sudo iptables -t nat -A POSTROUTING -s 192.168.50.0/24 -o eth0 -j MASQUERADE


# Save iptables rules to make them persistent across reboots
echo "Saving iptables rules for persistence..."
sudo netfilter-persistent save



# Enable and restart services
echo "Enabling and restarting services..."
sudo systemctl restart networking
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd

# Install Docker CE
echo "Installing Docker CE..."
curl -sSL https://get.docker.com | sh

# Add the current user to the docker group
echo "Adding current user to the docker group..."
sudo usermod -aG docker $USER

# Install Portainer CE as a Docker container
echo "Installing Portainer CE..."
sudo docker volume create portainer_data
docker run -d -p 9000:9000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest


echo "Installation and configuration complete. 'sudo reboot' the system to apply all settings. Install JPP using instructions  https://github.com/JuiceRescue/juicepassproxy"

