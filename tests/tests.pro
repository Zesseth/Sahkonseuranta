TEMPLATE = app
TARGET = pricefetcher_test

QT += core network

SOURCES += pricefetcher_test.cpp \
          ../src/pricefetcher.cpp

HEADERS += ../src/pricefetcher.h

INCLUDEPATH += ../src
DEPENDPATH += ../src
<<<<<<< HEAD

# MOC asetukset
MOC_DIR = .moc
OBJECTS_DIR = .obj

# Qt moduulit
LIBS += -lQt5Core -lQt5Network
=======
>>>>>>> vibe/sahkonseuranta-mvp
