#!/usr/bin/env python
# -*- coding: utf-8 -*-

from direct.gui.OnscreenText import OnscreenText
from direct.gui.OnscreenImage import OnscreenImage
from direct.interval.IntervalGlobal import *
from pandac.PandaModules import *

import parse
import particle
from utils import *

babelfish_font = loader.loadFont('./fonts/hum.egg')
menuSfx = loader.loadSfx('./sound/menu.wav')

class TitleScreen:
    def __init__(self):
        self.bg_particle = particle.StarParticles()
        self.bg_particle.start(render2d)
        self.bg_particle.setPos(.0, 1.5, 1.0)
        
        self.TITLE_SCALE = (512.0/base.win.getXSize(), 1 ,256.0/base.win.getYSize())
        
        self.bg = OnscreenImage(image='./image/bg.png', pos = (0.0, 2.0, 0.0), parent=render2d)
        self.bg.setTransparency(TransparencyAttrib.MAlpha)
        
        
        self.title_img = OnscreenImage(image='./image/title.png', pos = (0.0, 1.0, 0.6), scale = self.TITLE_SCALE, parent=render2d)
        self.title_img.setTransparency(TransparencyAttrib.MAlpha)
        
        texts = [OnscreenText(text='Start', scale=0.2, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1)),
            OnscreenText(text='Training',  scale=0.2, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1)),
            OnscreenText(text='Options',  scale=0.2, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1)),
            OnscreenText(text='Exit',  scale=0.2, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))]
        
        for i in range(len(texts)):
            node = aspect2d.attachNewNode("TextPos%d" % i)
            texts[i].reparentTo(node)
            node.setZ(-0.15*(i+1) - .08)
        
        self.options = [
            {
                'action':'start',
                'node': texts[0],
            },
            {
                'action':'training',
                'node': texts[1]
            },
            {
                'action':'options',
                'node': texts[2]
            },
            {
                'action':'exit',
                'node': texts[3]
            },
        ]
            
        
        for opt in self.options:            
            opt['sel_interval'] = Parallel(LerpScaleInterval(opt["node"], duration=0.2, startScale=1.0, scale=1.4, blendType='easeOut'), SoundInterval(menuSfx))
            opt['des_interval'] = LerpScaleInterval(opt["node"], duration=0.2, startScale=1.4, scale=1.0, blendType='easeOut')
        
        self.curr_option = 0
        self.options[self.curr_option]['sel_interval'].finish()
        
        self.copyright_text = OnscreenText(text='MoonBunny (c) TrombaSoft 2007', shadow=(.0,.0,.0,1), scale=0.09, pos=(.0, -.95), align=TextNode.ACenter, fg=(1,1,1,1))
        
    
    def option_changed(self, command):
        
        int1 = self.options[self.curr_option]['des_interval']
        
        if command=='up':
            self.curr_option = (self.curr_option - 1) % len(self.options)
        elif command=='down':
            self.curr_option = (self.curr_option + 1) % len(self.options)
        
        int2 = self.options[self.curr_option]['sel_interval']
        
        Parallel(int1, int2).start()
        
    def option_pressed(self):
        return self.options[self.curr_option]['action']
                                                
    def clear(self):
        self.bg_particle.cleanup()
        self.bg.destroy()
        self.title_img.destroy()
        for opt in self.options:
            opt['node'].destroy()
            
        self.copyright_text.destroy()


class LevelSelectScreen:
    def __init__(self, game_opts):
        self.ITEM_SPACING = 1.7
        
        self.game_opts = game_opts
        
        self.title = OnscreenText(text = 'Select Level', pos = (0.0, 0.7), scale = 0.3, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))
        self.bg = OnscreenImage(image='./image/bg.png', pos = (0.0, -1.0, 0.0), parent=render2d)
        self.bg.setTransparency(TransparencyAttrib.MAlpha)
        
        self.curr_option = 0
        self.levels = []
        
        self.arrow_left =  OnscreenImage(image='./image/arrow_left.png', scale=(64.0/base.win.getXSize(), 1 ,64.0/base.win.getYSize()), pos = (-.8, -3.0, 0.0), parent=aspect2d)
        self.arrow_left.setTransparency(TransparencyAttrib.MAlpha)
        
        self.arrow_right = OnscreenImage(image='./image/arrow_right.png', scale=(64.0/base.win.getXSize(), 1 ,64.0/base.win.getYSize()), pos = (.8, -3.0, 0.0), parent=aspect2d)
        self.arrow_right.setTransparency(TransparencyAttrib.MAlpha)
        
        level_list = parse.level_list()
        level_list.sort()
        
        self.item_list_node = aspect2d.attachNewNode("ItemList")
        self.initial_x = self.item_list_node.getX()
        
        for i, lvl in enumerate(level_list):
            header = parse.level_header(lvl)
            
            level_item = self.make_level_item(header)
            level_item.setX(self.ITEM_SPACING*i)
            level_item.setZ(-0.1)
            level_item.setScale(.8)
            
            level_item.reparentTo(self.item_list_node)
            self.levels.append(header['NAME'])
    
        self.cur_interval = None
        self.update()
    
    def create_cur_interval(self):
        return Sequence(LerpScaleInterval(self.item_list_node.getChild(self.curr_option), duration=0.4, startScale=.8, scale=.85), 
                                    LerpScaleInterval(self.item_list_node.getChild(self.curr_option), duration=0.4, startScale=.85, scale=.8))
    
    def option_changed(self, command):
        changed = False
        
        if command=='left' and self.curr_option > 0:
            self.curr_option = (self.curr_option - 1)
            changed = True
            
        elif command=='right' and self.curr_option < len(self.levels)-1:
            self.curr_option = (self.curr_option + 1)
            changed = True
        
        if changed:
            interval = Parallel(LerpPosInterval(self.item_list_node, duration=.2, startPos=VBase3(self.item_list_node.getX(),.0,.0), pos=VBase3(-self.ITEM_SPACING*self.curr_option,.0,.0)), SoundInterval(menuSfx))
            interval.start()
            self.update()
    
    def update(self):
        if self.curr_option < 1:
            self.arrow_left.setAlphaScale(.0)
        else:
            self.arrow_left.setAlphaScale(1)
    
        if self.curr_option >= len(self.levels)-1:
            self.arrow_right.setAlphaScale(.0)
        else:
            self.arrow_right.setAlphaScale(1)
        
        if self.cur_interval:
            self.cur_interval.finish()
            del self.cur_interval
        
        self.cur_interval = self.create_cur_interval()
        self.cur_interval.loop()
    
    def option_pressed(self):
        return self.levels[self.curr_option]
                                                
    def clear(self):
        self.bg.destroy()
        self.arrow_left.destroy()
        self.arrow_right.destroy()
        self.title.destroy()
        self.item_list_node.removeNode()
            
    def make_level_item(self, level_header):
        level_name = level_header['NAME']
        
        level_item = aspect2d.attachNewNode(level_name)
        level_img = OnscreenImage(image='./levels/%s/image.png' % level_name, 
                scale=(512.0/base.win.getXSize(), 1 ,362.0/base.win.getYSize()), pos = (0.0, 0.0, 0.3), parent=level_item)
                
        level_img.setTransparency(TransparencyAttrib.MAlpha)
        level_img.reparentTo(level_item)
        
        if level_header.has_key("TITLE"):
            title_str = "%s" % level_header["TITLE"]
        else:
            title_str = "%s" % level_header["NAME"]
        
        artist_str = ""
        if level_header.has_key("ARTIST"):
            artist_str = "by %s" %  level_header["ARTIST"]
            
        
        title_text = OnscreenText(text = title_str, pos = (0.0, 0.-0.3), scale = 0.2, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))
        title_text.reparentTo(level_item)
        
        next_y = -0.50
        
        if artist_str:
            next_y -= 0.05
            artist_text = OnscreenText(text = artist_str, pos = (0.0, 0.-0.4), scale = 0.15, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))
            artist_text.reparentTo(level_item)
            
            
        bpm_text = OnscreenText(text = "BPM %.2f" % level_header["BPM"], pos = (0.0, next_y), scale = 0.18, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))
        bpm_text.reparentTo(level_item)
        
        if self.game_opts.has_option('hiscores', level_name):
            his = self.game_opts.get('hiscores', level_name).split(',')            
            maxrank = OnscreenText(text = "max rank %s" % his[0].upper(), 
                pos = (0.0, next_y-0.15), scale = 0.18, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))
                
            hiscore = OnscreenText(text = "hiscore %s" % his[1], 
                pos = (0.0, next_y-0.25), scale = 0.18, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))

            maxrank.reparentTo(level_item)
            hiscore.reparentTo(level_item)
        
        return level_item

class OptionsScreen:
    def __init__(self, options):
        self.bg = OnscreenImage(image='./image/bg.png', pos = (0.0, -1.0, 0.0), parent=render2d)
        self.bg.setTransparency(TransparencyAttrib.MAlpha)
        
        self.title = OnscreenText(text = 'Options', pos = (0.0, 0.7), scale = 0.3, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))

        self.option_title_txt = OnscreenText(text='Controller', scale=0.2, pos=(-1.0, 0.0), font=babelfish_font, align=TextNode.ALeft, fg=(1,1,1,1))
        
        self.option_value = options.get('game-opts', 'controller')
        self.option_value_txt = OnscreenText(text=self.option_value, scale=0.2, pos=(.7, 0.0), font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))
    
        self.options = options
        self.curr_controller = 0
        
        self.controllers = ['Keyboard','Joypad', 'Mouse']
        
        #define o controle atual baseado no arquivo salvo
        for f in self.controllers:
            if f == self.option_value:
                break
            else:
                self.curr_controller += 1
        
    def option_changed(self, command):
        self.toggle_value(command)
    
    def toggle_value(self, opt):
        if opt == 'nav-right':
            self.curr_controller += 1
        elif opt == 'nav-left':
            self.curr_controller -= 1
        if (self.curr_controller >= len(self.controllers)):
            self.curr_controller = 0
        elif (self.curr_controller < 0):
            self.curr_controller = len(self.controllers) - 1
            
        self.option_value = self.controllers[self.curr_controller]
        self.option_value_txt.destroy()
        self.option_value_txt = OnscreenText(text=self.option_value, scale=0.2, pos=(.7, 0.0), font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))
    
    def clear(self):
        self.bg.destroy()
        self.title.destroy()
        
        self.option_title_txt.destroy()
        self.option_value_txt.destroy()

        self.options.set('game-opts', 'controller', self.option_value)

class ResultScreen:
    def __init__(self, rank, score, stats):        
        text_list = []
        
        text_list.append(OnscreenText(text = 'Level Ended', pos = (0.0, 0.7), scale = 0.3, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1)))
        
        judgements = ["PERFECT","GOOD","OK","BAD","MISS"]
        
        text_j = "\n".join(judgements)
       
        text_n = "\n".join(["%d" % stats[j] for j in judgements])
        
        text_list.append(OnscreenText(text = text_j, pos = (-1.2, 0.35), scale = 0.2, font=babelfish_font, align=TextNode.ALeft, fg=(1,1,1,1)))
        text_list.append(OnscreenText(text = text_n, pos = (0.2, 0.35), scale = 0.2, font=babelfish_font, align=TextNode.ARight, fg=(1,1,1,1)))
        text_list.append((OnscreenText(text = "RANK", pos = (0.85, 0.35), scale = 0.15, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))))
        
        self.rank_image = OnscreenImage(image = "./image/rank_%s.png" % rank, pos = (0.7, 0.0, -0.2), 
                scale = (256.0/base.win.getXSize()*0.8, 1.0, 256.0/base.win.getYSize()*0.8), parent=render2d)
        self.rank_image.setTransparency(TransparencyAttrib.MAlpha)
        
        #text_list.append((OnscreenText(text = rank, pos = (0.75, -0.25), scale = 0.9, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))))
        
        text_list.append((OnscreenText(text = 'SCORE   %d'%score, pos = (0.0, -0.7), scale = 0.2, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))))
        text_list.append((OnscreenText(text = 'press "SPACE " to continue', pos = (0.0, -0.9), scale = 0.16, font=babelfish_font, align=TextNode.ACenter, fg=(1,1,1,1))))
        
        self.text_list = text_list
        
    def clear(self):
        self.rank_image.destroy()
        
        for txt in self.text_list:
            txt.destroy()

class LoadScreen:
    def __init__(self, options):        
        self.options = options
        
        if self.options.get('game-opts', 'controller') == 'Joypad':
            self.bg = OnscreenImage(image='./image/tela_joypad.png', pos = (0.0, 2.0, 0.0), parent=render2d)
            self.bg.setTransparency(TransparencyAttrib.MAlpha)
        elif self.options.get('game-opts', 'controller') == 'Keyboard':
            self.bg = OnscreenImage(image='./image/tela_keyboard.png', pos = (0.0, 2.0, 0.0), parent=render2d)
            self.bg.setTransparency(TransparencyAttrib.MAlpha)
        elif self.options.get('game-opts', 'controller') == 'Mouse':
            self.bg = OnscreenImage(image='./image/tela_mouse.png', pos = (0.0, 2.0, 0.0), parent=render2d)
            self.bg.setTransparency(TransparencyAttrib.MAlpha)

        if uses_wii(self.options):
            self.press =  self.wiimote_connection_text = OnscreenText(text='Press SPACE to continue and 1+2 to connect the Wiimote', shadow=(.0,.0,.0,1), scale=0.09, pos=(.0, -.95), align=TextNode.ACenter, fg=(1,1,1,1))
        else:
            self.press =  self.wiimote_connection_text = OnscreenText(text='Press SPACE to continue', shadow=(.0,.0,.0,1), scale=0.09, pos=(.0, -.95), align=TextNode.ACenter, fg=(1,1,1,1))
    def alpha(self):
        Sequence(LerpFunc(self.bg.setAlphaScale, fromData=.1, toData=0, duration=.3)).start()
    def clear(self):
        self.bg.destroy()
        self.press.destroy()
