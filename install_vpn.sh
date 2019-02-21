#/bin/bash

#################################
#Variables Declarations
#################################
INST_DIR="/etc/openvpn"
OV_DEFAULT_FILE="/etc/default/openvpn"
KO_DESKTOP_DIR="/home/kioskoperator/Desktop"

#################################
#FUNCTIONS
#################################
function VPNFOLDERCHECK {
if [ ! -d "$VPN_HOME_DIR" ] 
then
	echo "The folder $VPN_HOME_DIR containing does not exist!"
    	echo "##########################################"
	echo "Content of $VPN_HOME_DIR:"
	echo "$(ls -lha $VPN_HOME_DIR)
    	echo "##########################################"
	echo "Please ensure that you have copied the VPN folder which has the name of the KIOSK ID! Did you copied the folder to the kioskoperator's Desktop?"
	echo "Enter y for YES"
	echo "Enter n for NO"
	read COPYMSG
		if [ $COPYMSG -e "y" ]
		then
			VPNFODLERCHECK
		else
			echo "ERROR: the folder has not been found!"
			exit 1
		if
fi
}
###################################
#Script start
##################################
echo "Enter the KIOSK ID (i.e. KE0004, RW0016 or TA0022):"
read USERNAME

VPN_HOME_DIR="$KO_DESKTOP_DIR/$USERNAME"

#Call Function
VPNFOLDERCHECK

#VPN file check
if [ -e "$VPN_HOME_DIR/ca.crt" ] && [ -e "$VPN_HOME_DIR/$USERNAME.crt ] && [ -e "$VPN_HOME_DIR/$USERNAME.key" ] && [ -e "$VPN_HOME_DIR/README.txt" ] 
then
	#READ PASSWORD
	PASSWORD=$(sudo cat $VPN_HOME_DIR/README.txt)
else
	echo "ERROR: Ensure that the folder $VPN_HOME_DIR contains the needed openvpn files (ca.crt, $USERNAME.crt, $USERNAME.key, README.txt)"
	exit 2
fi

##################################
#OPENVPN INSTALLATION
##################################

sudo systemctl stop openvpn@client.service 1>/dev/null 2&>1
sudo systemctl disable openvpn@client.service 1>/dev/null 2&>1

if ! command -v openvpn > /dev/null; then
    sudo apt-get install openvpn
    if [ $? != 0 ]; then
        printf "\n\nopenvpn could not be installed!\n"
        printf "\n\nThe installation proccess could not be finished\n"
        exit
    fi
fi

sudo cp $VPN_HOME_DIR/ca.crt $INST_DIR
sudo cp $VPN_HOME_DIR/$USERNAME.crt $INST_DIR
sudo cp $VPN_HOME_DIR/$USERNAME.key $INST_DIR


sudo rm $OV_DEFAULT_FILE

echo "AUTOSTART=\"all\"" >> $OV_DEFAULT_FILE
echo "OPTARGS=\"\"" >> $OV_DEFAULT_FILE
echo "OMIT_SENDSIGS=0" >> $OV_DEFAULT_FILE

sudo rm -rf $INST_DIR/.secrets

echo "$PASSWORD" >> $INST_DIR/.secrets

sudo rm $INST_DIR/client.ovpn

echo "tls-client" >> $INST_DIR/client.conf
echo "dev tap" >> $INST_DIR/client.conf
echo "proto udp" >> $INST_DIR/client.conf
echo "remote 90.187.46.229 1194" >> $INST_DIR/client.conf
echo "askpass $INST_DIR/.secrets" >> $INST_DIR/client.conf
echo "resolv-retry infinite" >> $INST_DIR/client.conf
echo "nobind" >> $INST_DIR/client.conf
echo "persist-key" >> $INST_DIR/client.conf
echo "persist-tun" >> $INST_DIR/client.conf
echo "ca ca.crt" >> $INST_DIR/client.conf
echo "cert $USERNAME.crt" >> $INST_DIR/client.conf
echo "key $USERNAME.key" >> $INST_DIR/client.conf
echo "comp-lzo" >> $INST_DIR/client.conf
echo "verb 3" >> $INST_DIR/client.conf
echo "pull dhcp-options" >> $INST_DIR/client.conf

#https://www.smarthomebeginner.com/configure-openvpn-to-autostart-linux/
sudo systemctl enable openvpn@client.service
sudo systemctl daemon-reload
sudo systemctl start openvpn@client.service
