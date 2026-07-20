ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MartinsMod
# Verifique se o nome do seu arquivo é Tweak.xm ou Martins_Mod_Final.xm e ajuste abaixo:
MartinsMod_FILES = Tweak.xm
MartinsMod_CFLAGS = -fobjc-arc
MartinsMod_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore

include $(THEOS)/makefiles/tweak.mk
