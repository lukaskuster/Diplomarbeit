import json
from aiortc.contrib.signaling import object_from_string, object_to_string


async def authenticate(socket, rule):
    request = {
        'event': 'authenticate',
        'username': 'quentin@wendegass.com',
        'password': 'test123',
        'rule': rule
    }
    await socket.send(json.dumps(request))

    data = await socket.recv()
    response = json.loads(data)

    if 'event' not in response or 'authenticated' not in response:
        raise KeyError()

    if response['event'] != 'authenticate':
        raise ValueError

    return True if response['authenticated'] else False


async def recv_answer(socket):
    data = await socket.recv()
    response = json.loads(data)

    if 'event' not in response or 'message' not in response:
        raise KeyError()

    if response['event'] != 'answer':
        raise ValueError()

    return object_from_string(response['message'])


async def recv_offer(socket):
    data = await socket.recv()
    response = json.loads(data)

    if 'event' not in response or 'message' not in response:
        raise KeyError()

    if response['event'] != 'offer':
        raise ValueError()

    return object_from_string(response['message'])


async def send_answer(socket, desc):
    request = {
        'event': 'answer',
        'message': object_to_string(desc)
    }
    await socket.send(json.dumps(request))


async def send_offer(socket, desc):
    data = await socket.recv()
    response = json.loads(data)

    if 'event' not in response:
        raise KeyError()

    if response['event'] != 'start':
        raise ValueError()

    request = {
        'event': 'offer',
        'message': object_to_string(desc)
    }
    await socket.send(json.dumps(request))
