from backend import API

if __name__ == '__main__':
    api = API('quentin@wendegass.com', 'test123')
    print(api.put_user('Quentin', 'Wendegass'))
    print(api.get_user())
    print(api.post_gateway('test1231231'))
    print(api.put_gateway('test1231231', 4423))
    print(api.get_gateway('test1231231'))
    print(api.delete_gateway('test1231231'))
    print(api.get_gateways())
