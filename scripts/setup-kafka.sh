#!/usr/bin/env bash
#
# Script to setup a Kafka server

# unload the command line
broker_id=$1
az=$2

echo "# update java"
sudo yum install -y java-1.8.0

echo "# install aws"
sudo yum install -y python-2.7.5-58.el7.x86_64
curl --silent "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
pip install pip==10.0.1
pip install awscli --upgrade
sudo chmod +x /usr/bin/aws

echo "# add directories that support kafka"
mkdir -p /opt/kafka
mkdir -p /var/run/kafka
mkdir -p /var/log/kafka

echo "# download kafka"
base_name=kafka_${scala_version}-${version}
mkdir /home/centos/install
cd /home/centos/install
curl -O ${repo}/${version}/$base_name.tgz

echo "# unpack the tarball"
cd /opt/kafka
sudo tar xzf /home/centos/install/$base_name.tgz
rm /home/centos/install/$base_name.tgz
cd $base_name

echo "# configure the server"
cat config/server.properties \
    | sed "s|broker.id=0|broker.id=$broker_id|" \
    | sed 's|log.dirs=/home/centos/install/kafka-logs|log.dirs=${mount_point}/kafka-logs|' \
    | sed 's|num.partitions=1|num.partitions=${num_partitions}|' \
    | sed 's|log.retention.hours=168|log.retention.hours=${log_retention}|' \
    | sed 's|zookeeper.connect=localhost:2181|zookeeper.connect=${zookeeper_connect}|' \
    >> /home/centos/install/server.properties
echo >> /home/centos/install/server.properties
echo "# rack ID" >> /home/centos/install/server.properties
echo "broker.rack=$az" >> /home/centos/install/server.properties
echo " " >> /home/centos/install/server.properties
echo "# replication factor" >> /home/centos/install/server.properties
echo "default.replication.factor=${repl_factor}" >> /home/centos/install/server.properties
mv /home/centos/install/server.properties config/server.properties
