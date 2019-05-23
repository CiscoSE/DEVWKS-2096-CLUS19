#!/usr/bin/env python3

import argparse
import requests
import json
import nxapi.connection

commands = [ 

    ### Create persistent directory storage
    'run bash mkdir -p /bootflash/kubernetes/bin',
    'run bash mkdir -p /bootflash/kubernetes/sbin',
    'run bash mkdir -p /bootflash/kubernetes/etc',
    'run bash mkdir -p /bootflash/kubernetes/lib',

    ### Setup non-persistent runtime environment
    'run bash sudo mkdir -p /root/.kube',
    'run bash sudo mkdir -p /root/bin',
    'run bash sudo mkdir -p /root/etc',

]

if __name__ == '__main__':
    # Command line arguments to flag Docker environment
    parser = argparse.ArgumentParser()

    parser.add_argument('-t', '--target', 
                        help='Provide remote hostname/IP for NXAPI',
                        )

    parser.add_argument('-p', '--port', 
                        help='Provide remote port for NXAPI',
                        )

    parser.add_argument('-s', '--ssl', 
                        help='Connect via SSL for NXAPI',
                        )

    parser.add_argument('-u', '--user', 
                        help='Provide remote username for NXAPI',
                        )

    parser.add_argument('-w', '--password', 
                        help='Provide remote password for NXAPI',
                        )

    parser.add_argument('-v', '--verbose',
                        help='Enable verbose output',
                        action='store_true'
                        )

    args = parser.parse_args()

    # Credentials
    if args.user:
        user = args.user
    else:
        user = 'admin'

    if args.password:
        password = args.password
    else:
        password = 'admin'

    # Running against a remote NX-OS system (not local VM)
    if args.target:
        host = args.target
    else:
        host = 'localhost'

    # Change from the (project historical) default port
    if args.port:
        port = str(args.port)
    else:
        port = '80'

    # Enable SSL for communication (requires valid SSL certificates!)
    if args.ssl:
        protocol = 'https'
    else:
        protocol = 'http'

    # Enable output
    if args.verbose:
        verbose = True
    else:
        verbose = False

    switch = nxapi.connection.nxapi(
                protocol=protocol,
                host=host, port=port,
                user=user, password=password,
                message_format='json-rpc',
                command_type='cli'
                )

    payload = switch.payload()

    for cmd in commands:
        if verbose:
            print(cmd)
        payload.add_command(cmd)

    if verbose:
        print(json.dumps(payload.post_input(), indent=4))

    response = switch.post(payload)

    if not isinstance(response, list):
        print(str(response))
    else:
        for r in response:
            if r['result'] is not None:
                if 'msg' in r['result']:
                    print(r['result']['msg'])

