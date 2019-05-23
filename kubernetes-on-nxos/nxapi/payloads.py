#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Copyright (c) 2018 Cisco and/or its affiliates.

This software is licensed to you under the terms of the Cisco Sample
Code License, Version 1.0 (the "License"). You may obtain a copy of the
License at

               https://developer.cisco.com/docs/licenses

All use of the material herein must be in accordance with the terms of
the License. All rights not expressly granted by the License are
reserved. Unless required by applicable law or agreed to separately in
writing, software distributed under the License is distributed on an "AS
IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
or implied.

"""

# http://python-future.org/quickstart.html
from __future__ import absolute_import, division, print_function

__author__ = "Timothy E Miller, PhD <timmil@cisco.com>"
__contributors__ = [
]
__copyright__ = "Copyright (c) 2018 Cisco and/or its affiliates."
__license__ = "Cisco Sample Code License, Version 1.1"

import copy

# Declare list of supported messaging types and command types
supported_messages = {
    'json-rpc': ['2.0'],
    'json': ['1.0'],
    }

supported_command_types = {
    'json-rpc': ['cli', 'cli_ascii'],
    'json': ['cli_show', 'cli_conf', 'bash'],
    }

supported_headers = {
    'post': {
        'json-rpc': {'content-type': 'application/json-rpc'},
        'json': {'content-type': 'application/json'},
    },
}


class invalidType(Exception):
    """
    Generic exception to throw when an invalid message or command type is used.
    """
    pass


class Payload:
    """
    Parent class for the support message formats for NX-API
    """

    def __init__(self, messages=None, version=None, method=None):
        self._messages = None
        self._version = None
        self._method = None
        self._commands = []

        self._set_format(messages=messages, version=version)
        self._set_method(method=method)

    def _get_template(self):
        return {}

    def _customize_template(self, template=None, id=None, input=None):
        return ""

    def _set_format(self, messages=None, version=None):
        if messages not in supported_messages:
            raise invalidType(
                "Unsupported message format {0}".format(messages)
            )

        if version not in supported_messages[messages]:
            raise invalidType(
                "Unsupported message format version {0}".format(version)
            )

        self._messages = messages
        self._version = version

    def _set_method(self, method=None):
        if method not in supported_command_types[self._messages]:
            message = "Unsupported command type {0} for {1}"
            message = message.format(method, self._messages)
            raise invalidType(message)

        self._method = method

    def add_command(self, command=None):
        if not command:
            return
        if type(command) is list:
            self._commands = self._commands + command
        else:        
            self._commands.append(command)

    def post_input(self):
        template = self._get_template()
        id = 0
        commands = []

        for cmd in self._commands:
            id = id + 1

            template = self._customize_template(
                                template=template,
                                id=id,
                                input=cmd
                            )

            commands.append(copy.deepcopy(template))

        return commands

    def post_header(self):
        return supported_headers['post'][self._messages]


class json(Payload):
    """
    Class for the JSON message format used for posting CLI commands to
    the NX-API interface on NX-OS based switches.
    """

    def __init__(self, method=None, cmd=None):
        super().__init__(messages='json', version='1.0', method=method)
        self.add_command(command=cmd)

    def _get_template(self):
        """
        Template Generator - must set the following attributes:
           x['ins_api']['sid']   - ID sequence number
           x['ins_api']['input'] - command input to send
        """

        return {
            "ins_api": {
                "version": str(self._version),
                "type": str(self._method),
                "chunk": "0",
                "sid": None,
                "input": None,
                "output_format": "json"
            }
        }

    def post_input(self):
        template = self._get_template()
        id = 1

        commands = " ; ".join(self._commands)
        
        template = self._customize_template(
                            template=template,
                            id=id,
                            input=commands
                        )

        return template

    def _customize_template(self, template=None, id=None, input=None):
        template['ins_api']['sid'] = str(id)
        template['ins_api']['input'] = input
        return template


class json_rpc(Payload):
    """
    Class for the JSON-RPC 2.0 standard for Remote Procedure Calls that
    are encoded within JSON formatting.

    JSON-RPC Standard - http://www.jsonrpc.org/specification
    Server implementation - https://github.com/pavlov99/json-rpc
    """

    def __init__(self, method=None, cmd=None):
        super().__init__(messages='json-rpc', version='2.0', method=method)
        self.add_command(command=cmd)

    def _get_template(self):
        """
        Template generator - must set the following attributes:
           x['id']            - ID sequence number
           x['params']['cmd'] - command input to send
        """

        return {
            'jsonrpc': self._version,
            'method': self._method,
            'params': {
                'cmd': None,
                'version': 1,
            },
            'id': None,
        }

    def _customize_template(self, template=None, id=None, input=None):
        template['id'] = id
        template['params']['cmd'] = input
        return template

