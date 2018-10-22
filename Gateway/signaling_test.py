import argparse
from backend import get_peer_description


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-r", "--rule", help="Rule [ Answer | Offer ]")
    parser.add_argument("-d", "--description", help="ICE Description")
    parser.add_argument("-o", "--host", help="Hostname/IP from Server")
    parser.add_argument("-p", "--port", help="Port from Server")

    # Parse commandline arguments
    args = parser.parse_args()

    # Set default values if the arguments are not set
    if not args.description:
        args.description = "Test Description"
    if not args.host:
        args.host = "https://signaling.da.digitalsubmarine.com"
    if not args.port:
        args.port = 443

    # Get the description of an other connected client
    if args.rule == 'answer':
        desc = get_peer_description('answer', args.description, args.host, args.port, 'quentin@wendegass.com', 'test123')

    else:
        desc = get_peer_description('offer', args.description,  args.host, args.port, 'quentin@wendegass.com', 'test123')

    # Print out the description of the other client
    print("Remote description:", desc)
