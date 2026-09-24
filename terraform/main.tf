locals {
  thing_name = "fan-monitor-01"
}

# The device's identity in AWS.
resource "aws_iot_thing" "fan_monitor" {
  name = local.thing_name
}

# The device's ID card (certificate) used to prove who it is.
resource "aws_iot_certificate" "fan_monitor" {
  active = true
}

# Rules for what this device is allowed to do.
resource "aws_iot_policy" "fan_monitor" {
  name = "${local.thing_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iot:Connect"]
        Resource = "arn:aws:iot:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:client/${local.thing_name}"
      },
      {
        Effect   = "Allow"
        Action   = ["iot:Publish"]
        Resource = "arn:aws:iot:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:topic/devices/${local.thing_name}/telemetry"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Link the certificate to the rules, and to the device.
resource "aws_iot_policy_attachment" "fan_monitor" {
  policy = aws_iot_policy.fan_monitor.name
  target = aws_iot_certificate.fan_monitor.arn
}

resource "aws_iot_thing_principal_attachment" "fan_monitor" {
  thing     = aws_iot_thing.fan_monitor.name
  principal = aws_iot_certificate.fan_monitor.arn
}

# Save the certificate files locally so the ESP8266 can use them.
resource "local_file" "device_cert" {
  filename        = "${path.module}/certs/device.pem.crt"
  content         = aws_iot_certificate.fan_monitor.certificate_pem
  file_permission = "0600"
}

resource "local_file" "private_key" {
  filename        = "${path.module}/certs/private.pem.key"
  content         = aws_iot_certificate.fan_monitor.private_key
  file_permission = "0600"
}