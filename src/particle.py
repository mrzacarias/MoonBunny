#!/usr/bin/env python
# -*- coding: utf-8 -*-

from direct.particles.ParticleEffect import ParticleEffect
from direct.particles.Particles import Particles
from direct.particles.ForceGroup import ForceGroup
from panda3d.core import *
from panda3d.physics import BaseParticleRenderer, BaseParticleEmitter
from direct.interval.MetaInterval import Sequence
from direct.interval.FunctionInterval import Func
from direct.particles.ParticleEffect import ParticleEffect

class BunnyParticles(ParticleEffect):
    def __init__(self):
        ParticleEffect.__init__(self)

        self.reset()
        self.setPos(0.000, 0.000, 0.000)
        self.setHpr(0.000, 0.000, 0.000)
        self.setScale(1.000, 1.000, 1.000)
        p0 = Particles('particles-1')
        # Particles parameters
        p0.setFactory("PointParticleFactory")
        p0.setRenderer("SpriteParticleRenderer")
        p0.setEmitter("SphereVolumeEmitter")
        p0.setPoolSize(1024)
        p0.setBirthRate(0.0200)
        p0.setLitterSize(1)
        p0.setLitterSpread(0)
        p0.setSystemLifespan(0.0000)
        p0.setLocalVelocityFlag(1)
        p0.setSystemGrowsOlderFlag(0)
        # Factory parameters
        p0.factory.setLifespanBase(3.0000)
        p0.factory.setLifespanSpread(0.0000)
        p0.factory.setMassBase(1.0000)
        p0.factory.setMassSpread(0.0000)
        p0.factory.setTerminalVelocityBase(400.0000)
        p0.factory.setTerminalVelocitySpread(0.0000)
        # Point factory parameters
        # Renderer parameters
        p0.renderer.setAlphaMode(BaseParticleRenderer.PRALPHAUSER)
        p0.renderer.setUserAlpha(1.00)
        # Sprite parameters
        p0.renderer.addTextureFromFile('./image/particle.png')
        p0.renderer.setColor(Vec4(0.40, 0.40, 1.00, 0.50))
        p0.renderer.setXScaleFlag(0)
        p0.renderer.setYScaleFlag(0)
        p0.renderer.setAnimAngleFlag(0)
        p0.renderer.setInitialXScale(0.03000)
        p0.renderer.setFinalXScale(1.0000)
        p0.renderer.setInitialYScale(0.03000)
        p0.renderer.setFinalYScale(1.0000)
        p0.renderer.setNonanimatedTheta(0.0000)
        p0.renderer.setAlphaBlendMethod(BaseParticleRenderer.PPBLENDLINEAR)
        p0.renderer.setAlphaDisable(0)
        # Emitter parameters
        p0.emitter.setEmissionType(BaseParticleEmitter.ETRADIATE)
        p0.emitter.setAmplitude(0.5000)
        p0.emitter.setAmplitudeSpread(0.0000)
        p0.emitter.setOffsetForce(Vec3(0.0000, 0.0000, 0.0000))
        p0.emitter.setExplicitLaunchVector(Vec3(1.0000, 0.0000, 0.0000))
        p0.emitter.setRadiateOrigin(Point3(0.0000, 0.0000, 0.0000))
        # Sphere Volume parameters
        p0.emitter.setRadius(0.0100)
        self.addParticles(p0)
        f0 = ForceGroup('force-1')
        # Force parameters
        force0 = LinearVectorForce(Vec3(0.0000, 0.0000, -1.0000), 3.0000, 0)
        force0.setVectorMasks(1, 1, 1)
        force0.setActive(1)
        f0.addForce(force0)
        self.addForceGroup(f0)

class StarParticles(ParticleEffect):
    def __init__(self):
        ParticleEffect.__init__(self)
        
        self.reset()
        self.setPos(0.000, 0.000, 0.000)
        self.setHpr(0.000, 0.000, 0.000)
        self.setScale(1.000, 1.000, 1.000)
        p0 = Particles('particles-1')
        # Particles parameters
        p0.setFactory("ZSpinParticleFactory")
        p0.setRenderer("SpriteParticleRenderer")
        p0.setEmitter("LineEmitter")
        p0.setPoolSize(1024)
        p0.setBirthRate(0.3000)
        p0.setLitterSize(1)
        p0.setLitterSpread(0)
        p0.setSystemLifespan(0.0000)
        p0.setLocalVelocityFlag(0)
        p0.setSystemGrowsOlderFlag(0)
        # Factory parameters
        p0.factory.setLifespanBase(15.0000)
        p0.factory.setLifespanSpread(0.0000)
        p0.factory.setMassBase(1.0000)
        p0.factory.setMassSpread(0.0000)
        p0.factory.setTerminalVelocityBase(400.0000)
        p0.factory.setTerminalVelocitySpread(0.0000)
        # Z Spin factory parameters
        p0.factory.setInitialAngle(0.0000)
        p0.factory.setInitialAngleSpread(0.0000)
        p0.factory.enableAngularVelocity(1)
        p0.factory.setAngularVelocity(60.0000)
        p0.factory.setAngularVelocitySpread(10.0000)
        # Renderer parameters
        p0.renderer.setAlphaMode(BaseParticleRenderer.PRALPHAUSER)
        p0.renderer.setUserAlpha(0.20)
        # Sprite parameters
        p0.renderer.addTextureFromFile('./image/star_particle.png')
        p0.renderer.setColor(Vec4(1.00, 1.00, 1.00, 1.00))
        p0.renderer.setXScaleFlag(0)
        p0.renderer.setYScaleFlag(0)
        p0.renderer.setAnimAngleFlag(1)
        p0.renderer.setInitialXScale(0.0500)
        p0.renderer.setInitialYScale(0.0500)
        p0.renderer.setNonanimatedTheta(0.0000)
        p0.renderer.setAlphaBlendMethod(BaseParticleRenderer.PPBLENDLINEAR)
        p0.renderer.setAlphaDisable(0)
        # Emitter parameters
        p0.emitter.setEmissionType(BaseParticleEmitter.ETEXPLICIT)
        p0.emitter.setAmplitude(0.1500)
        p0.emitter.setAmplitudeSpread(0.0500)
        p0.emitter.setOffsetForce(Vec3(0.0000, 0.0000, 0.0000))
        p0.emitter.setExplicitLaunchVector(Vec3(0.0000, 0.0000, -1.0000))
        p0.emitter.setRadiateOrigin(Point3(0.0000, 0.0000, 0.0000))
        # Line parameters
        p0.emitter.setEndpoint1(Point3(-1.0000, 0.0000, 0.0000))
        p0.emitter.setEndpoint2(Point3(1.0000, 0.0000, 0.0000))
        self.addParticles(p0)
