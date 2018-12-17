# cython: language_level=3

import re


def clear_str(string):
    """
    Removes carriage return and new line character from the string.

    :param string: string that should be processed
    :type string: str
    :return: String without \n and \r characters
    :rtype: str
    """

    return re.sub('([\n\r])', '', string)


regex = re.compile(r"\\.|[\"',]", re.DOTALL)


def split_str(string):
    """
    Splits the passed str after semicolon and ignores it in double quotes.

    :param string: string that should be split
    :return: array of strings
    """

    delimiter = ''
    compos = [-1]
    for match in regex.finditer(string):
        g = match.group(0)
        if delimiter == '':
            if g == ',':
                compos.append(match.start())
            elif g in "\"'":
                delimiter = g
        elif g == delimiter:
            delimiter = ''
    # uncomment the next line to catch errors
    # if delimiter: raise ValueError("Unterminated string in data")
    compos.append(len(string))
    return [string[compos[i] + 1:compos[i + 1]] for i in range(len(compos) - 1)]
