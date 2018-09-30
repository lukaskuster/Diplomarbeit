class Event:
    """
    Event encapsulates an error and a content list.
    """
    def __init__(self, name, error=False):
        """
        Construct a new 'Event' object.

        :param name: name of the event
        :param error: error of event
        :type name: str
        :type error: bool
        :return: returns nothing
        """
        self.error = error
        self.error_message = None
        self.name = name
        self.content = []

    def __str__(self):
        """
        Returns the event as a human readable string

        :return: human readable string of the event
        :rtype: str
        """

        content = '\n'.join(self.content)
        return 'Name: {}\nError: {}\nError Message: {}\nContent:\n{}'.format(
            self.name, self.error, self.error_message, content)
