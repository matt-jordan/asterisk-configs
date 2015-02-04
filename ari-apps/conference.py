#!/usr/bin/env python

import ari
import logging

logging.basicConfig(level=logging.ERROR)

conference = None

client = ari.connect('http://localhost:8088', 'asterisk', 'asterisk')

def stasis_end_cb(channel, ev):
    """StasisEnd event callback

    Called when a channel leaves the app
    Keyword Arguments:
    channel -- The channel that left
    ev      -- The actual event
    """
    print("Channel '{0}' left the conference".format(channel.json.get('name')))


def channel_left_bridge_cb(bridge, ev):
    """ChannelLeftBridge event callback

    Called when a channel leaves a bridge
    Keyword Arguments:
    bridge -- The bridge the channel left
    ev     -- The actual event
    """
    global conference
    if conference.id != bridge.id:
        return

    channels = bridge.get('channels')
    if len(channels) == 0:
        bridge.destroy()
        conference = None


def stasis_start_cb(channel_obj, ev):
    """StasisStart event callback

    Called when a channel enters into the application

    Keyword Arguments:
    channel_obj -- Wrapper around the channel
    ev          -- The actual event
    """

    global conference
    if not conference:
        conference = client.bridges.create(type='mixing')
        conference.on_event('ChannelLeftBridge', channel_left_bridge_cb)

    channel = channel_obj.get('channel')
    channel.answer()
    print("Channel '{0}' entered the conference".format(channel.json.get('name')))
    conference.play(media='sound:beep')


client.on_channel_event('StasisStart', stasis_start_cb)
client.on_channel_event('StasisEnd', stasis_end_cb)

client.run(apps='conference')

