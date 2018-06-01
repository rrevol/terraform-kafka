/*
 * Kafka EBS configuration
 */
resource "aws_ebs_volume" "volume" {
  count = "${var.deploy_kafka_cluster=="true"?(var.brokers_per_az * var.availability_zones_nb):0}"
  availability_zone = "${var.availability_zones[count.index % var.availability_zones_nb]}"
  type = "st1"
  size = "${var.ebs_size}"

  tags {
    Name = "${var.project}_${var.platform}_${format("%02d", count.index+1)}"
    Project = "${var.project}"
    Team = "${var.team}"
    Platform = "${var.platform}"
  }
}

resource "aws_volume_attachment" "attach" {
  count = "${var.deploy_kafka_cluster=="false"?0:aws_instance.kafka-server.count}"
  device_name = "${var.ebs_device_name}"
  volume_id = "${element(aws_ebs_volume.volume.*.id, count.index)}"
  instance_id = "${element(aws_instance.kafka-server.*.id, count.index)}"
}
