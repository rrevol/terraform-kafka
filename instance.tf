/*
 * Kafka instances
 */

resource "aws_instance" "zookeeper-server" {
  count = "${var.deploy_kafka_cluster=="false"?0:data.aws_subnet.static-subnet.count}"
  ami = "${var.zookeeper_ami}"
  instance_type = "${var.zookeeper_instance_type}"
  vpc_security_group_ids = ["${var.security_group_ids}"]
  subnet_id = "${var.static_subnet_ids[count.index]}"
  private_ip = "${cidrhost(element(data.aws_subnet.static-subnet.*.cidr_block, count.index), var.zookeeper_addr)}"
  iam_instance_profile = "${var.iam_instance_profile}"
  key_name = "${var.key_name}"
  tags {
    Name = "${var.project}_${var.platform}-zk-${format("%02d", count.index+1)}"
    Project = "${var.project}"
    Team = "${var.team}"
    Platform = "${var.platform}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "kafka-server" {
  count = "${var.deploy_kafka_cluster=="false"?0:(var.brokers_per_az * data.aws_subnet.subnet.count)}"
  ami = "${var.kafka_ami}"
  instance_type = "${var.kafka_instance_type}"
  vpc_security_group_ids = ["${var.security_group_ids}"]
  subnet_id = "${var.subnet_ids[count.index % data.aws_subnet.subnet.count]}"
  iam_instance_profile = "${var.iam_instance_profile}"
  key_name = "${var.key_name}"
  user_data = "${data.template_file.mount-volumes.rendered}"
  availability_zone = "${var.availability_zones[count.index % var.availability_zones_nb]}"
  tags {
    Name = "${var.project}_${var.platform}-kafka-${format("%02d", count.index+1)}"
    Project = "${var.project}"
    Team = "${var.team}"
    Platform = "${var.platform}"
  }
}
