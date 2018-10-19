from socketIO_client_nexus import SocketIO


class AuthenticationError(Exception):
    def __init__(self, message):
        """
        Construct a new 'AuthenticationError' object.

        :param message: error message
        """
        # Call the base class constructor with the parameters it needs
        super().__init__(message)


def get_peer_description(rule, local_description, host, port, username, password):
    """
    Get the description of a client to establish a p2p connection with an other client.

    :param rule: type of the description (offer or answer)
    :param local_description: the local description
    :param host: hostname or ip-address of the server
    :param port: port of the server
    :param username: username for authentication
    :param password: password for authentication
    :type rule: str
    :type local_description: str
    :type host: str
    :type port: int
    :type username: str
    :type password: str
    :return: returns the peer description
    """

    # The remote description that will be returned from the method
    description = ""

    # Define a new socket.io client
    client = SocketIO(host, port)

    def on_authenticated(data):
        """
        Response to authenticate event.

        :param data: object with authenticated and error
        :type data: dict
        :return: nothing
        """

        if not data['authenticated']:
            raise AuthenticationError(data['error'])

    client.on('authenticated', on_authenticated)

    def on_start():
        """
        Event from server to start the description exchange

        :return: nothing
        """

        # Send the offer description
        client.emit('offer', local_description)

    def on_answer(data):
        """
        Event from server that contains the answer description from the peer client.

        :param data: answer description
        :type data: str
        :return: nothing
        """

        # Saves the peer description to the outer description variable.
        nonlocal description
        description = data

        # Disconnect from the server to keep to return the description
        client.disconnect()

    def on_offer(data):
        """
        Event from server that contains the offer description from the peer client.
        Also sends back the answer description.

        :param data: offer description
        :type data: str
        :return: nothing
        """

        # Saves the peer description to the outer description variable
        nonlocal description
        description = data

        # Send the answer description
        client.emit('answer', local_description)

        # Disconnect from the server to keep to return the description
        client.disconnect()

    # Listen to incoming events
    client.on('start', on_start)
    client.on('answer', on_answer)
    client.on('offer', on_offer)

    # Authenticate with the username and password
    # Also the given rule can be sent
    client.emit('authenticate', {'username': username, 'password': password, 'rule': rule})

    # Wait until the socket.io client disconnects from the server
    client.wait()

    # Return the description of the peer client
    return description
