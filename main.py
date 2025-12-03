#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import time
import math

b_cwiid = True
wm_addr = '00:1E:35:7B:96:5D'

try:
    import cwiid
except ImportError:
    print("no cwiid =/")
    b_cwiid = False

for arg in sys.argv:
    try:
        bool_teste = False
        arg_splitted = arg.split('=')
        if arg_splitted[0] == "-w" or arg_splitted[0] == "--wiimote-address":
            wm_addr = arg_splitted[1]
    except:
        bool_teste = False
    
from panda3d.core import *
loadPrcFile("./config.prc")

import direct.directbase.DirectStart
from direct.task import Task
from direct.actor import Actor
from direct.showbase import DirectObject
from direct.gui.OnscreenText import OnscreenText
from direct.fsm import FSM

from direct.interval.IntervalGlobal import *

#tirando o cursor do mouse
from panda3d.core import WindowProperties
props = WindowProperties()
props.setCursorHidden(True) 
base.win.requestProperties(props)

import control

from level import *
from screens import *

import options

class Game(FSM.FSM):
    def __init__(self):
        FSM.FSM.__init__(self, 'Game')
        self.wm = None
        #controla ou nao o menu com wiimote
        #self.bool_wii = b_cwiid
        self.bool_wii = False
        
        self.defaultTransitions = {
            'Title' : [ 'Options', 'Training', 'LevelSelect', 'Exit' ],
            'Training': [ 'Load', 'Title', 'Options', 'Result'],
            'Options' : [ 'Title' , 'Level'],
            'LevelSelect' : [ 'Level', 'Title'],
            'Load' : ['LevelSelect','Training', 'Level'],
            'Level' : [ 'Result', 'Load', 'Options'],
            'Result' : [ 'Level', 'Title', 'Training'],
            }

        self.options = options.MoonBunnyOptions()
        self.start_level_sfx = loader.loadSfx('./sound/start_level.wav')
        self.theme = loader.loadMusic('./sound/always.wav')
        self.theme.setLoop(True)
        
        logo_sound= loader.loadSfx('./sound/elefante.wav')
        self.logo = OnscreenImage(image='./image/tromba_logo.png', scale=(512.0/base.win.getXSize(), 1 ,256.0/base.win.getYSize()), pos = (0.0, 2.0, 0.0), parent=render2d)
        self.logo.setTransparency(TransparencyAttrib.MAlpha)                
        Sequence( 
                LerpFunc(self.logo.setAlphaScale, fromData=.0, toData=1, duration=.5),
                SoundInterval(logo_sound, duration=4.0),
                LerpFunc(self.logo.setAlphaScale, fromData=1, toData=.0, duration=.5),
                Func(self.request,'Title')
                ).start()
    
    def connect_wii(self, end):
        try:
            self.wm = cwiid.Wiimote(end)
        except RuntimeError:
            pass

    ## Title state
    def enterTitle(self):
        if self.theme.status() == 1:
            self.theme.play()

        self.title_screen = TitleScreen()
        
    def exitTitle(self):
        self.title_screen.clear()

    def filterTitle(self, request, args):
        if request == 'nav-up' or request == 'nav-down':
            self.title_screen.option_changed(request.replace('nav-', ''))
            
        if request == 'nav-confirm':
            #~ if self.title_screen.option_pressed() == 'start':
                #~ return ("Load", 's')
            if self.title_screen.option_pressed() == 'start':
                return ("LevelSelect")
            if self.title_screen.option_pressed() == 'training':
                return ("Load", 't')
            if self.title_screen.option_pressed() == 'options':
                return 'Options'
            if self.title_screen.option_pressed() == 'exit':
                return 'Exit'
            
        if request == 'nav-back':
            return 'Exit'
        
    ## LevelSelect state
    def enterLevelSelect(self):
        if self.theme.status() == 1:
            self.theme.play()
        self.level_select = LevelSelectScreen(self.options)
        
    def exitLevelSelect(self):
        self.level_select.clear()
        
    def filterLevelSelect(self, request, args):
        if request == 'nav-confirm':
            level_name = self.level_select.option_pressed()
            return ("Load", 's', level_name)
        if request == 'nav-back':
            return 'Title'
        if request == 'nav-left'or request == 'nav-right':
            self.level_select.option_changed(request.replace('nav-', ''))

    
    ## Options state
    def enterOptions(self):
        self.options_screen = OptionsScreen(self.options)
        
    def exitOptions(self):
        self.options_screen.clear()
        self.options.save()
        
    def filterOptions(self, request, args):
        if request == 'nav-left' or request == 'nav-right':
            self.options_screen.option_changed(request)
        if request == 'nav-back' or request == 'nav-confirm':
            return 'Title'

    
    ## Load state
    def enterLoad(self, tipo, l_n=''):
        if self.theme.status() == 1:
            self.theme.play()
        self.load_screen = LoadScreen(self.options)
        self.tipo = tipo
        self.level_name = l_n
        
    def exitLoad(self):
        pass
       
    def filterLoad(self, request, args):
        if request == 'nav-confirm':
            if self.tipo == 's':
                return ('Level', self.level_name, 'Normal', self.load_screen)
            elif self.tipo == 't':
                return ('Training', 'rain_of_love', 'Normal', self.load_screen)

        if request == 'nav-back':
            self.load_screen.clear()
            return 'Title'    
    

    #conectando wiimote e tratando eventuais erros
    def connect_wiimote(self, wm_addr):
        try:
            self.wm = cwiid.Wiimote(wm_addr)
        except RuntimeError:
            pass
        
        self.wm.led = cwiid.LED1_ON
        
        if uses_nunchuk(self.options):
            self.wm.rpt_mode = cwiid.RPT_BTN | cwiid.RPT_ACC | cwiid.RPT_IR | cwiid.RPT_NUNCHUK
        else:
            if uses_wii_ir(self.options):
                self.wm.rpt_mode = cwiid.RPT_BTN | cwiid.RPT_ACC | cwiid.RPT_IR
            else:
                self.wm.rpt_mode = cwiid.RPT_BTN | cwiid.RPT_ACC

    ## Training state
    def enterTraining(self, level, difficulty, load_screen):
        self.theme.stop()
        self.ls = load_screen

        #verifica se a cwiid esta instalada na maquina e se o controle escolhido eh envolve o Wiimote
        if b_cwiid and uses_wii(self.options):
            self.connect_wiimote(wm_addr)
            self.level = Level(level, difficulty=difficulty, options=self.options, wm=self.wm, b_training=True)
        #caso nao utilize o Wiimote
        else:
            self.level = Level(level, difficulty=difficulty, options=self.options, b_training = True)
        
        Sequence(Func(self.ls.clear), SoundInterval(self.start_level_sfx), Func(self.level.setup), Func(self.level.play)).start()

    def exitTraining(self):
        self.level_name = self.level.name
        self.level_score = self.level.score
        self.rank_stats = (self.level.judgement_stats, self.level.n_rings)
        del self.level
        self.level = None
        if uses_wii(self.options):
            self.wm.led = 0
        
        return 'Title'


    ## Level state
    def enterLevel(self, level, difficulty, load_screen):
        self.theme.stop()
        self.ls = load_screen        
        
        #verifica se a cwiid esta instalada na maquina e se o controle escolhido eh envolve o Wiimote
        if b_cwiid and uses_wii(self.options):
            self.connect_wiimote(wm_addr)
            self.level = Level(level, difficulty=difficulty, options=self.options, wm=self.wm)

        #caso nao utilize o Wiimote
        else:
            self.level = Level(level, difficulty=difficulty, options=self.options)
        
        Sequence(Func(self.ls.clear), SoundInterval(self.start_level_sfx), Func(self.level.setup), Func(self.level.play)).start()
        
    def exitLevel(self):
        self.level_name = self.level.name
        self.level_score = self.level.score
        self.rank_stats = (self.level.judgement_stats, self.level.n_rings)
        del self.level
        self.level = None
        if uses_wii(self.options):
            self.wm.led = 0

    ## Result
    def enterResult(self):
        rank = self.calculate_rank(*self.rank_stats)
        self.save_score(self.level_name, rank, self.level_score)
        self.result_screen = ResultScreen(rank, self.level_score, self.rank_stats[0])
        
    def exitResult(self):
        self.result_screen.clear()

    def filterResult(self, request, args):
        if request == 'nav-confirm':
            return 'Title'
        if request == 'nav-back':
            return 'Title'

    def enterExit(self):
        sys.exit(0)

    def save_score(self, levelname, rank, score):
        if not self.options.has_section('hiscores'):
            self.options.add_section('hiscores')
            
        if self.options.has_option('hiscores', levelname):
            old_rank, old_score = self.options.get('hiscores', levelname).split(',')
            
            if rank != 's' and  rank != 'ss' and old_rank != 'ss':
                if ord(old_rank) < ord(rank): 
                    rank = old_rank

            
            if int(old_score) > score: 
                score = old_score
                    
        self.options.set('hiscores', levelname, "%s,%s" % (rank, str(score)))
        self.options.save()

    def calculate_rank(self, stats, n):
        rates = {
            "PERFECT": float(stats['PERFECT']) / float(n),
            "GOOD": float(stats['GOOD']) / float(n),
            "OK" : float(stats['OK']) / float(n),
            "BAD" : float(stats['BAD']) / float(n),
            "MISS": float(stats['MISS']) / float(n)
        }
        
        if(rates['PERFECT'] ==1):
            rank = 'ss'
        
        elif( rates['MISS'] <= 0 and rates['BAD'] <= 0.1 and rates['PERFECT'] >=0.5):
            rank = 's'
            
        elif( rates['MISS'] <= 0.05 and (rates['MISS'] + rates['BAD'] <= 0.2) and (rates['GOOD'] + rates['PERFECT'] >=0.4) ):
            rank = 'a'
            
        elif( (rates['MISS'] + rates['BAD'] <= 0.3) and (rates['GOOD'] + rates['PERFECT'] >=0.3) ):
            rank = 'b'
            
        elif( (rates['MISS'] + rates['BAD'] <= 0.4) and (rates['GOOD'] + rates['PERFECT'] >=0.2) ):
            rank = 'c'
            
        else:
            rank = 'f'

        return rank


class WiimoteHandler(DirectObject.DirectObject):
    def __init__(self, game):
        self.game = game
        self.last_button = 0
        taskMgr.add(self.ctask_CheckEvents, "cwiid-event")
    
    def ctask_CheckEvents(self, task):
        
        if not game.bool_nunchuk:
            if self.game.wm.state['buttons'] == cwiid.BTN_UP:
                if self.last_button != cwiid.BTN_UP:
                    messenger.send("nav-up")
                    self.last_button = cwiid.BTN_UP
                    
            elif self.game.wm.state['buttons'] == cwiid.BTN_DOWN:
                if self.last_button != cwiid.BTN_DOWN:
                    messenger.send("nav-down")
                    self.last_button = cwiid.BTN_DOWN 
                    
            elif self.game.wm.state['buttons'] == cwiid.BTN_LEFT:
                if self.last_button != cwiid.BTN_LEFT:
                    messenger.send("nav-left")
                    self.last_button = cwiid.BTN_LEFT 
                    
            elif self.game.wm.state['buttons'] == cwiid.BTN_RIGHT:
                if self.last_button != cwiid.BTN_RIGHT:
                    messenger.send("nav-right")
                    self.last_button = cwiid.BTN_RIGHT 
                    
            elif self.game.wm.state['buttons'] == cwiid.BTN_A:
                if self.last_button != cwiid.BTN_A:
                    messenger.send("nav-confirm")
                    self.last_button = cwiid.BTN_A 
                    
            elif self.game.wm.state['buttons'] == cwiid.BTN_B:
                if self.last_button != cwiid.BTN_B:
                    messenger.send("nav-back")
                    self.last_button = cwiid.BTN_B 
            
            else:
                self.last_button = 0
        else:
            #Left
            if self.game.wm.state['nunchuk']['stick'][0] < 50: 
                if self.last_button != 1:
                    messenger.send("nav-left")
                self.last_button = 1
            
            #Down
            elif self.game.wm.state['nunchuk']['stick'][1] < 50: 
                if self.last_button != 2:
                    messenger.send("nav-down")
                self.last_button = 2
                
            #Right
            elif self.game.wm.state['nunchuk']['stick'][0] >200: 
                if self.last_button != 3:
                    messenger.send("nav-right")
                self.last_button = 3
                
            #Up
            elif self.game.wm.state['nunchuk']['stick'][1] > 200: 
                if self.last_button != 4:
                    messenger.send("nav-up")
                self.last_button = 4

            elif self.game.wm.state['buttons'] == cwiid.BTN_A:
                if self.last_button != cwiid.BTN_A:
                    messenger.send("nav-confirm")
                    self.last_button = cwiid.BTN_A 
                    
            elif self.game.wm.state['buttons'] == cwiid.BTN_B:
                if self.last_button != cwiid.BTN_B:
                    messenger.send("nav-back")
                    self.last_button = cwiid.BTN_B 

            else:
                self.last_button = 0

        return Task.cont


class Controller(DirectObject.DirectObject):
    def __init__(self, game):
        self.game = game
        
        self.accept("nav-up", self.game.request, ['nav-up'])
        self.accept("nav-down", self.game.request, ['nav-down'])
        self.accept("nav-left", self.game.request, ['nav-left'])
        self.accept("nav-right", self.game.request, ['nav-right'])
        self.accept("nav-confirm", self.game.request, ['nav-confirm'])
        self.accept("nav-back", self.game.request, ['nav-back'])
        
        self.accept("level-finished", self.game.request, ['Result'])
        self.accept("training-finished", self.game.request, ['Options'])
    
    
class JoystickManager:
    def __init__(self):
        pygame.init()
        pygame.joystick.init()
        taskMgr.add(self.ctask_CheckEvents, "pygame-event")
        
        print("Joysticks available:", pygame.joystick.get_count())
        
        self.joy_list = [pygame.joystick.Joystick(i) for i in range(pygame.joystick.get_count())]
        
        if self.joy_list:
            pass
    
    def init_joy(self, id):
        self.joy_list[id].init()
    
    def set_current_joy(self, id):
        pass
    
    def ctask_CheckEvents(self, task):
        pygame.event.pump()
        
        if self.joy.get_button(2): messenger.send("joy-button", ["A"])
        if self.joy.get_button(1): messenger.send("joy-button", ["B"])
        if self.joy.get_button(3): messenger.send("joy-button", ["C"])
        if self.joy.get_button(0): messenger.send("joy-button", ["D"])
            
        return Task.cont
            

if __name__ == '__main__':

    base.enableParticles()
    base.disableMouse()
    base.setBackgroundColor(.0, .0, .0, .0)
    
    control.KeyNavMapper()
    
    try:
        pygame.init()
        pygame.joystick.init()
        j = pygame.joystick.Joystick(0)
        j.init()
        control.JoyNavMapper(j).activate()
        
    except pygame.error as e:
        print(e)
    
    game = Game()
    Controller(game)
    
    base.run()
    