add_executable(intro main.cpp)

target_link_libraries(
  intro
  PRIVATE computational_modeling_visualized::computational_modeling_visualized_options
          computational_modeling_visualized::computational_modeling_visualized_warnings
          CLI11::CLI11
          fmt::fmt
          spdlog::spdlog
          lefticus::tools
          ftxui::screen
          ftxui::dom
          ftxui::component)


computational_modeling_visualized_configure_linker(intro)

target_include_directories(intro PRIVATE "${CMAKE_BINARY_DIR}/configured_files/include")

# Apply WASM-specific configuration
if(EMSCRIPTEN)
  computational_modeling_visualized_configure_wasm_target(intro
    TITLE "Intro - FTXUI Sample"
    DESCRIPTION "FTXUI-based terminal application"
  )
endif()
