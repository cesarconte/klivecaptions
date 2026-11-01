find_package(Qt6Test ${QT_MIN_VERSION} REQUIRED)

add_executable(test_livecaptions test_livecaptions.cpp)
target_compile_definitions(test_livecaptions PRIVATE KLIVECAPTIONS_SOURCE_DIR="${CMAKE_SOURCE_DIR}")
target_link_libraries(test_livecaptions PRIVATE
    klivecaptions_core
    Qt6::Core
    Qt6::Qml
    Qt6::Test
)

add_test(NAME test_livecaptions COMMAND test_livecaptions)
