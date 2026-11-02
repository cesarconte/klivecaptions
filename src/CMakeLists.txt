add_library(klivecaptions_core STATIC
    livecaptionengine.cpp
    livecaptionengine.h
)

target_include_directories(klivecaptions_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(klivecaptions_core PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Network
)

add_executable(klivecaptions
    main.cpp
    resources.qrc
)

target_link_libraries(klivecaptions PRIVATE
    klivecaptions_core
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    KF6::CoreAddons
    KF6::I18n
)

install(TARGETS klivecaptions DESTINATION ${KDE_INSTALL_BINDIR})
install(FILES org.cesar.klivecaptions.desktop DESTINATION ${KDE_INSTALL_APPDIR})
