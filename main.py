import ftplib
import csv
# from PyBambooHR import PyBambooHR

# FTP server configuration
ip_ftp = ""
username = "anonymous"
password = "anonymous"

# Attempts to authenticate to FTP server
try:
    ftp = ftplib.FTP(ip_ftp)
    ftp.login(username, password)
except:
    print("Error connecting to FTP")
    exit()

def csv_parser(filename):
    with open(filename, 'wb') as file:
        ftp.retrbinary(f'RETR {filename}', file.write)
        reader = csv.reader(file)
        print(reader)
        # for row in reader:
        #     print(', '.join(row))

def lambda_handler(event=None, context=None):
    # Gets list of existing files in FTP serber
    directory = ftp.nlst()

    for i in directory:
        print(i)

    csv_parser('test_data.csv')

    ftp.close()

# Remove before deploying
lambda_handler()

