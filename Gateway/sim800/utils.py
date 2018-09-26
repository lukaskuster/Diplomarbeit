import re


def clear_str(string):
    """
    Function that returns the string without carriage return and new line character

    :param string: String that should be processed
    :return: String without \n and \r characters
    """

    return re.sub('([\n\r])', '', string)
