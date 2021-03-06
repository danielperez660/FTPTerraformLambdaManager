data "archive_file" "init"{
    type = "zip"
    output_path = "main.zip"

    source {
      content = data.template_file.main.rendered
      filename = "main.py"
    }

    source {
      content = data.template_file.bamboohr.rendered
      filename = "bambooManager.py"
    }
}

data "template_file" "main" {
  template = "${file("main.py")}"
}

data "template_file" "bamboohr" {
  template = "${file("bambooManager.py")}"
}

data "archive_file" "pysftp"{
    type = "zip"
    source_dir = "pysftp"
    output_path = "pysftp.zip"
}

data "archive_file" "requests"{
    type = "zip"
    source_dir = "requests"
    output_path = "requests.zip"
}

data "archive_file" "boto3"{
    type = "zip"
    source_dir = "boto3"
    output_path = "boto3.zip"
}


resource "aws_lambda_function" "FTPManager"{
    filename=data.archive_file.init.output_path
    function_name = "FTPManager"
    role=aws_iam_role.lambdaAdminIAM.arn
    handler="main.lambda_handler"
    layers = [aws_lambda_layer_version.pysftpLayer.arn, aws_lambda_layer_version.requestsLayer.arn, 
    aws_lambda_layer_version.boto3Layer.arn]
    source_code_hash = filebase64sha256(data.archive_file.init.output_path)
    architectures = ["x86_64"]

    runtime="python3.9"
    timeout = 60

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

resource "aws_iam_role_policy_attachment" "cloudtrail_attach" {
  role       = aws_iam_role.lambdaAdminIAM.name
  policy_arn = data.aws_iam_policy.policy.arn
}

resource "aws_iam_policy" "key_policy"{
  name = "key_reader"
  description = "Read the SSH key from S3 for SFTP access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::sfpt-key-storage/*"
      },
    ]
  })
}

resource "aws_iam_policy" "s3_write_policy"{
  name = "csv_writer"
  description = "Write the new CSV file to an S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Put*",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::sftp-csv-storage/*",
          "arn:aws:s3:::sftp-csv-storage",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "keypolicy_attach" {
  role       = aws_iam_role.lambdaAdminIAM.name
  policy_arn = aws_iam_policy.key_policy.arn
}

resource "aws_iam_role_policy_attachment" "s3writepolicy_attach" {
  role       = aws_iam_role.lambdaAdminIAM.name
  policy_arn = aws_iam_policy.s3_write_policy.arn
}

resource "aws_cloudwatch_log_group" "ftp" {
  name = "/aws/lambda/FTPManager"
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

resource "aws_lambda_layer_version" "requestsLayer" {
  filename   = data.archive_file.requests.output_path
  layer_name = "requestsLayer"
  source_code_hash = filebase64sha256(data.archive_file.requests.output_path)
  compatible_runtimes = ["python3.9"]
}

resource "aws_lambda_layer_version" "boto3Layer" {
  filename   = data.archive_file.boto3.output_path
  layer_name = "boto3Layer"
  source_code_hash = filebase64sha256(data.archive_file.boto3.output_path)
  compatible_runtimes = ["python3.9"]
}

resource "aws_s3_bucket" "csv_storage" {
  bucket = "sftp-csv-storage"
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "public_access_manager" {
  bucket = aws_s3_bucket.csv_storage.id

  # block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}