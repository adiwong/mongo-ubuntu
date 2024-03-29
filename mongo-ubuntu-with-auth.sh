# Receive parameter for Mongod DB Admin Credentials
mongoAdmin=$1
mongoPass=$2

# Configure mongodb.list file with the correct location 
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list

# Disable THP
sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled
sudo echo never > /sys/kernel/mm/transparent_hugepage/defrag
sudo grep -q -F 'transparent_hugepage=never' /etc/default/grub || echo 'transparent_hugepage=never' >> /etc/default/grub

# Install updates
sudo apt-get -y update

# Modified tcp keepalive according to https://docs.mongodb.org/ecosystem/platforms/windows-azure/
sudo bash -c "sudo echo net.ipv4.tcp_keepalive_time = 120 >> /etc/sysctl.conf"

#Install Mongo DB
sudo apt-get install -y mongodb-org

# Uncomment this to bind to all ip addresses
sudo sed -i -e 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf

sudo service mongod start
sleep 8
mongoCmd="{user: \"$mongoAdmin\", pwd: \"$mongoPass\", roles:[{ role: \"root\", db: \"admin\"}]}"
mongo localhost:27017/admin --eval "db.createUser($mongoCmd)"
sudo sed -i -e 's/#security:/security:\n  authorization: \"enabled\"/g' /etc/mongod.conf
sudo service mongod restart

# limiting ports
sudo ufw default deny incoming 
sudo ufw allow 22
sudo ufw allow 53
sudo ufw allow 27017
echo "y" | sudo ufw enable

# start mongod.service at startup
sudo systemctl enable mongod.service
