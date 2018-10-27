import requests
from pyee import EventEmitter
from backend.sse import SSE


class API(EventEmitter):
    """
    Wrapper to send requests to the REST-API.
    """

    def __init__(self, username, password, _id, host='https://api.da.digitalsubmarine.com/v1'):
        super(API, self).__init__()
        self.auth = (username, password)
        self.host = host
        self.id = _id

        # Create an new sse connection, that emits the incoming push notifications on the API object
        self.sse = SSE(self)

    def start(self):
        """
        Start the sse thread.

        :return: nothing
        """

        self.sse.start()

    def close(self):
        """
        Close the sse thread.

        :return: noting
        """

        self.sse.running = False

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

    def _request(self, path, method, body=None):
        """
        Sends a http request to the server with a given http method
        and returns the json body in a dict

        :param path: path of the endpoint
        :param method: http method from requests module
        :param body: json data in form of a dict
        :type path: str
        :type method: request function
        :type body: dict
        :return: body of the response and status code in a tuple
        :returns: dict
        """

        if type(body) is not dict and body is not None:
            raise ValueError('Body has to be of type dict!')

        if body is None:
            response = method(self.host + path, auth=self.auth)
        else:
            response = method(self.host + path, auth=self.auth, json=body)

        data = response.json()
        return data, response.status_code
