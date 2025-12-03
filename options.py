#!/usr/bin/env python
# -*- coding: utf-8 -*-

from configparser import ConfigParser

NAV_CMDS = ['nav-up', 'nav-down', 'nav-left', 'nav-right', 'nav-confirm', 'nav-back']
ACT_CMDS = ['aX', 'aY', 'A', 'B', 'C', 'D']

DEFAULTS = {
    'joy-nav-map': {
            ('a', 1, -1):0,
            ('a', 1, 1):1,
            ('a', 0, -1):2,
            ('a', 0, 1):3,
            ('b', 0):4,
            ('b', 1):5,
        },
    'key-nav-map': {
            'arrow_up':0,
            'arrow_down':1,
            'arrow_left':2,
            'arrow_right':3,
            'space':4,
            'escape':5,
        },
    'joy-map': {
            ('a', 0) : 0,
            ('a', 1) : 1,
            ('b', 2) : 2,
            ('b' ,1) : 3 ,
            ('b', 3) : 4,
            ('b', 0) : 5,
        },
    #~ 'key-nav-map': {
            #~ ''
        #~ },
        
    'game-opts':{
            'controller': 'Keyboard',
        }
}

class MoonBunnyOptions(ConfigParser):
    def __init__(self):
        ConfigParser.__init__(self)
        try:
            f = open('options.cfg')
            self.read('options.cfg')
        except IOError:
            for (k, v) in DEFAULTS.items():
                self.add_section(k)
                for (k2, v2) in v.items():
                    self.set(k, str(k2), str(v2))
             
            f = open('options.cfg', 'w')
            self.write(f)
            
    def save(self):
        f = open('options.cfg', 'w')
        self.write(f)
