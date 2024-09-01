#!/bin/bash
wget -q -O- https://downloads.opennebula.org/repo/repo.key | sudo apt-key add -
echo "deb [trusted=yes] https://downloads.opennebula.org/repo/5.6/Ubuntu/18.04 stable opennebula" | sudo tee /etc/apt/sources.list.d/opennebula.list
sudo apt update
sudo apt install -y opennebula-tools
sudo apt install -y ansible
sudo apt install -y sshpass

echo -e "SSH key creation"
eval $(ssh-agent -s)
ssh-keygen -f ~/.ssh/id_rsa
ssh-add

CENDPOINT=https://grid5.mif.vu.lt/cloud3/RPC2

read -p "Please enter your OpenNebula username for webserver-vm: " CUSER_WEBSERVER
read -s -p "Please enter your OpenNebula password for webserver-vm: " CPASS_WEBSERVER
echo
WEBSERVER_REZ=$(onetemplate instantiate "debian12-lxde-password" --name "webserver-vm" --user "$CUSER_WEBSERVER" --password "$CPASS_WEBSERVER" --endpoint $CENDPOINT)
WEBSERVER_ID=$(echo $WEBSERVER_REZ |cut -d ' ' -f 3)

read -p "Please enter your OpenNebula username for db-vm: " CUSER_DB
read -s -p "Please enter your OpenNebula password for db-vm: " CPASS_DB
echo
DB_REZ=$(onetemplate instantiate "debian12-lxde-password" --name "db-vm" --user "$CUSER_DB" --password "$CPASS_DB" --endpoint $CENDPOINT)
DBVM_ID=$(echo $DB_REZ |cut -d ' ' -f 3)

read -p "Please enter your OpenNebula username for client-vm: " CUSER_CLIENT
read -s -p "Please enter your OpenNebula password for client-vm: " CPASS_CLIENT
echo
CLIENT_REZ=$(onetemplate instantiate "debian12-lxde-password" --name "client-vm" --user "$CUSER_CLIENT" --password "$CPASS_CLIENT" --endpoint $CENDPOINT)
CLIENTVM_ID=$(echo $CLIENT_REZ |cut -d ' ' -f 3)

echo "Waiting for Virtual Machines to run for 60 seconds..."
sleep 60

onevm show "$WEBSERVER_ID" --user "$CUSER_WEBSERVER" --password "$CPASS_WEBSERVER" --endpoint "$CENDPOINT" > "$WEBSERVER_ID.txt"
WEBSERVER_CON=$(cat $WEBSERVER_ID.txt | grep CONNECT\_INFO1| cut -d '=' -f 2 | tr -d '"'|sed 's/'$CUSER_WEBSERVER'/root/')
WEBSERVER_IP=$(cat $WEBSERVER_ID.txt | grep PRIVATE\_IP| cut -d '=' -f 2 | tr -d '"')
WEBSERVER_PUBLIC_IP=$(cat $WEBSERVER_ID.txt | grep PUBLIC\_IP| cut -d '=' -f 2 | tr -d '"')
echo -e "Webserver-vm\nPrivate IP: $WEBSERVER_IP\nPublic IP: $WEBSERVER_PUBLIC_IP"
printf "[webserver]\n$CUSER_WEBSERVER@$WEBSERVER_IP\n\n" > hosts
sshpass -p "password" ssh-copy-id -o StrictHostKeyChecking=no "$CUSER_WEBSERVER@$WEBSERVER_IP"

onevm show "$DBVM_ID" --user "$CUSER_DB" --password "$CPASS_DB" --endpoint "$CENDPOINT" > "$DBVM_ID.txt"
DB_CON=$(cat $DBVM_ID.txt | grep CONNECT_INFO1| cut -d '=' -f 2 | tr -d '"'|sed 's/'$CUSER_DB'/root/')
DB_IP=$(cat $DBVM_ID.txt | grep PRIVATE_IP| cut -d '=' -f 2 | tr -d '"')
DB_PUBLIC_IP=$(cat $DBVM_ID.txt | grep PUBLIC\_IP| cut -d '=' -f 2 | tr -d '"')
echo -e "DBserver-vm\nPrivate IP: $DB_IP\nPublic IP: $DB_PUBLIC_IP"
printf "[dbserver]\n$CUSER_DB@$DB_IP\n\n" >> hosts
sshpass -p "password" ssh-copy-id -o StrictHostKeyChecking=no "$CUSER_DB@$DB_IP"


onevm show "$CLIENTVM_ID" --user "$CUSER_CLIENT" --password "$CPASS_CLIENT" --endpoint "$CENDPOINT" > "$CLIENTVM_ID.txt"
CLIENT_CON=$(cat $CLIENTVM_ID.txt | grep CONNECT_INFO1| cut -d '=' -f 2 | tr -d '"'|sed 's/'$CUSER_CLIENT'/root/')
CLIENT_IP=$(cat $CLIENTVM_ID.txt | grep PRIVATE_IP| cut -d '=' -f 2 | tr -d '"')
CLIENT_PUBLIC_IP=$(cat $CLIENTVM_ID.txt | grep PUBLIC\_IP| cut -d '=' -f 2 | tr -d '"')
echo -e "Clientserver-vm\nPrivate IP: $CLIENT_IP\nPublic IP: $CLIENT_PUBLIC_IP"
printf "[clientserver]\n$CUSER_CLIENT@$CLIENT_IP\n\n" >> hosts
sshpass -p "password" ssh-copy-id -o StrictHostKeyChecking=no "$CUSER_CLIENT@$CLIENT_IP"
ansible all -m ping -i ./hosts

PASS=password
read -p "Enter new sudo password: " -s NEWPASS
read -p "Enter new database password: " -s DB_PASSWORD
read -p "Enter new client password: " -s CLIENT_PASSWORD

cat <<EOL > vault.yml
---
sudo_pass: "$PASS"
web_password: "$NEWPASS"
database_password: "$DB_PASSWORD"
client_password: "$CLIENT_PASSWORD"
web_ip: "$WEBSERVER_IP"
db_ip: "$DB_IP"

EOL

ansible-vault encrypt vault.yml

ansible-playbook -i ./hosts db.yml -K --ask-vault-pass
ansible-playbook -i ./hosts webserver.yml -K --ask-vault-pass
ansible-playbook -i ./hosts client.yml -K --ask-vault-pass

exit 0