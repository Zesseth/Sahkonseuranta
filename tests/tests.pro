# SPDX-License-Identifier: AGPL-3.0-or-later
TEMPLATE = app
TARGET = pricefetcher_test

QT += core network

SOURCES += pricefetcher_test.cpp \
          ../src/pricefetcher.cpp

HEADERS += ../src/pricefetcher.h

INCLUDEPATH += ../src
DEPENDPATH += ../src

MOC_DIR = .moc
OBJECTS_DIR = .obj
