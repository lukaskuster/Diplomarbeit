import requests


class API:
    def __init__(self, username, password, host='https://api.da.digitalsubmarine.com/v1'):
        self.username = username
        self.password = password
        self.host = host

    def get_gateway(self, _id):
        response = requests.get(self.host + '/gateway/' + _id, auth=(self.username, self.password))
        data = response.json()
        return data

    def get_gateways(self):
        response = requests.get(self.host + '/gateways', auth=(self.username, self.password))
        data = response.json()
        return data

    def post_gateway(self, _id):
        response = requests.post(self.host + '/gateway', auth=(self.username, self.password), json={'id': _id})
        data = response.json()
        return data

    def delete_gateway(self, _id):
        response = requests.delete(self.host + '/gateway/' + _id, auth=(self.username, self.password))
        print(response.status_code)
        return True if response.status_code == 200 else False

    def put_gateway(self, _id, signal_strength=None):
        request = {}
        if signal_strength:
            request['signalStrength'] = signal_strength

        response = requests.put(self.host + '/gateway/' + _id, auth=(self.username, self.password), json=request)
        data = response.json()
        return data

    def get_user(self):
        response = requests.get(self.host + '/user', auth=(self.username, self.password))
        data = response.json()
        return data

    def put_user(self, first_name=None, last_name=None, password=None):
        request = {}
        if first_name:
            request['firstName'] = first_name
        if last_name:
            request['lastName'] = last_name
        if password:
            request['password'] = password

        response = requests.put(self.host + '/user', auth=(self.username, self.password), json=request)
        data = response.json()
        return data
