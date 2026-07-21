ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MartinsBypass
MartinsBypass_FILES = Tweak.xm
MartinsBypass_CFLAGS = -fobjc-arc
MartinsBypass_FRAMEWORKS = UIKit Foundation

include $(THEOS)/makefiles/tweak.mk
