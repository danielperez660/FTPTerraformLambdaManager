import requests
import json
import os
import datetime

api_key = "e579f2a207c3e1c0ff93ced03e36be8f3453ad8d"
api_key_hippo = os.environ["TF_VAR_bamboo"]

def api_caller(endpoint, data):
    if endpoint == "employees":
        url = "https://api.bamboohr.com/api/gateway.php/testdomain123/v1/employees/"
        # url = "https://api.bamboohr.com/api/gateway.php/hippodigital/v1/employees/"

        headers = {"Content-Type": "application/json"}

        res = requests.post(url=url, data=data, headers=headers, auth=(api_key, ''))
        print(res.headers)


def create_user(user_object):
    if user_object[14]:
        employee = {
            "firstName" : user_object[2],
            "lastName" : user_object[4],
            "status" : user_object[0],
            "nickname" : user_object[3],
            "mobilePhone" : user_object[5],
            "homeEmail" : user_object[6],
            "hireDate" : str(datetime.datetime.strptime(user_object[7], "%d/%m/%Y").date()),
            "jobTitle" : user_object[8],
            "division" : user_object[9],
            "location" : user_object[10],
            "payRate" : user_object[11],
            "payType" : user_object[12],
            "paidPer" : user_object[13],
            "terminationDate" : str(datetime.datetime.strptime(user_object[14], "%d/%m/%Y").date()),
            "level" : user_object[15],
            "referredBy" : user_object[16],
            "methodOfHire" : user_object[17],
            "nameOfAgency" : user_object[18]
        }
    else:
        employee = {
            "firstName" : user_object[2],
            "lastName" : user_object[4],
            "status" : user_object[0],
            "nickname" : user_object[3],
            "mobilePhone" : user_object[5],
            "homeEmail" : user_object[6],
            "hireDate" : str(datetime.datetime.strptime(user_object[7], "%d/%m/%Y").date()),
            "jobTitle" : user_object[8],
            "division" : user_object[9],
            "location" : user_object[10],
            "payRate" : user_object[11],
            "payType" : user_object[12],
            "paidPer" : user_object[13],
            "level" : user_object[15],
            "referredBy" : user_object[16],
            "methodOfHire" : user_object[17],
            "nameOfAgency" : user_object[18]
        }

    # try:
    api_caller('employees', json.dumps(employee))
    # except Exception as e:
        # print("Error creating employee:", e)