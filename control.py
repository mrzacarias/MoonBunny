#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys

if __name__=='__main__':
    import direct.directbase.DirectStart

from direct.task import Task
from direct.actor import Actor
from pandac.PandaModules import *
from direct.showbase import DirectObject

import pygame
from pygame.locals import *

NAV_CMDS = ['nav-up', 'nav-down', 'nav-left', 'nav-right', 'nav-confirm', 'nav-back']
DEFAULT_NAV_KEY_MAP = {
    'arrow_up':0,
    'arrow_down':1,
    'arrow_left':2,
    'arrow_right':3,
    'space':4,
    'escape':5,
}

DEFAULT_NAV_JOY_MAP = {
    ('a', 1, -1):0,
    ('a', 1, 1) :1,
    ('a', 0, -1):2,
    ('a', 0, 1) :3,
    ('b', 0)    :4,
    ('b', 1)    :5,
}

    
#classe para tratamento de joystick
class JoyNavMapper:
    def __init__(self, joystick, map=DEFAULT_NAV_JOY_MAP):
        self.map = map
        self.joy = joystick
        
        self.valid_buttons = [t[1] for t in map.keys() if t[0]=='b']
        self.valid_axes = [t[1] for t in map.keys() if t[0]=='a']
        
        self.buttons_pressed = {}
        for b in self.valid_buttons:
            self.buttons_pressed[b] = False
        
        self.axis_pressed = {}
        for a in self.valid_axes:
            self.axis_pressed[(a, 1)] = False
            self.axis_pressed[(a, -1)] = False
        
    def activate(self):
        taskMgr.add(self.ctask_CheckEvents, 'check-joy-events')
        
    def deactivate(self):
        taskMgr.remove(self.ctask_CheckEvents)
        
    def ctask_CheckEvents(self, task):
        return Task.cont
    
#classe para tratamento de Keyboard
class KeyNavMapper(DirectObject.DirectObject):
    def __init__(self, map=DEFAULT_NAV_KEY_MAP):
        DirectObject.DirectObject.__init__(self)
        
        for k, v in map.items():
            self.accept(k, messenger.send, [NAV_CMDS[v]])

if __name__=='__main__':
    class EvtPrinter(DirectObject.DirectObject):
        def __init__(self):
            DirectObject.DirectObject.__init__(self)
            
            for cmd in NAV_CMDS:
                self.accept(cmd, sys.stdout.write, [cmd])

    KeyNavMapper()
    EvtPrinter()
    run()
