class ATEvent:
    """
    Event encapsulates an error and a content list.
    """

    def __init__(self, name, error=False):
        """
        Construct a new 'Event' object.

        :param error: error of event
        :type error: bool
        :return: returns nothing
        """

        self.error = error
        self.error_message = None
        self.name = name
        self.content = []
        self.data = None

    def __str__(self):
        """
        Returns the event as a human readable string

        :return: human readable string of the event
        :rtype: str
        """

        return 'Name: {}\nError: {}\nError Message: {}\nData:\n{}'.format(
            self.name, self.error, self.error_message, self.data)
