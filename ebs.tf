/*
 * Kafka EBS configuration
 */

resource "aws_volume_attachment" "attach" {
  count = "${var.deploy_kafka_cluster=="false"?0:aws_instance.kafka-server.count}"
  device_name = "${var.ebs_device_name}"
  volume_id = "${element(var.ebs_volume_ids, count.index)}"
  instance_id = "${element(aws_instance.kafka-server.*.id, count.index)}"
}
