find_package(Qt6Test ${QT_MIN_VERSION} REQUIRED)

# The CachyOS.UI design system provides the shared layout auditor.
list(APPEND CMAKE_PREFIX_PATH "$ENV{HOME}/.local" "/usr/local")
find_package(CachyOSUITesting REQUIRED)

add_executable(test_livecaptions test_livecaptions.cpp)
target_compile_definitions(test_livecaptions PRIVATE KLIVECAPTIONS_SOURCE_DIR="${CMAKE_SOURCE_DIR}")
target_link_libraries(test_livecaptions PRIVATE
    klivecaptions_core
    Qt6::Core
    Qt6::Qml
    Qt6::Test
)

add_test(NAME test_livecaptions COMMAND test_livecaptions)

# ---------------------------------------------------------------------------
# Golden Gate layout audit: renders the real QML scene offscreen and asserts
# that no item protrudes, gets clipped or overlaps another one.
# ---------------------------------------------------------------------------
add_executable(test_layout_audit
    test_layout_audit.cpp
    ../src/livecaptionengine.cpp
    ../src/livecaptionengine.h
    ../src/resources.qrc
)

target_include_directories(test_layout_audit PRIVATE ../src)
target_link_libraries(test_layout_audit PRIVATE
    klivecaptions_core
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Test
    CachyOSUITesting::CachyOSUITesting
)

add_test(NAME test_layout_audit COMMAND test_layout_audit)

set_tests_properties(test_layout_audit PROPERTIES
    ENVIRONMENT "CACHYOS_UI_IMPORT_PATH=$ENV{HOME}/.local/lib/qt6/qml"
)
