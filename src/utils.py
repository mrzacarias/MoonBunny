#!/usr/bin/env python
# -*- coding: utf-8 -*-

def time2pos(time, delay_per_beat, space_per_beat):
    return (time / delay_per_beat) * space_per_beat
    
def beat_delay(bpm):
    return 60.0/bpm
    
def clamp(low, v, hi): return max(low, min(v, hi))
    
def norm(acc, cal):
    return [(v - c0)/float(c1 - c0) for v, c0, c1 in zip(acc, cal[0], cal[1])]

def desloc(graus):
    return graus/100000.0
    
class ListMovements:
    #map: 0 - fly, 1 = left, 2 = right, 3 = up, 4 = down 
    def __init__(self):
        self.size = 10
        self.elements = 0
        self.list = [0,0,0,0,0,0,0,0,0,0]
    
    #adiciona um movimento a lista de movimentos
    def add(self, move):
        self.list[self.elements] = move
        self.elements += 1
        if self.elements == self.size:
            self.elements = 0
    
    #retorna a moda da lista
    def most(self):
        moves = [0,0,0,0,0]
        for mv in self.list:
            moves[mv] += 1

        x = 0
        m = max(moves)
        while moves[x] != m:
            x += 1
        
        return x
        
    #verifica se deve fazer o movimento, ou seja, se o movimento é a moda da lista e se é maior do que x pixels
    def do_movement(self, move):
        mv = self.most()        
        if move == mv :
            return True
        else:
            return False
            
    def move_char_x(self, mv_x, error = 2):
        if mv_x > error:
            return True
        else:
            return False

    def move_char_y(self, mv_y, error = 2):
        if mv_y > error:
            return True
        else:
            return False

#funcao booleana que verifica se o Wiimote serah utilizado
def uses_wii(options):
    wiimote_list = ['Wiimote IR', 'Wii e Nunchuk IR', 'Wiimote', 'Wii e Nunchuk']
    for wm in wiimote_list: 
        if (options.get('game-opts', 'controller') == wm):
            return True
    return False

def uses_nunchuk(options):
    nunchuk_list = ['Wii e Nunchuk IR', 'Wii e Nunchuk']
    for nc in nunchuk_list: 
        if (options.get('game-opts', 'controller') == nc):
            return True
    return False

def uses_wii_ir(options):
    wiimote_ir_list = ['Wiimote IR', 'Wii e Nunchuk IR']
    for ir in wiimote_ir_list: 
        if (options.get('game-opts', 'controller') == ir):
            return True
    return False