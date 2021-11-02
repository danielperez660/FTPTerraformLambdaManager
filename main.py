import csv
import os
from bambooManager import create_user
import paramiko
import boto3

try:
    s3_client = boto3.client('s3')
    s3_client.download_file("sfpt-key-storage", "ssh-key.pem", "/tmp/ssh-key.pem")
except Exception as e:
    print("Error getting SSH key:", e)
    exit()

try:
    s3_resources = boto3.resource('s3')
    csv_bucket = s3_resources.Bucket('sftp-csv-storage')
    csv_list = [i.key for i in csv_bucket.objects.all()]
except Exception as e:
    print("Error getting csv storage bucket:", e)
    exit()

try:
    key = paramiko.rsakey.RSAKey(filename='/tmp/ssh-key.pem')
except Exception as e:
    print("Error reading SSH key:", e)
    exit()

host,port = "sftp.eploy.net", 22
ssh = paramiko.SSHClient()

# Attempts to authenticate to FTP server
try:
    ssh.load_system_host_keys()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    ssh.connect('sftp.eploy.net', username='HippoDigital', pkey=key, port=port)
    ftp = ssh.open_sftp()
except Exception as e:
    print("Error connecting to SFTP:", e)
    exit()

def csv_parser(filename):
    print("Parsing:", filename)

    ftp.get(str(filename), str(f'/tmp/{filename}'))

    csv_bucket.upload_file(f'/tmp/{filename}', filename)

    with open('/tmp/' + filename, newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')

        header = []
        header = next(reader)

        for row in reader:
            print(', '.join(row))

    os.remove('/tmp/' + filename)

def lambda_handler(event=None, context=None):
    # Gets list of existing files in FTP server
    try:
        ftp.chdir('PayrollExport')
    except FileNotFoundError as e:
        print("Already in PayrollExport:", e)

    directory = ftp.listdir(path='.')
    
    for i in directory:
        print("ITEM:", i)
        i = i.strip()

        if i not in csv_list:
            csv_parser(i)
        else:
            print(f"{i} has already been processed")


