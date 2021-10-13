data "archive_file" "init"{
    type="zip"
    source_file="main.py"
    output_path = "main.zip"
}

resource "aws_lambda_function" "FTPManager"{
    filename=data.archive_file.init.output_path
    function_name = "FTPManager"
    role=aws_iam_role.lambdaAdminIAM.arn
    handler="main.lambda_handler"

    source_code_hash = filebase64sha256(data.archive_file.init.output_path)

    runtime="python3.9"
}

resource "aws_iam_role" "lambdaAdminIAM" {
  name = "ftpManager"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "poc-ftp"
  }
}

resource "aws_cloudwatch_event_rule" "hourlyCheck" {
    name = "hourlyFTPCheck"
    description = "Does an hourly check to a given FTP server"
    schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "targetResource" {
    rule = aws_cloudwatch_event_rule.hourlyCheck.name
    arn = aws_lambda_function.FTPManager.arn
}

resource "aws_lambda_permission" "cloudwatch_permission" {
    statement_id = "AllowCloudWatchTrigger"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.FTPManager.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.hourlyCheck.arn
}