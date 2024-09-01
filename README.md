# Automated Virtualization

This is a 3rd semester university project. After the defense, got the maximum amount of points for it.

## The task was:

Create virtual machines using OpenNebula:

1. "ansible-vm" - where the Ansible tool will be installed and from which you will configure all other VMs (Linux OS);
   
2.  "db-vm" - where the selected database would be installed and configured (Linux OS);
   
3. "webserver-vm" - where your website files would be located (Linux OS);

4. "client-vm" - in which a browser would be installed, an account for an ordinary user (Linux OS) would be created;
   
Program the website according to the requirements:

Call center: functionality (all html windows with links to other pages) with the possibility to receive a call by pressing the appropriate button on the website.

## On this repository:

1. main.sh - the script that installs OpenNebula tool and creates VMs;

2. dm.yml - Ansible script that installs MySQL, configures the database;

3. webserver.yml - Ansible script that installs Apache, MySQL, sets up the website;

4. client.yml - Ansible script that installs Gnome, Google Chrome and creates a system user;

5. ./website - folder with files of a simple website with a possibility to receive a call via Twilio
