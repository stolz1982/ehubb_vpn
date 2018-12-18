#/bin/bash
INST_DIR="/etc/openvpn"
OV_DEFAULT_FILE="/etc/default/openvpn"

echo "Enter the KIOSK ID, must be unique to the VPN Username:""
read USERNAME

echo "Enter the VPN Password:""
read PASSWORD

VPN_HOME_DIR="/home/administrator/$USERNAME"

if [ ! -d "$VPN_HOME_DIR" ] 
then
    echo "The folder $VPN_HOME_DIR containing the vpn files does not exist!"
    exit 1
fi

echo "Ensure that the openvpn files has been copied in the E-HUBB local file system in /etc/openvpn (ca.crt, $USERNAME.crt, $USERNAME.key)"


sudo systemctl stop openvpn@client.service
sudo systemctl disable openvpn@client.service

# Install openvpn
if ! command -v openvpn > /dev/null; then
    sudo apt-get install openvpn
    if [ $? != 0 ]; then
        printf "\n\nopenvpn could not be installed!\n"
        printf "\n\nThe installation proccess could not be finished\n"
        exit
    fi
fi
sudo cp $VPN_HOME_DIR/* $INST_DIR
sudo rm $OV_DEFAULT_FILE

echo "AUTOSTART=\"all\"" >> $OV_DEFAULT_FILE
echo "OPTARGS=\"\"" >> $OV_DEFAULT_FILE
echo "OMIT_SENDSIGS=0" >> $OV_DEFAULT_FILE


cd $INST_DIR

sudo rm -rf $INST_DIR/.secrets

echo "$USERNAME" > $INST_DIR/.secrets
echo "$PASSWORD" >> $INST_DIR/.secrets

sudo rm $INST_DIR/$USERNAME.ovpn

echo "tls-client" >> $INST_DIR/$USERNAME.ovpn
echo "dev tap" >> $INST_DIR/$USERNAME.ovpn
echo "proto udp" >> $INST_DIR/$USERNAME.ovpn
echo "remote 90.187.46.229 1194" >> $INST_DIR/$USERNAME.ovpn
echo "resolv-retry infinite" >> $INST_DIR/$USERNAME.ovpn
echo "nobind" >> $INST_DIR/$USERNAME.ovpn
echo "persist-key" >> $INST_DIR/$USERNAME.ovpn
echo "persist-tun" >> $INST_DIR/$USERNAME.ovpn
echo "ca ca.crt" >> $INST_DIR/$USERNAME.ovpn
echo "cert $USERNAME.crt" >> $INST_DIR/$USERNAME.ovpn
echo "key $USERNAME.key" >> $INST_DIR/$USERNAME.ovpn
echo "comp-lzo" >> $INST_DIR/$USERNAME.ovpn
echo "verb 3" >> $INST_DIR/$USERNAME.ovpn
echo "pull dhcp-options" >> $INST_DIR/$USERNAME.ovpn
echo "auth-users-pass .secrets" >> $INST_DIR/$USERNAME.ovpn

#https://www.smarthomebeginner.com/configure-openvpn-to-autostart-linux/
sudo systemctl enable openvpn@client.service
sudo systemctl daemon-reload
sudo systemctl start openvpn@client.service




