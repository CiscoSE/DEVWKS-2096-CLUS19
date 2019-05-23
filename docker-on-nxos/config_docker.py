#!/usr/bin/env python3

import argparse
import requests
import json
import nxapi.connection

commands = [ 

    ### Prep for scripted configuration
    'terminal dont-ask',

    ### Protect against switch reload
    'configure terminal',
    'boot nxos bootflash:nxos.9.2.1.bin',

    ### Out with the old
    'guestshell destroy',

    ### Setup DNS correctly
    'vrf context management',
    'ip domain-name clus19.internal',
    'ip name-server 208.67.222.222',

    ### Initialize the Docker environment
    'run bash sudo service docker start',
    'run bash sudo chkconfig --add docker',
    'run bash sudo service docker stop',

    ### Give your Docker space
    'run bash sudo truncate -s +1000MB /bootflash/dockerpart',
    'run bash sudo e2fsck -f /bootflash/dockerpart',
    'run bash sudo /sbin/resize2fs /bootflash/dockerpart',
    'run bash sudo e2fsck -f /bootflash/dockerpart',

    ### Secure your Docker
    'run bash sudo groupadd dockremap -r',
    'run bash sudo useradd dockremap -r -g dockremap',
    'run bash sudo bash -c \'echo "dockremap:123000:65536" >> /etc/subuid\'',
    'run bash sudo bash -c \'echo "dockremap:123000:65536" >> /etc/subgid\'',
    'run bash sudo perl -pi -e \'s,^other_args=.*,other_args="--debug=true --cgroup-parent=/ext_ser/",g\' /etc/sysconfig/docker',

    ### Bring Docker back up for production
    'run bash sudo service docker start',

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
            # Print output from successful commands
            if 'result' in r:
                if r['result'] is not None:
                    if 'msg' in r['result']:
                        print(r['result']['msg'])
            # Print error output
            elif 'error' in r:
                if r['error'] is not None:
                    if 'message' in r['error']:
                        print(r['error']['message'])
                    if 'data' in r['error']:
                        if 'msg' in r['error']['data']:
                            print(r['error']['data']['msg'])
            # Print generic output in failure
            else:
                print(r)
