#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Compatibility wrapper to make wiiuse work with cwiid-based code.
This allows the original MoonBunny cwiid code to work with the modern wiiuse library.
"""

import wiiuse
import time
import threading

# cwiid constants mapped to wiiuse equivalents
LED1_ON = wiiuse.LED_1
LED2_ON = wiiuse.LED_2
LED3_ON = wiiuse.LED_3
LED4_ON = wiiuse.LED_4

# Button constants
BTN_A = 0x0008
BTN_B = 0x0004
BTN_UP = 0x0800
BTN_DOWN = 0x0400
BTN_LEFT = 0x0100
BTN_RIGHT = 0x0200
BTN_HOME = 0x0080
BTN_PLUS = 0x1000
BTN_MINUS = 0x0010
BTN_1 = 0x0002
BTN_2 = 0x0001

# Report mode constants
RPT_BTN = 0x01
RPT_ACC = 0x02
RPT_IR = 0x04
RPT_NUNCHUK = 0x08

# Extension constants
EXT_NONE = 0
EXT_NUNCHUK = 1
EXT_CLASSIC = 2

# Axis constants for accelerometer
X = 0
Y = 1
Z = 2

class WiimoteState:
    """Mimics cwiid's wiimote state structure"""
    def __init__(self):
        self.buttons = 0
        self.acc = [0, 0, 0]
        self.ir_src = []
        self.nunchuk = {
            'stick': [128, 128],
            'acc': [0, 0, 0],
            'buttons': 0
        }

class Wiimote:
    """Compatibility wrapper for wiiuse that mimics cwiid.Wiimote"""
    
    def __init__(self, bdaddr=None):
        """Initialize Wiimote connection"""
        self.bdaddr = bdaddr
        self.wiimotes = None
        self.wiimote = None
        self.state = WiimoteState()
        self.led = 0
        self.rpt_mode = RPT_BTN
        self._running = False
        self._thread = None
        
        # Initialize wiiuse
        self.wiimotes = wiiuse.init(1)  # Support 1 wiimote
        if not self.wiimotes:
            raise RuntimeError("Failed to initialize wiiuse")
        
        # Find and connect to wiimotes
        found = wiiuse.find(self.wiimotes, 1, 5)  # Find 1 wiimote, 5 second timeout
        if found == 0:
            raise RuntimeError("No Wiimotes found")
        
        connected = wiiuse.connect(self.wiimotes, 1)
        if connected == 0:
            raise RuntimeError("Failed to connect to Wiimote")
        
        self.wiimote = self.wiimotes[0]
        
        # Set default settings
        wiiuse.set_leds(self.wiimote, wiiuse.LED_1)
        wiiuse.set_flags(self.wiimote, wiiuse.INIT_FLAGS, 0)
        wiiuse.motion_sensing(self.wiimote, 1)
        
        # Start polling thread
        self._running = True
        self._thread = threading.Thread(target=self._poll_loop)
        self._thread.daemon = True
        self._thread.start()
    
    def _poll_loop(self):
        """Continuously poll the wiimote for state updates"""
        while self._running:
            if wiiuse.poll(self.wiimotes, 1):
                self._update_state()
            time.sleep(0.01)  # 100Hz polling
    
    def _update_state(self):
        """Update the state object with current wiimote data"""
        if not self.wiimote:
            return
        
        # Update button state
        self.state.buttons = 0
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.A):
            self.state.buttons |= BTN_A
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.B):
            self.state.buttons |= BTN_B
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.Up):
            self.state.buttons |= BTN_UP
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.Down):
            self.state.buttons |= BTN_DOWN
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.Left):
            self.state.buttons |= BTN_LEFT
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.Right):
            self.state.buttons |= BTN_RIGHT
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.Home):
            self.state.buttons |= BTN_HOME
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.Plus):
            self.state.buttons |= BTN_PLUS
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.Minus):
            self.state.buttons |= BTN_MINUS
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.One):
            self.state.buttons |= BTN_1
        if wiiuse.is_pressed(self.wiimote, wiiuse.button.Two):
            self.state.buttons |= BTN_2
        
        # Update accelerometer data
        if hasattr(self.wiimote.contents, 'accel'):
            self.state.acc[X] = self.wiimote.contents.accel.x
            self.state.acc[Y] = self.wiimote.contents.accel.y
            self.state.acc[Z] = self.wiimote.contents.accel.z
        
        # Update nunchuk data if connected
        if hasattr(self.wiimote.contents, 'exp') and self.wiimote.contents.exp.type == wiiuse.EXP_NUNCHUK:
            nunchuk = self.wiimote.contents.exp.nunchuk
            self.state.nunchuk['stick'][0] = nunchuk.js.x
            self.state.nunchuk['stick'][1] = nunchuk.js.y
            self.state.nunchuk['acc'][X] = nunchuk.accel.x
            self.state.nunchuk['acc'][Y] = nunchuk.accel.y
            self.state.nunchuk['acc'][Z] = nunchuk.accel.z
            
            # Nunchuk buttons
            self.state.nunchuk['buttons'] = 0
            if wiiuse.is_pressed(self.wiimote, wiiuse.nunchuk_button.C):
                self.state.nunchuk['buttons'] |= 0x02
            if wiiuse.is_pressed(self.wiimote, wiiuse.nunchuk_button.Z):
                self.state.nunchuk['buttons'] |= 0x01
    
    def get_acc_cal(self, ext_type):
        """Get accelerometer calibration data"""
        # Return default calibration values
        # In a real implementation, you'd get these from the wiimote
        return ([120, 120, 120], [220, 220, 220])
    
    def close(self):
        """Close the wiimote connection"""
        self._running = False
        if self._thread:
            self._thread.join()
        if self.wiimotes:
            wiiuse.disconnect(self.wiimotes[0])
    
    def __del__(self):
        """Cleanup when object is destroyed"""
        self.close()

# Module-level functions to mimic cwiid API
def find_wiimote(timeout=5):
    """Find available wiimotes"""
    wiimotes = wiiuse.init(1)
    if not wiimotes:
        return []
    
    found = wiiuse.find(wiimotes, 1, timeout)
    if found > 0:
        return [None]  # Return a dummy address since wiiuse handles connection differently
    return []
