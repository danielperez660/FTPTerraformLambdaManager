import ftplib
import csv
import os
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
        ftp.retrbinary('RETR ' + filename, file.write)

    with open(filename, newline='') as csvfile:
        spamreader = csv.reader(csvfile, delimiter=' ', quotechar='|')
        for row in spamreader:
            print(', '.join(row))

    os.remove(filename)

def lambda_handler(event=None, context=None):
    # Gets list of existing files in FTP serber
    directory = ftp.nlst()

    ftp.cwd('files')
    csv_parser('test_data.csv')

    ftp.close()

# Remove before deploying
lambda_handler()

