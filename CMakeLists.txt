cmake_minimum_required(VERSION 3.16)

project(harbour-sahkonseuranta
    VERSION 1.0.0
    DESCRIPTION "Finnish electricity spot price tracker"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt5 5.6 REQUIRED COMPONENTS Core Gui Qml Quick Network)
include(FindPkgConfig)
pkg_search_module(SAILFISH sailfishapp REQUIRED)

add_executable(harbour-sahkonseuranta
    src/main.cpp
    src/pricefetcher.cpp
    src/settings.cpp)

target_include_directories(harbour-sahkonseuranta PRIVATE
    ${SAILFISH_INCLUDE_DIRS})

target_compile_definitions(harbour-sahkonseuranta PRIVATE
    APP_VERSION="${PROJECT_VERSION}")

target_link_libraries(harbour-sahkonseuranta
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::Network
    ${SAILFISH_LDFLAGS})

install(TARGETS harbour-sahkonseuranta DESTINATION bin)
install(DIRECTORY qml DESTINATION share/harbour-sahkonseuranta)
# The license must ship inside the app's own data directory; the Jolla
# Store validator rejects /usr/share/licenses and /usr/share/doc paths
install(FILES LICENSE DESTINATION share/harbour-sahkonseuranta)
install(FILES harbour-sahkonseuranta.desktop DESTINATION share/applications)
install(FILES icons/86x86/harbour-sahkonseuranta.png
    DESTINATION share/icons/hicolor/86x86/apps)
install(FILES icons/108x108/harbour-sahkonseuranta.png
    DESTINATION share/icons/hicolor/108x108/apps)
install(FILES icons/128x128/harbour-sahkonseuranta.png
    DESTINATION share/icons/hicolor/128x128/apps)
install(FILES icons/172x172/harbour-sahkonseuranta.png
    DESTINATION share/icons/hicolor/172x172/apps)
install(FILES icons/256x256/harbour-sahkonseuranta.png
    DESTINATION share/icons/hicolor/256x256/apps)
