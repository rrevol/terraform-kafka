/*
 * Kafka data
 */

data "aws_subnet" "subnet" {
  count = "${var.deploy_kafka_cluster=="false"?0:var.subnet_count}"
  id = "${var.subnet_ids[count.index]}"
}

data "aws_subnet" "static-subnet" {
  count = "${var.deploy_kafka_cluster=="false"?0:var.static_subnet_count}"
  id = "${var.static_subnet_ids[count.index]}"
}
