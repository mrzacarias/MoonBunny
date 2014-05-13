#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os

keywords = ["MUSIC_FILE", "TITLE", "BPM", "DIFFICULTIES", "ARTIST"]

class InvalidKeyword(Exception):
    pass

LEVEL_DIR = "./levels"

def level_list():
    for f in os.listdir(LEVEL_DIR): f
    
    level_list = [f for f in os.listdir(LEVEL_DIR) if os.path.isdir(os.path.join(LEVEL_DIR, f)) and os.path.exists(os.path.join(LEVEL_DIR, f, 'header.lvl'))]
    return level_list

def level_header(name):
    level_file = open(os.path.join(LEVEL_DIR, name, 'header.lvl'))
    try:
        level_info = {}
        for i, line in enumerate(level_file):
            key, value = line.split("=")
            
            value = value.strip()
            
            if key not in keywords: 
                raise InvalidKeyword("Invalid keyword '%s' found when parsing level %s at line %d" % (key, name, i))
            if key == "BPM":
                try:
                    value = float(value)
                except ValueError:
                    raise ValueError("Error parsing line %d from file '%s': could not convert (%s) to float" % (i, level_file, value))
            if key == "MUSIC_FILE":
                value = os.path.join(LEVEL_DIR, name, value)            
            
            level_info[key]=value
        
        level_info["NAME"] = os.path.split(name)[1]
        
        return level_info
    
    finally:
        level_file.close()


def level_rings(levelname, diff):
    ring_list = []
    time_ant = 0.0
    ring_file = "%s.rng" % (diff)
    
    level_file = open(os.path.join(LEVEL_DIR, levelname, ring_file))
    try:
        for i, line in enumerate(level_file):
            if line.strip() and not line.startswith('#'):
                pos_str, time_str, button = line.split(";")
                x, y = pos_str.split(",")
                
                try:
                    f_x, f_y = float(x), float(y)
                except ValueError:
                    raise ValueError("Error parsing line %d from file '%s': could not convert (%s, %s) to float tuple" % (i, level_addr, x, y))
                try:
                    time_ant += float(time_str)
                except ValueError:
                    raise ValueError("Error parsing line %d from file '%s': could not convert (%s) to float" % (i, level_addr, time_str))
                    
                ring_list.append(((f_x, f_y), time_ant, button.strip()))           
            
        return ring_list

    finally:
        level_file.close()

#print level_list()
