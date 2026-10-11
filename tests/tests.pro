TEMPLATE = app
TARGET = pricefetcher_test

QT += core network

SOURCES += pricefetcher_test.cpp \
          ../src/pricefetcher.cpp

HEADERS += ../src/pricefetcher.h

INCLUDEPATH += ../src
DEPENDPATH += ../src
