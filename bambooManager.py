from PyBambooHR.PyBambooHR import PyBambooHR

try:
    bamboo = PyBambooHR(subdomain='hippodigital', api_key='yourapikeyhere')
    print(bamboo.get_employee_directory())
except Exception as e :
    print("Error connecting to Bamboo HR:", e)
    exit()