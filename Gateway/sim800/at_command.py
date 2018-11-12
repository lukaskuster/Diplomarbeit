class ATCommand:
    """
    Represents an AT-Command that gets send to the sim module.
    """

    def __init__(self, command, name='', callback=None, data=None):
        """
        Construct a new 'Command' object.

        :param command: actual at-command
        :param name: name of the event that gets emitted
        :param callback: callback that gets emitted with the response event
        :param data: additional data that gets send if prompted
        :type command: str
        :type name: str
        :type data: str
        :return: returns nothing
        """

        self.command = command
        self.name = name
        self.callback = callback
        self.data = data

    def __str__(self):
        """
        Returns the command as a human readable string

        :return: human readable string of the event
        :rtype: str
        """

        return 'Name: {}\nCommand: {}\nData: {}'.format(self.name, self.command, self.data)
