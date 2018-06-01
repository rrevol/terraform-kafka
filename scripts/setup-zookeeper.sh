#!/bin/bash
# Script to start a zookeeper Docker container

# unload command line
id=$1

echo "#install java"
sudo yum install -y java-1.8.0

echo "# install aws"
sudo yum install -y python-2.7.5-58.el7.x86_64
curl --silent "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
pip install pip==10.0.1
pip install awscli --upgrade
sudo chmod +x /usr/bin/aws

# create an array of IPs
ip_addrs=( ${ip_addrs} )

echo "# create zookeeper user"
mkdir -p /opt/zookeeper
if ! id zookeeper 2> /dev/null; then
    useradd -d /opt/zookeeper zookeeper
fi

echo "# download zookeeper"
base_name=zookeeper-${version}
mkdir /home/centos/install
cd /home/centos/install
curl -O ${repo}/$base_name/$base_name.tar.gz

echo "# unpack the tarball"
cd /opt/zookeeper
tar xzf /home/centos/install/$base_name.tar.gz
rm /home/centos/install/$base_name.tar.gz
cd $base_name

echo "# create a data dir"
mkdir -p /var/lib/zookeeper

echo "# configure the server"
cat conf/zoo_sample.cfg \
    | sed 's|dataDir=/home/centos/install/zookeeper|dataDir=/var/lib/zookeeper|' \
    > /home/centos/install/zoo.cfg
echo "# server list" >> /home/centos/install/zoo.cfg
for i in {1..${count}}; do
    echo "server.$i=$${ip_addrs[$((i-1))]}:2888:3888" >> /home/centos/install/zoo.cfg
done
mv /home/centos/install/zoo.cfg conf/zoo.cfg

echo "# configure the logging"
cat conf/log4j.properties \
    | sed 's/zookeeper.root.logger=INFO, CONSOLE/zookeeper.root.logger=INFO/' \
    > /home/centos/install/log4j.properties
mv /home/centos/install/log4j.properties conf/log4j.properties

echo "# set the ID"
echo $id > /var/lib/zookeeper/myid

echo "# change ownership"
chown -R zookeeper:zookeeper /opt/zookeeper
chown -R zookeeper:zookeeper /var/lib/zookeeper
