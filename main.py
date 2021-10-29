import csv
import os
from bambooManager import create_user
import paramiko

key = paramiko.rsakey.RSAKey(filename='ssh-key.pem')
host,port = "sftp.eploy.net ",22
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
    with open(filename, newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')

        header = []
        header = next(reader)

        for row in reader:
            create_user(row)


    # with open('/tmp/' + filename, 'wb') as file:
    #     ftp.retrbinary('RETR ' + filename, file.write)

    # with open('/tmp/' + filename, newline='') as csvfile:
        # reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        # header = []
        # header = next(reader)
    #     for row in reader:
    #         print(', '.join(row))

    # os.remove('/tmp/' + filename)

def lambda_handler(event=None, context=None):
    # Gets list of existing files in FTP serber
    directory = ftp.listdir(path='.')

    for i in directory:
        print(i)

    # ftp.cwd('files')
    # csv_parser('test_data.csv')


lambda_handler()

# csv_parser('test_data.csv')