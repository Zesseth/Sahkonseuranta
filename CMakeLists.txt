cmake_minimum_required(VERSION 3.16)

project(harbour-sahkonseuranta
    VERSION 0.1.0
    DESCRIPTION "Sähkön pörssihinnan seuranta"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt5 5.6 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(SailfishApp 1.0 REQUIRED)

add_executable(harbour-sahkonseuranta
    src/main.cpp
    src/pricefetcher.cpp)

target_link_libraries(harbour-sahkonseuranta
    SailfishApp::SailfishApp
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick)

install(TARGETS harbour-sahkonseuranta DESTINATION bin)
install(DIRECTORY qml DESTINATION share/harbour-sahkonseuranta)
install(DIRECTORY icons DESTINATION share/harbour-sahkonseuranta)
