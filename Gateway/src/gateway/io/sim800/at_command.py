# cython: language_level=3

from gateway.io.sim800 import parser as sim_parser


class ATCommand:
    """
    Represents an AT-Command that gets send to the sim module.
    """

    def __init__(self, command, name='', data=None, parser=sim_parser.Parser()):
        """
        Construct a new 'Command' object.

        :param command: actual at-command
        :param name: name of the event that gets emitted
        :param data: additional data that gets send if prompted
        :type command: str
        :type name: str
        :type data: str
        :return: returns nothing
        """

        self.command = command
        self.name = name
        self.data = data
        self.parser = parser

    def __str__(self):
        """
        Returns the command as a human readable string

        :return: human readable string of the event
        :rtype: str
        """

        return 'Name: {}\nCommand: {}\nData: {}'.format(self.name, self.command, self.data)
