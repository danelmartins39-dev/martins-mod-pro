ARCHS = arm64 arm64e
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MartinsMod

MartinsMod_FILES = Tweak.xm
MartinsMod_CFLAGS = -fobjc-arc
MartinsMod_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore

include $(THEOS)/makefiles/tweak.mk
