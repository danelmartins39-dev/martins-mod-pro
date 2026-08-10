ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LicenseManager
LicenseManager_FILES = LicenseManager.m
LicenseManager_CFLAGS = -fobjc-arc
LicenseManager_FRAMEWORKS = UIKit Foundation Security
LicenseManager_PRIVATE_FRAMEWORKS = CommonCrypto

include $(THEOS)/makefiles/tweak.mk
