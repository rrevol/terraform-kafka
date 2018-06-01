/*
 * Kafka provisioners
 */

resource "null_resource" "zookeeper-nodes" {
  count = "${var.deploy_kafka_cluster=="false"?0:aws_instance.zookeeper-server.count}"
  triggers {
    zookeeper_id = "${element(aws_instance.zookeeper-server.*.id, count.index)}"
  }
  connection {
    host = "${element(aws_instance.zookeeper-server.*.private_ip, count.index)}"
    user = "${var.zookeeper_user}"
    private_key = "${file(var.private_key)}"
    bastion_host = "${var.bastion_ip}"
    bastion_user = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
    script_path = "/home/centos/zookeeper-deployment.sh"
  }
  provisioner "file" {
    content = "${data.template_file.setup-zookeeper.rendered}"
    destination = "/home/centos/setup-zookeeper.sh"
  }
  provisioner "file" {
    content = "${data.template_file.zookeeper-ctl.rendered}"
    destination = "/home/centos/zookeeper-ctl"
  }
  provisioner "file" {
    content = "${data.template_file.zookeeper-status.rendered}"
    destination = "/home/centos/zookeeper-status.sh"
  }
  provisioner "file" {
    source = "${path.module}/scripts/zookeeper_firewallRule.xml"
    destination = "/home/centos/zooKeeper.xml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/centos/zooKeeper.xml /etc/firewalld/services/zooKeeper.xml",
      "sudo service firewalld restart",
      "sudo firewall-cmd --permanent --add-service=zooKeeper",
      "sudo service firewalld restart",
      "sudo firewall-cmd --list-services",
      "chmod +x /home/centos/setup-zookeeper.sh",
      "sudo /home/centos/setup-zookeeper.sh ${count.index+1}",
      "rm /home/centos/setup-zookeeper.sh",
      "sudo mv /home/centos/zookeeper-ctl /etc/init.d/zookeeper",
      "sudo chmod a+x /etc/init.d/zookeeper",
      "sudo chown root:root /etc/init.d/zookeeper",
      "sudo chkconfig zookeeper on",
      "sudo service zookeeper start",
      "sudo mv /home/centos/zookeeper-status.sh /opt/zookeeper",
      "sudo chmod a+x /opt/zookeeper/zookeeper-status.sh",
      "sudo chown zookeeper:zookeeper /opt/zookeeper/zookeeper-status.sh",
      "echo '* * * * * /opt/zookeeper/zookeeper-status.sh' > /home/centos/crontab",
      "sudo crontab -u zookeeper /home/centos/crontab",
      "rm /home/centos/crontab",
      "rm /home/centos/*zookeeper*"
    ]
  }
}

resource "null_resource" "kafka-nodes" {
  count = "${aws_instance.kafka-server.count}"
  depends_on = ["null_resource.zookeeper-nodes"]
  triggers {
    kafka_attach_id = "${element(aws_volume_attachment.attach.*.id, count.index)}"
    zookeeper_id = "${join(",", null_resource.zookeeper-nodes.*.id)}"
  }
  connection {
    host = "${element(aws_instance.kafka-server.*.private_ip, count.index)}"
    user = "${var.kafka_user}"
    private_key = "${file(var.private_key)}"
    bastion_host = "${var.bastion_ip}"
    bastion_user = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
    script_path = "/home/centos/kafka-deployment.sh"
  }
  provisioner "file" {
    content = "${element(data.template_file.setup-kafka.*.rendered, count.index)}"
    destination = "/home/centos/setup-kafka.sh"
  }
  provisioner "file" {
    content = "${data.template_file.kafka-ctl.rendered}"
    destination = "/home/centos/kafka-ctl"
  }
  provisioner "file" {
    content = "${data.template_file.kafka-status.rendered}"
    destination = "/home/centos/kafka-status.sh"
  }
  provisioner "file" {
    source = "${path.module}/scripts/kafka_firewallRule.xml"
    destination = "/home/centos/kafka.xml"
  }
  provisioner "file" {
    source = "${path.module}/scripts/zookeeper_firewallRule.xml"
    destination = "/home/centos/zooKeeper.xml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/centos/kafka.xml /etc/firewalld/services/kafka.xml",
      "sudo cp /home/centos/zooKeeper.xml /etc/firewalld/services/zooKeeper.xml",
      "sudo service firewalld restart",
      "sudo firewall-cmd --permanent --add-service=zooKeeper",
      "sudo firewall-cmd --permanent --add-service=kafka",
      "sudo service firewalld restart",
      "sudo firewall-cmd --list-services",
      "chmod +x /home/centos/setup-kafka.sh",
      "sudo /home/centos/setup-kafka.sh ${count.index} ${element(data.aws_subnet.subnet.*.availability_zone, count.index % data.aws_subnet.subnet.count)}",
      "rm /home/centos/setup-kafka.sh",
      "sudo mv /home/centos/kafka-ctl /etc/init.d/kafka",
      "sudo chmod a+x /etc/init.d/kafka",
      "sudo chown root:root /etc/init.d/kafka",
      "sudo chkconfig kafka on",
      "sudo service kafka start",
      "sudo mv /home/centos/kafka-status.sh /opt/kafka",
      "sudo chmod a+x /opt/kafka/kafka-status.sh",
      "echo '* * * * * /opt/kafka/kafka-status.sh' > /home/centos/crontab",
      "sudo crontab /home/centos/crontab",
      "rm /home/centos/crontab",
      "rm /home/centos/*zookeeper*",
      "rm /home/centos/*kafka*"
    ]
  }
}
