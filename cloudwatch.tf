/*
 * CloudWatch alarm configuration.
 */

resource "aws_cloudwatch_metric_alarm" "zookeeper-cpu-alarm" {
  count = "${var.cloudwatch_alarm_arn==""?0:aws_instance.zookeeper-server.count}"
  alarm_name = "${format("%s-zk-cpu-%02d", var.project, var.platform, count.index+1)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "5"
  namespace = "AWS/EC2"
  metric_name = "CPUUtilization"
  period = "60"
  statistic = "Average"
  threshold = "80"
  dimensions {
    InstanceId = "${element(aws_instance.zookeeper-server.*.id, count.index)}"
  }
  alarm_actions = ["${var.cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "kafka-cpu-alarm" {
  count = "${var.cloudwatch_alarm_arn==""?0:aws_instance.kafka-server.count}"
  alarm_name = "${format("%s-kafka-cpu-%s-%02d", var.project, var.platform, element(data.aws_subnet.subnet.*.availability_zone, count.index), (count.index/data.aws_subnet.subnet.count)+1)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "5"
  namespace = "AWS/EC2"
  metric_name = "CPUUtilization"
  period = "60"
  statistic = "Average"
  threshold = "80"
  dimensions {
    InstanceId = "${element(aws_instance.kafka-server.*.id, count.index)}"
  }
  alarm_actions = ["${var.cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "zookeeper-status-alarm" {
  count = "${var.cloudwatch_alarm_arn==""?0:aws_instance.zookeeper-server.count}"
  alarm_name = "${format("%s_%s-zk-status-%02d", var.project, var.platform, count.index+1)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  namespace = "AWS/EC2"
  metric_name = "StatusCheckFailed"
  period = "60"
  statistic = "Average"
  threshold = "1"
  dimensions {
    InstanceId = "${element(aws_instance.zookeeper-server.*.id, count.index)}"
  }
  alarm_actions = ["${var.cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "kafka-status-alarm" {
  count = "${var.cloudwatch_alarm_arn==""?0:aws_instance.kafka-server.count}"
  alarm_name = "${format("%s_%s-kafka-status-%s-%02d", var.project, var.platform, element(data.aws_subnet.subnet.*.availability_zone, count.index), (count.index/data.aws_subnet.subnet.count)+1)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  namespace = "AWS/EC2"
  metric_name = "StatusCheckFailed"
  period = "60"
  statistic = "Average"
  threshold = "1"
  dimensions {
    InstanceId = "${element(aws_instance.kafka-server.*.id, count.index)}"
  }
  alarm_actions = ["${var.cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "zookeeper-proc-alarm" {
  count = "${var.cloudwatch_alarm_arn==""?0:aws_instance.zookeeper-server.count}"
  alarm_name = "${format("%s_%s-zk-proc-%02d", var.project, var.platform, count.index+1)}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "1"
  namespace = "CMXAM/Kafka"
  metric_name = "ZookeeperStatus"
  period = "60"
  statistic = "Minimum"
  threshold = "1"
  dimensions {
    InstanceId = "${element(aws_instance.zookeeper-server.*.id, count.index)}"
  }
  alarm_actions = ["${var.cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "kafka-proc-alarm" {
  count = "${var.cloudwatch_alarm_arn==""?0:aws_instance.kafka-server.count}"
  alarm_name = "${format("%s_%s-kafka-proc-%s-%02d", var.project, var.platform, element(data.aws_subnet.subnet.*.availability_zone, count.index), (count.index/data.aws_subnet.subnet.count)+1)}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "1"
  namespace = "CMXAM/Kafka"
  metric_name = "KafkaStatus"
  period = "60"
  statistic = "Minimum"
  threshold = "1"
  dimensions {
    InstanceId = "${element(aws_instance.kafka-server.*.id, count.index)}"
  }
  alarm_actions = ["${var.cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_event_rule" "zookeeper-event-rule" {
  count = "${var.cloudwatch_alarm_arn==""?0:1}"
  name = "${var.project}_${var.platform}-zk-event"
  description = "Zookeeper State Change"
  event_pattern = "${data.template_file.zookeeper-state-change.rendered}"
}

resource "aws_cloudwatch_event_target" "zookeeper-event-target" {
  count = "${var.cloudwatch_alarm_arn==""?0:1}"
  target_id = "zookeeper"
  rule = "${aws_cloudwatch_event_rule.zookeeper-event-rule.name}"
  arn = "${var.cloudwatch_alarm_arn}"
}

resource "aws_cloudwatch_event_rule" "kafka-event-rule" {
  count = "${var.cloudwatch_alarm_arn==""?0:1}"
  name = "${var.project}_${var.platform}-kafka-event"
  description = "Kafka State Change"
  event_pattern = "${data.template_file.kafka-state-change.rendered}"
}

resource "aws_cloudwatch_event_target" "kafka-event-target" {
  count = "${var.cloudwatch_alarm_arn==""?0:1}"
  target_id = "kafka"
  rule = "${aws_cloudwatch_event_rule.kafka-event-rule.name}"
  arn = "${var.cloudwatch_alarm_arn}"
}
