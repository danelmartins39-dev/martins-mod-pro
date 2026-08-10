# Makefile para compilar a dylib do LicenseManager
# Compatível com Theos

ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = LicenseManager
LicenseManager_FILES = Sources/LicenseManager.m
LicenseManager_FRAMEWORKS = Foundation UIKit Security
LicenseManager_PRIVATE_FRAMEWORKS = CommonCrypto
LicenseManager_CFLAGS = -fobjc-arc
LicenseManager_LDFLAGS = -lSystem

include $(THEOS)/makefiles/framework.mk
