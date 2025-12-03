#!/usr/bin/env python
# -*- coding: utf-8 -*-

from direct.task import Task
from direct.gui.OnscreenText import OnscreenText
from direct.gui.OnscreenImage import OnscreenImage

from panda3d.core import *
from direct.interval.IntervalGlobal import *

from utils import *

babelfish_font = loader.loadFont('./fonts/hum.egg')

class TitleMessage:
    def __init__(self, title, artist):
        text_node = TextNode('title_display')
        text_node.setAlign(TextNode.ACenter)
        text_node.setFont(babelfish_font)
        text_node.setTextColor(1, 1, 0.16, .9)
        text_node.setShadow(0.05, 0.05)
        text_node.setShadowColor(0.05, 0, 0.43, .9)
        
        
        self.title_display = aspect2d.attachNewNode(text_node)
        self.title_display.setScale(0.3)
        self.title_display.setZ(.1)
        self.title_display.setAlphaScale(.0)
        
        text_node = TextNode('artist_display')
        text_node.setAlign(TextNode.ACenter)
        text_node.setFont(babelfish_font)
        text_node.setTextColor(0.05, 0, 0.43, .9)
        text_node.setShadow(0.05, 0.05)
        text_node.setShadowColor(1, 1, 0.16, .9)
        
        self.artist_display = aspect2d.attachNewNode(text_node)
        self.artist_display.setScale(0.15)
        self.artist_display.setZ(-.1)
        self.artist_display.setAlphaScale(.0)
        
        self.title_display.node().setText(title)
        self.artist_display.node().setText(artist)

        Sequence(Parallel(LerpFunc(self.title_display.setAlphaScale, fromData=.0, toData=1, duration=.5),
                                      LerpFunc(self.artist_display.setAlphaScale, fromData=.0, toData=1, duration=.5)),
                        Wait(1.0),
                        Parallel(LerpFunc(self.title_display.setAlphaScale, fromData=1, toData=.0, duration=.5),
                                      LerpFunc(self.artist_display.setAlphaScale, fromData=1, toData=.0, duration=.5))).start()
            
    def clear(self):
        self.title_display.removeNode()
        self.artist_display.removeNode()
        

class ButtonViewer:
    def __init__(self, bpm, z_pos = -0.7):
        self.BTN_SPACE_PER_BEAT = 0.2
        self.BTN_SIZE = 64.0
        self.BTN_SIZE = 64.0
        self.BTN_SCALE = (self.BTN_SIZE/base.win.getXSize(), 1 ,self.BTN_SIZE/base.win.getYSize())
        
        self.z_pos = z_pos
        self.delay_per_beat = beat_delay(bpm)
        
        self.tex_buttons = {}
        for b, i in zip(["A", "B", "C", "D"],["down", "right", "left", "up"]):
            self.tex_buttons[b] = loader.loadTexture("image/wii_%s.png" % i)
    
        #~ else:
            #~ for b, i in zip(["A", "B", "C", "D"],["cross", "circle", "square", "triangle"]):
                #~ self.tex_buttons[b] = loader.loadTexture("image/b_%s.png" % i)
        
        ## Button marker
        self.button_marker = OnscreenImage(image="image/b_marker.png",pos=(0, 2, self.z_pos), scale=self.BTN_SCALE, parent=render2d)
        self.button_marker.setTransparency(TransparencyAttrib.MAlpha)
        
        self.button_node = render2d.attachNewNode("Button Root Node")
        self.initial_x = self.button_node.getX()
        
        self.next_button = 0
        
    def append_button(self, button, beat):
        btn_image = OnscreenImage(image=self.tex_buttons[button], pos=(-beat*self.BTN_SPACE_PER_BEAT, 0, self.z_pos), scale=self.BTN_SCALE, parent=render2d)
        btn_image.setTransparency(TransparencyAttrib.MAlpha)        
        btn_image.reparentTo(self.button_node)
    
    def update(self, time):
        self.button_node.setX(self.initial_x + time2pos(time, self.delay_per_beat, self.BTN_SPACE_PER_BEAT))
        
    def button_hit(self):
        pass
        #~ button = self.button_node.getChild(self.next_button)
        #~ button.setAlphaScale(.0)
        
        #~ self.next_button += 1
        #~ button = self.button_node.getChild(self.next_button )
        #~ pos = render2d.getRelativePoint(self.button_node, button.getPos())
    
        #~ button.reparentTo(render2d)
        #~ button.setPos(pos)
        
        #~ LerpFunc(button.setAlphaScale, duration=0.2, fromData=1, toData=0, blendType='easeOut').start()
        
    def button_miss(self):
        pass
        #self.next_button += 1
        
    def __del__(self):
        self.button_node.removeNode()
        self.button_marker.removeNode()
        
class LifeBar:
    def __init__(self):
        ## Life bar
        self.image = OnscreenImage(image="image/life_bar.png",pos=(0, 0, 0), scale=(256.0/base.win.getXSize(),1,32.0/base.win.getYSize()), parent=render2d)
        self.image.setTransparency(TransparencyAttrib.MAlpha)
        self.image.setZ(-0.9)
        self.image.setY(2)
        
    def __del__(self):
        self.image.destroy()
        
class ScoreDisplay:
    def __init__(self):
        ## Score display
        text_node = TextNode('score_display')
        text_node.setAlign(TextNode.ACenter)
        text_node.setFont(babelfish_font)
        text_node.setShadow(0.05, 0.05)
        text_node.setShadowColor(.0,.0,.0,.1)
        
        self.score_display = aspect2d.attachNewNode(text_node)
        self.score_display.setZ(0.9)
        self.score_display.setScale(0.11)
    
        self.score_display.node().setText("SCORE 0000000")
        
    def update(self, score):
        self.score_display.node().setText("SCORE %s" % str(score).rjust(7, '0'))

    def __del__(self):
        self.score_display.removeNode()

class ScreenDecorationManager:
    def __init__(self):
        self.tex_judgements = {}
        
        for i in ["PERFECT","GOOD","OK","BAD","MISS"]:
            self.tex_judgements[i] = loader.loadTexture("image/j_%s.png" % i.lower())
        
        ## Judgement message
        self.image_judgement = OnscreenImage(image=self.tex_judgements["OK"],pos=(0, 0, 0), scale=(256.0/base.win.getXSize(),1,32.0/base.win.getYSize()), parent=render2d)
        self.image_judgement.setTransparency(TransparencyAttrib.MAlpha)
        #self.image_judgement.setPos(-0.7, 1, 0.6)
        self.image_judgement.setAlphaScale(0)
        
        interval_pos = LerpPosInterval(self.image_judgement, duration=0.1, startPos=VBase3(-1.2, 1, 0.5), pos=VBase3(-0.7, 1, 0.5), blendType='easeOut')
        interval_alpha = LerpFunc(self.image_judgement.setAlphaScale, duration=0.1, blendType='easeOut')
        interval_fade = LerpFunc(self.image_judgement.setAlphaScale, fromData=1, toData=0, duration=1.0, blendType='easeOut')
        
        self.judgement_enters = Sequence(Parallel(interval_pos, interval_alpha), Wait(1.0), interval_fade)

        ## Chain message
        text_node = TextNode('chain_msg')
        text_node.setAlign(TextNode.ACenter)
        text_node.setFont(babelfish_font)

        text_node.setTextColor(1, 1, 0.16, .9)
        text_node.setShadow(0.05, 0.05)
        text_node.setShadowColor(0.05, 0, 0.43, .9)
        
        self.chain_msg = aspect2d.attachNewNode(text_node)
        self.chain_msg.setPos(-.9, 1, 0.35)
        self.chain_msg.setScale(0.11)
        
        
    def judgement_msg(self, msg, chain):
        if self.judgement_enters.isPlaying():
            self.judgement_enters.clearToInitial()
        
        self.image_judgement.setTexture(self.tex_judgements[msg])
        self.judgement_enters.start()
        
        if chain > 1:
            self.chain_msg.node().setText("%d CHAIN" % chain)
        
        taskMgr.add(self.task_ClearJudgementTask, "clear-judgement")
        
    def task_ClearJudgementTask(self, task):
        if task.time < 1.5:
            return Task.cont
            
        self.chain_msg.node().clearText()
    
    def __del__(self):
        self.judgement_enters.finish()
        self.image_judgement.destroy()
        self.chain_msg.removeNode()
