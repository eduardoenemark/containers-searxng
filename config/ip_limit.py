# SPDX-License-Identifier: AGPL-3.0-or-later
""".. _botdetection.ip_limit:

Method ``ip_limit``
-------------------

The ``ip_limit`` method counts request from an IP in *sliding windows*.  If
there are to many requests in a sliding window, the request is evaluated as a
bot request.  This method requires a valkey DB and needs a HTTP X-Forwarded-For_
header.  To take privacy only the hash value of an IP is stored in the valkey DB
and at least for a maximum of 10 minutes.

The :py:obj:`.link_token` method can be used to investigate whether a request is
*suspicious*.  To activate the :py:obj:`.link_token` method in the
:py:obj:`.ip_limit` method add the following configuration:

.. code:: toml

   [botdetection.ip_limit]
   link_token = true

If the :py:obj:`.link_token` method is activated and a request is *suspicious*
the request rates are reduced:

- :py:obj:`BURST_MAX` -> :py:obj:`BURST_MAX_SUSPICIOUS`
- :py:obj:`LONG_MAX` -> :py:obj:`LONG_MAX_SUSPICIOUS`

To intercept bots that get their IPs from a range of IPs, there is a
:py:obj:`SUSPICIOUS_IP_WINDOW`.  In this window the suspicious IPs are stored
for a longer time.  IPs stored in this sliding window have a maximum of
:py:obj:`SUSPICIOUS_IP_MAX` accesses before they are blocked.  As soon as the IP
makes a request that is not suspicious, the sliding window for this IP is
dropped.

.. _X-Forwarded-For:
   https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For

"""

from ipaddress import (
    IPv4Network,
    IPv6Network
)

import flask
import werkzeug
import os

from searx.valkeylib import incr_sliding_window, drop_counter

from . import link_token
from . import config
from . import valkeydb
from ._helpers import (
    too_many_requests,
    logger
)


logger = logger.getChild('ip_limit')

"""Time (sec) before sliding window for *burst* requests expires."""
BURST_WINDOW = int(os.getenv('SEARXNG_BURST_WINDOW', 20))

"""Maximum requests from one IP in the :py:obj:`BURST_WINDOW`"""
BURST_MAX = int(os.getenv('SEARXNG_BURST_MAX', 20))

"""Maximum of suspicious requests from one IP in the :py:obj:`BURST_WINDOW`"""
BURST_MAX_SUSPICIOUS = int(os.getenv('SEARXNG_BURST_MAX_SUSPICIOUS', 5))

"""Time (sec) before the longer sliding window expires."""
LONG_WINDOW = int(os.getenv('SEARXNG_LONG_WINDOW', 60))

"""Maximum requests from one IP in the :py:obj:`LONG_WINDOW`"""
LONG_MAX = int(os.getenv('SEARXNG_LONG_MAX', 30))

"""Maximum suspicious requests from one IP in the :py:obj:`LONG_WINDOW`"""
LONG_MAX_SUSPICIOUS = int(os.getenv('SEARXNG_LONG_MAX_SUSPICIOUS', 15))

"""Time (sec) before sliding window for one suspicious IP expires."""
SUSPICIOUS_IP_WINDOW = int(os.getenv('SEARXNG_SUSPICIOUS_IP_WINDOW', 60))

"""Maximum requests from one suspicious IP in the :py:obj:`SUSPICIOUS_IP_WINDOW`."""
SUSPICIOUS_IP_MAX = int(os.getenv('SEARXNG_SUSPICIOUS_IP_MAX', 3))

"""Enable link token for bot detection."""
LINK_TOKEN = os.getenv('SEARXNG_LINK_TOKEN', 'true').lower() == 'true'

"""Filter link-local networks."""
FILTER_LINK_LOCAL = os.getenv('SEARXNG_FILTER_LINK_LOCAL', 'false').lower() == 'true'


def _key(window: str, network: IPv4Network | IPv6Network) -> str:
    """Construct a valkey counter key for a rate-limit window."""
    return f'ip_limit.{window}' + network.compressed


def _check_window(
    valkey_client,
    network: IPv4Network | IPv6Network,
    window: str,
    duration: int,
    limit: int,
    label: str) -> werkzeug.Response | None:
    """Increment a sliding-window counter and block if limit exceeded."""
    c = incr_sliding_window(valkey_client, _key(window, network), duration)
    if c > limit:
        return too_many_requests(network, f"too many request in {label}")


def filter_request(
    network: IPv4Network | IPv6Network,
    request: flask.Request,
    cfg: config.Config) -> werkzeug.Response | None:

    valkey_client = valkeydb.get_valkey_client()

    if network.is_link_local and not FILTER_LINK_LOCAL:
        logger.debug("network %s is link-local -> not monitored by ip_limit method", network.compressed)
        return None

    if LINK_TOKEN:
        suspicious = link_token.is_suspicious(network, request, True)

        if not suspicious:
            drop_counter(valkey_client, _key('SUSPICIOUS_IP_WINDOW', network))
            return None

        # Block persistent suspicious IPs with a redirect
        c = incr_sliding_window(valkey_client, _key('SUSPICIOUS_IP_WINDOW', network), SUSPICIOUS_IP_WINDOW)
        if c > SUSPICIOUS_IP_MAX:
            logger.error("BLOCK: too many request from %s in SUSPICIOUS_IP_WINDOW (redirect to /)", network)
            response = flask.redirect(flask.url_for('index'), code=302)
            response.headers["Cache-Control"] = "no-store, max-age=0"
            return response

        # Suspicious IPs get tighter limits
        if response := _check_window(valkey_client, network, 'BURST_WINDOW', BURST_WINDOW, BURST_MAX_SUSPICIOUS, 'BURST_WINDOW (BURST_MAX_SUSPICIOUS)'):
            return response
        if response := _check_window(valkey_client, network, 'LONG_WINDOW', LONG_WINDOW, LONG_MAX_SUSPICIOUS, 'LONG_WINDOW (LONG_MAX_SUSPICIOUS)'):
            return response

        return None

    # Vanilla rate limiting
    if response := _check_window(valkey_client, network, 'BURST_WINDOW', BURST_WINDOW, BURST_MAX, 'BURST_WINDOW (BURST_MAX)'):
        return response
    if response := _check_window(valkey_client, network, 'LONG_WINDOW', LONG_WINDOW, LONG_MAX, 'LONG_WINDOW (LONG_MAX)'):
        return response

    return None
