data "archive_file" "init"{
    type = "zip"
    output_path = "main.zip"

    source {
      content = data.template_file.main.rendered
      filename = "main.py"
    }

    source {
      content = data.template_file.bamboohrpip.rendered
      filename = "bambooManager.py"
    }
}

data "template_file" "main" {
  template = "${file("main.py")}"
}

data "template_file" "bamboohrpip" {
  template = "${file("bambooManager.py")}"
}

data "archive_file" "bamboohr"{
    type = "zip"
    source_dir = "bambooHR"
    output_path = "bambooHR.zip"
}

data "archive_file" "pysftp"{
    type = "zip"
    source_dir = "pysftp"
    output_path = "pysftp.zip"
}


resource "aws_lambda_function" "FTPManager"{
    filename=data.archive_file.init.output_path
    function_name = "FTPManager"
    role=aws_iam_role.lambdaAdminIAM.arn
    handler="main.lambda_handler"
    layers = [aws_lambda_layer_version.pysftpLayer.arn]
    source_code_hash = filebase64sha256(data.archive_file.init.output_path)

    runtime="python3.9"

    environment {
      variables = {
        "TF_VAR_bamboo" = var.bamboo
      }
    }
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

data  "aws_iam_policy" "policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "ftp" {
  name = "/aws/lambda/FTPManager"
}

resource "aws_iam_role_policy_attachment" "cloudtrail_attach" {
  role       = aws_iam_role.lambdaAdminIAM.name
  policy_arn = data.aws_iam_policy.policy.arn
}

resource "aws_cloudwatch_event_rule" "hourlyCheck" {
    name = "hourlyFTPCheck"
    description = "Does an hourly check to a given FTP server"
    schedule_expression = "rate(1 hour)"
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

resource "aws_lambda_layer_version" "pysftpLayer" {
  filename   = data.archive_file.pysftp.output_path
  layer_name = "pysftpLayer"
  source_code_hash = filebase64sha256(data.archive_file.pysftp.output_path)
  compatible_runtimes = ["python3.9"]
}