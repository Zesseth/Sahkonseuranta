TEMPLATE = app
TARGET = settings_test

QT += core

CONFIG += console
CONFIG -= app_bundle

SOURCES += settings_test.cpp \
          ../src/settings.cpp

HEADERS += ../src/settings.h

INCLUDEPATH += ../src
DEPENDPATH += ../src

MOC_DIR = .moc
OBJECTS_DIR = .obj
