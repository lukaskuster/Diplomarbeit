import re


def clear_str(string):
    """
    Function that returns the string without carriage return and new line character

    :param string: String that should be processed
    :type string: str
    :return: String without \n and \r characters
    :rtype: str
    """

    return re.sub('([\n\r])', '', string)
