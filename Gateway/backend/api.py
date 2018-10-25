import requests


class API:
    """
    Wrapper to send requests to the REST-API.
    """

    def __init__(self, username, password, host='https://api.da.digitalsubmarine.com/v1'):
        self.auth = (username, password)
        self.host = host

    def get_gateway(self, _id):
        return self._request('/gateway/' + _id, requests.get)

    def get_gateways(self):
        return self._request('/gateways', requests.get)

    def post_gateway(self, _id):
        return self._request('/gateway', requests.post, {'id': _id})

    def delete_gateway(self, _id):
        return self._request('/gateway/' + _id, requests.delete)

    def put_gateway(self, _id, signal_strength=None):
        body = {}
        if signal_strength:
            body['signalStrength'] = signal_strength

        return self._request('/gateway/' + _id, requests.put, body)

    def get_user(self):
        return self._request('/user', requests.get)

    def put_user(self, first_name=None, last_name=None, password=None):
        body = {}
        if first_name:
            body['firstName'] = first_name
        if last_name:
            body['lastName'] = last_name
        if password:
            body['password'] = password

        return self._request('/user', requests.put, body)

    def _request(self, url, method, body=None):
        if type(body) is not dict and body is not None:
            raise ValueError('Body has to be of type dict!')

        if body is None:
            response = method(self.host + url, auth=self.auth)
        else:
            response = method(self.host + url, auth=self.auth, json=body)

        data = response.json()
        return data, response.status_code
