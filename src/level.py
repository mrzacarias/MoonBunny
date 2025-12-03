#!/usr/bin/env python
# -*- coding: utf-8 -*-

import math
    
import pygame
from direct.task import Task
from direct.actor import Actor
from direct.showbase import DirectObject
from direct.gui.OnscreenText import OnscreenText
from panda3d.core import *
from direct.interval.IntervalGlobal import *

import gui
import parse
import particle
try:
    import cwiid_compat as cwiid
except ImportError:
    try:
        import cwiid
    except ImportError:
        print("no cwiid =/")

from utils import *

class Level(DirectObject.DirectObject):
    def __init__(self, name, options=None, difficulty="Normal", joystick=None, camera=base.camera, wm=None, b_training=False):
        self.options = options
        self.bool_training = b_training
        self.first = True
        
        if wm:
            self.wm = wm
        
        #booleano para teste de mouse
        self.bool_mouse = False
        
        #booleano para teste com wiimote
        self.bool_wiimote = False
        self.bool_wiimote_ir = False
        self.bool_nun_error = False
        
        self.miss_time = 0.0
        self.bool_miss = True
        self.angle_R = 0.0
        self.angle_P = 0.0
        
        if self.options.get('game-opts', 'controller') == 'Mouse':
            self.bool_mouse = True
        elif uses_wii(self.options):
            self.bool_wiimote = True
            if uses_wii_ir(self.options):
                self.bool_wiimote_ir = True

        ## Constantes
        self.FLY_AREA_W = 6.0
        self.FLY_AREA_H = 4.0
        
        self.FLY_AREA_R = self.FLY_AREA_W/4
        self.FLY_AREA_L = -self.FLY_AREA_W/4
        self.FLY_AREA_T = self.FLY_AREA_H/5
        self.FLY_AREA_B = -self.FLY_AREA_H/3
        
        self.RING_SPACING_PER_BEAT = 20
        
        self.SPEED_SCALE = .08        
        
        self.CONTROL_UPDATE_DELAY = 1.0/60.0
    
        self.rootNode = render.attachNewNode("Level Root Node")
        
        self.miss_sound = loader.loadSfx('./sound/miss.wav')
        
        self.name = name
        self.difficulty = difficulty
        
        self.y_signal = -1

        if self.bool_wiimote:
            if uses_nunchuk(self.options):
                for i in range(1000):
                    try:
                        self.wm.state['nunchuk']['stick'][0]
                    except KeyError:
                        self.bool_nun_error = True
                    else:
                        self.bool_nun_error = False
            if self.bool_nun_error:
                print("No Nunchuk conected, using standard Wiimote\n")

            self.cal = self.wm.get_acc_cal(cwiid.EXT_NONE)

        if self.bool_mouse or self.bool_wiimote:
            self.x_old = 300
            self.y_old = 213
            
            base.win.movePointer(0, int(self.x_old), int(self.y_old))
            self.mvs = ListMovements()

    def setup(self):
        self.setup_logic()
        self.setup_graphics()
        self.setup_gui()
        self.setup_rings()
        self.setup_events()
    
    def setup_logic(self):
        self.info = parse.level_header(self.name)
        
        #################
        ## Musica
        self.music = loader.loadMusic(self.info["MUSIC_FILE"])
        self.music_bpm = self.info["BPM"]
        self.BEAT_DELAY = beat_delay(self.music_bpm)
                
        #################
        ## Pontuacao4o, Chain e Vida
        
        self.score = 0
        self.chain = 0
        self.max_chain = 0
        
        self.MAX_LIFE = 20
        self.LIFE_FILL_THRESHOLD = 4
        
        self.life = 7

        #################
        ## Dicionarios
        self.score_map = {
            "PERFECT" : 200,
            "GOOD" : 100,
            "OK" : 50,
            "BAD" : 5,
            "MISS" : 0,
        }
        
        self.precision_judge = {
            0.08 : "PERFECT",
            0.2 : "GOOD",
            0.3 : "OK",
            0.5 : "BAD",
            1.0 : "MISS",
        }
        
        self.score_list = list(self.precision_judge.keys())
        self.score_list.sort()
        
        self.judgement_stats = {
            "PERFECT" : 0,
            "GOOD" : 0,
            "OK" : 0,
            "BAD" : 0,
            "MISS" : 0,
        }

    def setup_gui(self):
        #################
        ## Decoracoes de Tela
        self.deco_mgr = gui.ScreenDecorationManager()
        self.btn_viewer = gui.ButtonViewer(self.music_bpm,z_pos=-0.8)
        self.score_display = gui.ScoreDisplay()

    def setup_graphics(self):
        #################
        ## Ator principal
        self.bunnyActor = Actor.Actor("models/bunny_boy", {
                "fly": "models/bunny_boy-fly",
                "turn-left": "models/bunny_boy-turn-left",
                "turn-right": "models/bunny_boy-turn-right",
                "dive": "models/bunny_boy-dive",
                "rise": "models/bunny_boy-rise",
        })
        self.bunnyActor.setScale(0.11, 0.11, 0.11)
        self.bunnyActor.setHpr(180, 0, 0)
        self.bunnyActor.setPos(.0, .0, .0)
        self.bunnyActor.reparentTo(self.rootNode)
        self.bunnyActor.loop("fly")
        self.bunnyActor.setLightOff()
        self.bunnyActor.speed = Vec3(0, 0, 0)
        self.bunnyActor.last_update = 0
        
        #################
        ## Inicializaca4o de camera
        self.camera = camera
        
        self.camera.setPos(0, -4.5, 0.3)
        self.camera.lookAt(0.0,0.0,0.0)
        self.camera_z_offset = 0.4
        self.camera.setZ(0.0)
        self.camera_offset = 5

        base.cam.node().getLens().setFar(500000)

        #################
        ## self.skybox
        self.skybox = loader.loadModel("./models/skybox")
        
        self.skybox.setZ(-15)
        
        self.skybox.reparentTo(self.rootNode)
        self.skybox.setFogOff()
        self.skybox.setLightOff()
        
        self.skybox.setScale(80)

        ambientLight = AmbientLight("ambientLight")
        ambientLight.setColor(Vec4( 2.0, 2.0, 2.0, 1 ))
        self.skybox.attachNewNode(ambientLight) 
        
        interval_hpr_skybox = LerpHprInterval(self.skybox, duration=1000.0, startHpr=VBase3(0, 0, 0), hpr=VBase3(360, 0, 0))
        interval_hpr_skybox.loop()
        
        #################
        ## Terreno
        self.TERRAIN_Z = -15
        self.TERRAIN_PATCHES = 20
        self.TERRAIN_PATCHES_W = 1
        
        self.terrain_patch_size = 39.9934616089 
        self.terrain_patch_list = []
        
        for i in range(self.TERRAIN_PATCHES):
            terrain_index = (i % 8) + 1
            terrain = loader.loadModelCopy("./models/terrain_%d" % terrain_index)
            
            terrain.setPos(.0, 24 + self.terrain_patch_size*i - 0.1, self.TERRAIN_Z)
            terrain.reparentTo(self.rootNode)
            
            self.terrain_patch_list.append(terrain)

        
        #################
        ## Fog
        fog = Fog('distanceFog')
        fog.setColor(Vec4(0.25, 0.80, 0.97, 1))
        fog.setExpDensity(.002)
        render.setFog(fog)

        #################
        ## Iluminacao
        # Create Ambient Light
        ambientLight = AmbientLight( 'ambientLight' )
        ambientLight.setColor( Vec4( 0.4, 0.4, 0.4, 1 ) )
        ambientLightNP = render.attachNewNode( ambientLight )
        self.rootNode.setLight(ambientLightNP)

        # Directional light 01
        directionalLight = DirectionalLight( "directionalLight" )
        directionalLight.setColor( Vec4( 1.1, 1.1, 0.9, 1 ) )
        directionalLightNP = self.rootNode.attachNewNode( directionalLight )
        # This light is facing backwards, towards the camera.
        directionalLightNP.setHpr(180, -20, 0)
        self.rootNode.setLight(directionalLightNP)

        # Directional light 02
        directionalLight = DirectionalLight( "directionalLight" )
        directionalLight.setColor( Vec4( 0.6, 0.6, 0.6, 1 ) )
        directionalLightNP = self.rootNode.attachNewNode( directionalLight )
        # This light is facing forwards, away from the camera.
        directionalLightNP.setHpr(0, -20, 0)
        self.rootNode.setLight(directionalLightNP)

    def setup_events(self):        
        if self.bool_wiimote:
            self.button_map = ButtonMap(options = self.options, wm = self.wm, b_nunc = self.bool_nun_error)
        else:
            self.button_map = ButtonMap(options = self.options)
                
        if self.bool_wiimote and not uses_nunchuk(self.options):
            self.accept("wii-button", self.check_button_press)
        elif uses_nunchuk(self.options):
            if self.bool_nun_error:
                self.accept("wii-button", self.check_button_press)
            else:
                self.accept("nunchuk-button", self.check_button_press)

        else:
            self.accept("arrow_left", self.setKey, ["left",1])
            self.accept("arrow_right", self.setKey, ["right",1])
            self.accept("arrow_up", self.setKey, ["up",1])
            self.accept("arrow_down", self.setKey, ["down",1])
            
            self.accept("arrow_left-up", self.setKey, ["left",0])
            self.accept("arrow_right-up", self.setKey, ["right",0])
            self.accept("arrow_up-up", self.setKey, ["up",0])
            self.accept("arrow_down-up", self.setKey, ["down",0])
            
            self.accept("s", self.check_button_press, ['A'])
            self.accept("d", self.check_button_press, ['B'])
            self.accept("a", self.check_button_press, ['C'])
            self.accept("w", self.check_button_press, ['D'])

            self.accept("joy-button", self.check_button_press)
        
        self.accept("music-finished", self.end)
        self.accept("escape", self.end)
        self.accept("wii-out", self.end)
        
    
    def setup_rings(self):
        ring_parsed_info = parse.level_rings(self.info["NAME"], self.difficulty)
        
        self.ring_list = []
        for pos, beat, button in ring_parsed_info:
            ring = loader.loadModelCopy("./models/ring")
            ring.setName('ring%d'%beat)
            #ring.setScale(0.8, 0.8, 0.8)
            
            tex = loader.loadTexture('./image/envmap.jpg')
            ring.setTexGen(TextureStage.getDefault(), TexGenAttrib.MEyeSphereMap)
            ring.setTexture(tex)
            
            ringY = beat*self.RING_SPACING_PER_BEAT
            self.btn_viewer.append_button(button, beat)
            
            ring.setX(pos[0]*self.FLY_AREA_W)
            ring.setZ(pos[1]*self.FLY_AREA_H)
            
            color = None
            
            if button == 'A':
                color = (.4, .44, .81, 1)
            elif button == 'B':
                color = (1, .3, .3, 1)
            elif button == 'C':
                color = (.99, .0, 1, 1)
            elif button == 'D':
                color = (.39, 1, .62, 1)
            
            ring.setY(ringY)
            ring.reparentTo(self.rootNode)
            ring.setColor(VBase4(*color))

            self.ring_list.append({"node":ring, "time":beat*self.BEAT_DELAY, "button":button, "cleared": False})#+adjust, "button":button, "cleared": False})
        
        ring = self.ring_list[0]["node"]
        
        self.ring_radius = ring.node().getBounds().getRadius()
                
        self.n_rings = len(self.ring_list)
    
    def setKey(self, key, value):
        self.button_map[key] = value
    
    def play(self):
        self.music.play()
        self.title_msg = gui.TitleMessage(self.info["TITLE"], "by %s" % self.info["ARTIST"])
        
        self.task_list = [name for name in self.__class__.__dict__.keys() if name.startswith("ctask_")]
        
        for task in self.task_list:
            taskMgr.add(getattr(self, task), task)
    def calculate_rank(self, stats, n):
        rates = {
            "PERFECT": float(stats['PERFECT']) / float(n),
            "GOOD": float(stats['GOOD']) / float(n),
            "OK" : float(stats['OK']) / float(n),
            "BAD" : float(stats['BAD']) / float(n),
            "MISS": float(stats['MISS']) / float(n)
        }
        
        if( rates['MISS'] <= 0 and rates['BAD'] <= 0.1 and rates['PERFECT'] >=0.5):
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

    def ctask_moveChar(self, task):
        music_time = self.music.getTime()
        if music_time > 20:
            #print music_time, self.bunnyActor.getY(), self.bunnyActor.getX()
            self.title_msg.clear()

        if (task.time - self.bunnyActor.last_update) > self.CONTROL_UPDATE_DELAY:
            s_x = self.button_map.get_axis(0)*self.SPEED_SCALE
            s_z = self.button_map.get_axis(1)*self.SPEED_SCALE*self.y_signal
            
            if s_x > 0:
                self.bunnyActor.setR(-15)
                if self.bunnyActor.getCurrentAnim() != "turn-right":
                    self.bunnyActor.loop("turn-right")
            elif s_x < 0:
                self.bunnyActor.setR(15)
                if self.bunnyActor.getCurrentAnim() != "turn-left":
                    self.bunnyActor.loop("turn-left")
            else:
                self.bunnyActor.setR(0)
            
            if s_z > 0:
                self.bunnyActor.setP(-10)
                if self.bunnyActor.getCurrentAnim() != "rise":
                    self.bunnyActor.loop("rise")
            elif s_z < 0:
                self.bunnyActor.setP(+10)
                if self.bunnyActor.getCurrentAnim() != "dive":
                    self.bunnyActor.loop("dive")
            else:
                self.bunnyActor.setP(0)

            if s_z == 0 and s_x == 0:
                if self.bunnyActor.getCurrentAnim() != "fly":
                    self.bunnyActor.loop("fly")

            #controles
            if self.bool_mouse:
                self.control_mouse()
            elif self.bool_wiimote:
                if self.bool_wiimote_ir:
                    self.control_wiimote_ir()
                else:
                    self.control_wiimote_acc()
            
            else:
                self.bunnyActor.setX(clamp(self.FLY_AREA_L, self.bunnyActor.getX() + s_x, self.FLY_AREA_R))
                self.bunnyActor.setZ(clamp(self.FLY_AREA_B, self.bunnyActor.getZ() + s_z, self.FLY_AREA_T))
                
            self.bunnyActor.last_update = task.time
        
        
        bunny_pos = time2pos(music_time, self.BEAT_DELAY, self.RING_SPACING_PER_BEAT)
        self.bunnyActor.setY(bunny_pos)
        self.btn_viewer.update(music_time)
        
        self.camera.setY(self.bunnyActor.getY() - self.camera_offset)
        self.skybox.setY(self.bunnyActor.getY())

        return Task.cont

    

    #Rotina para controle de movimento com o Mouse
    def control_mouse(self):
        x = base.win.getPointer(0).getX()
        y = base.win.getPointer(0).getY()
        
        mouse_factor = 240.0

        pos_x = x/mouse_factor + self.FLY_AREA_L
        if pos_x > self.FLY_AREA_R:
            pos_x = self.FLY_AREA_R
            x = (pos_x - self.FLY_AREA_L)*mouse_factor
            self.x_old = x   
        elif pos_x < self.FLY_AREA_L:
            pos_x = self.FLY_AREA_L
            x = (pos_x - self.FLY_AREA_L)*mouse_factor
            self.x_old = x   
        self.bunnyActor.setX(pos_x)
        
        mv_x = abs(x - self.x_old)
        mv_y = abs(y - self.y_old)        
        
        move_x = move_y = True
        
        #animacao
        if x < self.x_old:
            if self.mvs.move_char_x(mv_x):
                self.mvs.add(1)
                if self.mvs.do_movement(1):
                    self.bunnyActor.setR(15)
                    if self.bunnyActor.getCurrentAnim() != "turn-left":
                        self.bunnyActor.loop("turn-left")
                self.bunnyActor.setX(pos_x)
                self.x_old = x
            else:
                move_x = False
        
        elif x > self.x_old:
            if self.mvs.move_char_x(mv_x):
                self.mvs.add(2)
                if self.mvs.do_movement(2):
                    self.bunnyActor.setR(-15)
                    if self.bunnyActor.getCurrentAnim() != "turn-right":
                        self.bunnyActor.loop("turn-right")
                self.bunnyActor.setX(pos_x)
                self.x_old = x   
            else:
                move_x = False
        
        pos_z = -(y/mouse_factor + self.FLY_AREA_B)                
        #pos_z = y/mouse_factor + self.FLY_AREA_B                
        if pos_z > self.FLY_AREA_T:
            pos_z = self.FLY_AREA_T
            y = (-pos_z - self.FLY_AREA_B)*mouse_factor
            self.y_old = y
        if pos_z < self.FLY_AREA_B:
            pos_z = self.FLY_AREA_B
            y = (-pos_z - self.FLY_AREA_B)*mouse_factor
            self.y_old = y
        self.bunnyActor.setZ(pos_z)
        
        #animacao
        if y < self.y_old:
            if self.mvs.move_char_y(mv_y):
                self.mvs.add(3)
                if self.mvs.do_movement(3):
                    self.bunnyActor.setP(-10)
                    if self.bunnyActor.getCurrentAnim() != "rise":
                        self.bunnyActor.loop("rise")
                self.bunnyActor.setZ(pos_z)
                self.y_old = y
            else:
                move_y = False
            
        elif y > self.y_old:
            if self.mvs.move_char_y(mv_y):
                self.mvs.add(4)
                if self.mvs.do_movement(4):
                    self.bunnyActor.setP(+10)
                    if self.bunnyActor.getCurrentAnim() != "dive":
                        self.bunnyActor.loop("dive")
                self.bunnyActor.setZ(pos_z)
                self.y_old = y
            else:
                move_y = False
                
        if not move_x and not move_y:
            base.win.movePointer(0, int(self.x_old), int(self.y_old))

    #######################################################
    # ROTINAS PARA CONTROLE COM WIIMOTE USANDO APENAS OS ACELEROMETROS #
    #######################################################
    
    def calcula_movimento_acc_x(self, acc_norm):
        if abs(acc_norm[cwiid.X]) <= 1.0:
            angulo = math.acos(acc_norm[cwiid.X])
            graus = math.degrees(angulo)
            if graus > 100:
                delta = angulo/2.2
            elif graus < 80:
                delta = -(2.2 - angulo)/2.2
            else:
                delta = 0
            
            return delta
        else:
            return 0

    def calcula_movimento_acc_y(self, acc_norm):
        if abs(acc_norm[cwiid.Y]) <= 1.0:
            angulo = math.acos(acc_norm[cwiid.Y])
            graus = math.degrees(angulo)
            if graus > 95:
                delta = -angulo/2.2
            elif graus < 85:
                delta = (2.2 - angulo)/2.2
            else:
                delta = 0
            
            return delta
        else:
            return 0
    
    def control_wiimote_acc(self):
        if self.first:
            x = 410
            y = 380
            self.first = False
        else:
            x = self.x_old
            y = self.y_old

        refinador = 18
        
        acc_norm = norm(self.wm.state['acc'], self.cal)
        
        x += self.calcula_movimento_acc_x(acc_norm)*refinador
        y += self.calcula_movimento_acc_y(acc_norm)*refinador
        
        wii_factor = 280.0
        
        #teste wiimote
        pos_x = -(x/wii_factor + self.FLY_AREA_L)
        if pos_x > self.FLY_AREA_R:
            pos_x = self.FLY_AREA_R
            x = (-pos_x - self.FLY_AREA_L)*wii_factor
        elif pos_x < self.FLY_AREA_L:
            pos_x = self.FLY_AREA_L
            x = (-pos_x - self.FLY_AREA_L)*wii_factor
        self.bunnyActor.setX(pos_x)
        #print pos_x

        #teste wiimote - animacao
        mv_x = abs(x - self.x_old)
        mv_y = abs(y - self.y_old)        
        
        move_x = move_y = True
        acc_norm = norm(self.wm.state['acc'], self.cal)

        if abs(acc_norm[cwiid.X]) <= 1.0:
            angulo = math.acos(acc_norm[cwiid.X])
            self.angle_R = math.degrees(angulo)
            #print self.angle_R

        if abs(acc_norm[cwiid.Y]) <= 1.0:
            angulo = math.acos(acc_norm[cwiid.Y])
            self.angle_P = math.degrees(angulo)
            #print self.angle_P

        #animacao
        if x > self.x_old:
            if self.mvs.move_char_x(mv_x):
                self.mvs.add(1)
                if self.mvs.do_movement(1):
                    if self.bunnyActor.getCurrentAnim() != "turn-left":
                        self.bunnyActor.loop("turn-left")
                self.bunnyActor.setX(pos_x)
                self.x_old = x
            else:
                move_x = False
        
        elif x < self.x_old:
            if self.mvs.move_char_x(mv_x):
                self.mvs.add(2)
                if self.mvs.do_movement(2):
                    if self.bunnyActor.getCurrentAnim() != "turn-right":
                        self.bunnyActor.loop("turn-right")
                self.bunnyActor.setX(pos_x)
                self.x_old = x   
            else:
                move_x = False
        
        #teste wiimote
        pos_z = -(y/wii_factor + self.FLY_AREA_B)                
        if pos_z > self.FLY_AREA_T:
            pos_z = self.FLY_AREA_T
            y = (-pos_z - self.FLY_AREA_B)*wii_factor
        if pos_z < self.FLY_AREA_B:
            pos_z = self.FLY_AREA_B
            y = (-pos_z - self.FLY_AREA_B)*wii_factor
        self.bunnyActor.setZ(pos_z)


        #animacao
        if y < self.y_old:
            if self.mvs.move_char_y(mv_y):
                self.mvs.add(3)
                if self.mvs.do_movement(3):
                    if self.bunnyActor.getCurrentAnim() != "rise":
                        self.bunnyActor.loop("rise")
                self.bunnyActor.setZ(pos_z)
                self.y_old = y
            else:
                move_y = False
            
            
        elif y > self.y_old:
            if self.mvs.move_char_y(mv_y):
                self.mvs.add(4)
                if self.mvs.do_movement(4):
                    if self.bunnyActor.getCurrentAnim() != "dive":
                        self.bunnyActor.loop("dive")
                self.bunnyActor.setZ(pos_z)
                self.y_old = y
            else:
                move_y = False
                
        if not move_x and not move_y:
            base.win.movePointer(0, int(self.x_old), int(self.y_old))
        
        self.bunnyActor.setR(-(90 - self.angle_R))
        self.bunnyActor.setP(90 - self.angle_P)

    ##########################################
    # ROTINAS PARA CONTROLE COM WIIMOTE USANDO VISAO IR  #
    ##########################################

    def control_wiimote_ir(self):
        x = self.x_old
        y = self.y_old

        try:
            if self.wm.state['ir_src'][0]['pos']:
                x = self.wm.state['ir_src'][0]['pos'][0]
                y = self.wm.state['ir_src'][0]['pos'][1]
                #print 'X = ', pos_x, '| Y = ', pos_y
        except:
            #print "fora daea"
            pass
        
        wii_factor = 300.0

        #teste wiimote
        pos_x = -(x/wii_factor + self.FLY_AREA_L)
        if pos_x > self.FLY_AREA_R:
            pos_x = self.FLY_AREA_R
            x = (-pos_x - self.FLY_AREA_L)*wii_factor
            self.x_old = x
        elif pos_x < self.FLY_AREA_L:
            pos_x = self.FLY_AREA_L
            x = (-pos_x - self.FLY_AREA_L)*wii_factor
            self.x_old = x
        self.bunnyActor.setX(pos_x)

        #teste wiimote - animacao
        mv_x = abs(x - self.x_old)
        mv_y = abs(y - self.y_old)        
        
        move_x = move_y = True
        acc_norm = norm(self.wm.state['acc'], self.cal)

        if abs(acc_norm[cwiid.X]) <= 1.0:
            angulo = math.acos(acc_norm[cwiid.X])
            self.angle_R = math.degrees(angulo)
            #print self.angle_R

        if abs(acc_norm[cwiid.Y]) <= 1.0:
            angulo = math.acos(acc_norm[cwiid.Y])
            self.angle_P = math.degrees(angulo)
            #print self.angle_P
        
        #animacao
        if x > self.x_old:
            if self.mvs.move_char_x(mv_x):
                self.mvs.add(1)
                if self.mvs.do_movement(1):
                    #self.bunnyActor.setR(angle_left)
                    if self.bunnyActor.getCurrentAnim() != "turn-left":
                        self.bunnyActor.loop("turn-left")
                self.bunnyActor.setX(pos_x)
                self.x_old = x
            else:
                move_x = False
        
        elif x < self.x_old:
            if self.mvs.move_char_x(mv_x):
                self.mvs.add(2)
                if self.mvs.do_movement(2):
                    #self.bunnyActor.setR(angle_right)
                    if self.bunnyActor.getCurrentAnim() != "turn-right":
                        self.bunnyActor.loop("turn-right")
                self.bunnyActor.setX(pos_x)
                self.x_old = x   
            else:
                move_x = False
        
        #teste wiimote
        pos_z = -(y/wii_factor + self.FLY_AREA_B)                
        #pos_z = y/wii_factor + self.FLY_AREA_B                
        if pos_z > self.FLY_AREA_T:
            pos_z = self.FLY_AREA_T
            y = (-pos_z - self.FLY_AREA_B)*wii_factor
            self.y_old = y
        if pos_z < self.FLY_AREA_B:
            pos_z = self.FLY_AREA_B
            y = (-pos_z - self.FLY_AREA_B)*wii_factor
            self.y_old = y
        self.bunnyActor.setZ(pos_z)

        #animacao
        if y < self.y_old:
            if self.mvs.move_char_y(mv_y):
                self.mvs.add(3)
                if self.mvs.do_movement(3):
                    #self.bunnyActor.setP(-10)
                    if self.bunnyActor.getCurrentAnim() != "rise":
                        self.bunnyActor.loop("rise")
                self.bunnyActor.setZ(pos_z)
                self.y_old = y
            else:
                move_y = False
            
            
        elif y > self.y_old:
            if self.mvs.move_char_y(mv_y):
                self.mvs.add(4)
                if self.mvs.do_movement(4):
                    #self.bunnyActor.setP(+10)
                    if self.bunnyActor.getCurrentAnim() != "dive":
                        self.bunnyActor.loop("dive")
                self.bunnyActor.setZ(pos_z)
                self.y_old = y
            else:
                move_y = False
                
        if not move_x and not move_y:
            base.win.movePointer(0, int(self.x_old), int(self.y_old))
        
        self.bunnyActor.setR(-(90 - self.angle_R))
        self.bunnyActor.setP(90 - self.angle_P)



    def ctask_terrainPatch(self, task):
        closest_patch = self.terrain_patch_list[0]
        
        if camera.getPos().getY() > closest_patch.node().getBounds().getCenter().getY() + closest_patch.node().getBounds().getRadius():
            last_patch = self.terrain_patch_list[-1]
            closest_patch.setY(last_patch.getPos().getY() + self.terrain_patch_size -0.1)
            
            self.terrain_patch_list.append(self.terrain_patch_list.pop(0))
            
        return Task.cont
    
    def ctask_checkNextRing(self, task):
        pos = self.music.getTime()
        
        if uses_wii(self.options):
            if self.bool_miss:
                if pos - self.miss_time >= 0.5:
                    self.wm.rumble = 0
                    self.bool_miss = False
                    #print "rumble off"
        
        if self.ring_list:
            ring = self.ring_list[0]
            
            if ring["time"] - pos < -0.11:
                if not ring["cleared"]:
                    self.miss_sound.play()
                    self.chain = 0
                    self.judgement_stats["MISS"] += 1
                    self.deco_mgr.judgement_msg("MISS", self.chain)
                    
                    ring_x = ring["node"].getX()
                    ring_z = ring["node"].getZ()

                    bunny_x = self.bunnyActor.getX()
                    bunny_z = self.bunnyActor.getZ()

                    ring_dist = math.sqrt((ring_x - bunny_x)**2 + (ring_z - bunny_z)**2)
                    
                    #rumble
                    if uses_wii(self.options):
                        self.bool_miss = True
                        self.wm.rumble = 1
                        self.miss_time = pos
                self.ring_list.pop(0)                
                
        return Task.cont
    
    def ctask_checkEnd(self, task):
        if self.music.status() == 1:
            messenger.send("music-finished")
        return Task.cont
    
    def end(self):
        if self.title_msg:
            self.title_msg.clear()
        self.rootNode.node().removeAllChildren()
        self.music.stop()
        
        if uses_wii(self.options):
            if self.bool_miss:
                self.wm.rumble = 0
        
        for t in self.task_list:
            taskMgr.remove(t)
        messenger.send("level-finished")
        
        self.ignoreAll()
                
    def check_button_press(self, button):        
        time = self.music.getTime()
        if self.ring_list:
            hit = False
            
            next_ring = self.ring_list[0]
            
            if not next_ring["cleared"]:
                time_dist = abs(next_ring["time"] - time)
                
                ring_x = next_ring["node"].getX()
                ring_z = next_ring["node"].getZ()
                
                bunny_x = self.bunnyActor.getX()
                bunny_z = self.bunnyActor.getZ()
                
                ring_dist = math.sqrt((ring_x - bunny_x)**2 + (ring_z - bunny_z)**2)
                
                for s in self.score_list:
                    if time_dist < s:
                        hit = True
                        judgement = self.precision_judge[s]
                        break
                
                if hit:
                    next_ring["cleared"] = True
                    if judgement in ["PERFECT", "GOOD", "OK"]:
                        self.chain += 1
                        #teste para verificar posicao na musica
                        #print self.bunnyActor.getY()
                    elif judgement in ["BAD", "MISS"]:
                        self.chain = 0

                    if ring_dist > self.ring_radius or button != next_ring["button"]:
                        judgement = "MISS"
                        self.chain = 0

                    score = self.score_map[judgement]
                    if score > 0:
                        self.score += score + int(self.chain*0.02*score)
                        self.score_display.update(self.score)
                        
                        self.btn_viewer.button_hit()
                        
                    if judgement == 'MISS':
                        self.miss_sound.play()
                        if uses_wii(self.options):
                            self.bool_miss = True
                            self.wm.rumble = 1
                            self.miss_time = time
                            
                    self.judgement_stats[judgement] += 1
                    self.deco_mgr.judgement_msg(judgement, self.chain)

class ButtonMap:
    def __init__(self, options, j_id=0, wm=None, b_nunc = False):
        self.options = options
        
        self.wii = False
        if wm:
            self.wm = wm
            self.wii = True
        
        if self.options.get('game-opts', 'controller') == 'Joypad':
            self.mode = 'joy'
        elif self.options.get('game-opts', 'controller') == 'Mouse':
            self.mode = 'mouse'
        elif self.options.get('game-opts', 'controller') == 'Wiimote' or self.options.get('game-opts', 'controller') == 'Wiimote IR':
            self.mode = 'wiimote'
        elif uses_nunchuk(self.options):
            if b_nunc:
                self.mode = 'wiimote'
            else:
                self.mode = 'nunchuk'
        else:
            self.mode = 'key'
        
        if self.mode == 'joy':
            pygame.init()
            pygame.joystick.init()
            print(pygame.joystick)
        
            try:
                if self.mode == "joy":
                    self.joy = pygame.joystick.Joystick(j_id)
                    self.joy.init()
                
                    taskMgr.add(self.ctask_JoyEvent, "joy-event")
            except pygame.error as e:
                print(e)
                self.mode = 'key'
        
        elif self.wii and self.mode == 'wiimote':
            taskMgr.add(self.ctask_WiiEvent, "wii-event")
        elif self.wii and self.mode == 'nunchuk':
            taskMgr.add(self.ctask_NunchukEvent, "nunchuk-event")

        self.buttons = {
            "left":0,
            "right":0,
            "up":0,
            "down":0
        }
            
    def setMode(self, mode):
        self.mode = mode
        
    def __setitem__(self, key, value):
        self.buttons[key] = value
        
    def get_axis(self, axis):
        if self.mode != 'joy':
            value = .0
            if axis == 0:
                if self.buttons["left"]:
                    value = -1.0
                elif self.buttons["right"]:
                    value = 1.0
            elif axis == 1:
                if self.buttons["down"]:
                    value = 1.0
                elif self.buttons["up"]:
                    value = -1.0
            
            return value
            
        elif self.mode == "joy":
            return self.joy.get_axis(axis)
        
    def ctask_JoyEvent(self, task):
        pygame.event.pump()
        
        if self.joy.get_button(2): messenger.send("joy-button", ["A"])
        if self.joy.get_button(1): messenger.send("joy-button", ["B"])
        if self.joy.get_button(3): messenger.send("joy-button", ["C"])
        if self.joy.get_button(0): messenger.send("joy-button", ["D"])
            
        return Task.cont

    def ctask_WiiEvent(self, task):
        #mapeamento dos botoes para o direcional do wiimote
        #Quadrado
        if self.wm.state['buttons'] == cwiid.BTN_LEFT: 
            messenger.send("wii-button", ["C"])
        
        #Xis
        if self.wm.state['buttons'] == cwiid.BTN_DOWN:
            messenger.send("wii-button", ["A"])
            
        #Circulo
        if self.wm.state['buttons'] == cwiid.BTN_RIGHT:
            messenger.send("wii-button", ["B"])
        
        #Triangulo
        if self.wm.state['buttons'] == cwiid.BTN_UP:
            messenger.send("wii-button", ["D"])

        if self.wm.state['buttons'] == cwiid.BTN_HOME:
            messenger.send("wii-out")
        
        return Task.cont

    def ctask_NunchukEvent(self, task):
        #mapeamento dos botoes para o direcional do wiimote
        #Quadrado
        try:
            if self.wm.state['nunchuk']['stick'][0] < 50: 
                messenger.send("nunchuk-button", ["C"])
            
            #Xis
            elif self.wm.state['nunchuk']['stick'][1] < 50: 
                messenger.send("nunchuk-button", ["A"])
                
            #Circulo
            elif self.wm.state['nunchuk']['stick'][0] >200: 
                messenger.send("nunchuk-button", ["B"])
                
            #Triangulo
            elif self.wm.state['nunchuk']['stick'][1] > 200: 
                messenger.send("nunchuk-button", ["D"])

        except KeyError:
            pass
        
        if self.wm.state['buttons'] == cwiid.BTN_HOME:
            messenger.send("wii-out")

        return Task.cont
