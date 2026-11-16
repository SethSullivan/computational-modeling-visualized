include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(computational_modeling_visualized_supports_sanitizers)
  # Emscripten doesn't support sanitizers
  if(EMSCRIPTEN)
    set(SUPPORTS_UBSAN OFF)
    set(SUPPORTS_ASAN OFF)
  elseif((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(computational_modeling_visualized_setup_options)
  option(computational_modeling_visualized_ENABLE_HARDENING "Enable hardening" ON)
  option(computational_modeling_visualized_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    computational_modeling_visualized_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    computational_modeling_visualized_ENABLE_HARDENING
    OFF)

  computational_modeling_visualized_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR computational_modeling_visualized_PACKAGING_MAINTAINER_MODE)
    option(computational_modeling_visualized_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(computational_modeling_visualized_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(computational_modeling_visualized_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(computational_modeling_visualized_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(computational_modeling_visualized_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(computational_modeling_visualized_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(computational_modeling_visualized_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(computational_modeling_visualized_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(computational_modeling_visualized_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(computational_modeling_visualized_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(computational_modeling_visualized_ENABLE_PCH "Enable precompiled headers" OFF)
    option(computational_modeling_visualized_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(computational_modeling_visualized_ENABLE_IPO "Enable IPO/LTO" ON)
    option(computational_modeling_visualized_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(computational_modeling_visualized_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(computational_modeling_visualized_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(computational_modeling_visualized_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(computational_modeling_visualized_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(computational_modeling_visualized_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(computational_modeling_visualized_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(computational_modeling_visualized_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(computational_modeling_visualized_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(computational_modeling_visualized_ENABLE_PCH "Enable precompiled headers" OFF)
    option(computational_modeling_visualized_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      computational_modeling_visualized_ENABLE_IPO
      computational_modeling_visualized_WARNINGS_AS_ERRORS
      computational_modeling_visualized_ENABLE_SANITIZER_ADDRESS
      computational_modeling_visualized_ENABLE_SANITIZER_LEAK
      computational_modeling_visualized_ENABLE_SANITIZER_UNDEFINED
      computational_modeling_visualized_ENABLE_SANITIZER_THREAD
      computational_modeling_visualized_ENABLE_SANITIZER_MEMORY
      computational_modeling_visualized_ENABLE_UNITY_BUILD
      computational_modeling_visualized_ENABLE_CLANG_TIDY
      computational_modeling_visualized_ENABLE_CPPCHECK
      computational_modeling_visualized_ENABLE_COVERAGE
      computational_modeling_visualized_ENABLE_PCH
      computational_modeling_visualized_ENABLE_CACHE)
  endif()

  computational_modeling_visualized_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (computational_modeling_visualized_ENABLE_SANITIZER_ADDRESS OR computational_modeling_visualized_ENABLE_SANITIZER_THREAD OR computational_modeling_visualized_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(computational_modeling_visualized_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(computational_modeling_visualized_global_options)
  if(computational_modeling_visualized_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    computational_modeling_visualized_enable_ipo()
  endif()

  computational_modeling_visualized_supports_sanitizers()

  if(computational_modeling_visualized_ENABLE_HARDENING AND computational_modeling_visualized_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR computational_modeling_visualized_ENABLE_SANITIZER_UNDEFINED
       OR computational_modeling_visualized_ENABLE_SANITIZER_ADDRESS
       OR computational_modeling_visualized_ENABLE_SANITIZER_THREAD
       OR computational_modeling_visualized_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${computational_modeling_visualized_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${computational_modeling_visualized_ENABLE_SANITIZER_UNDEFINED}")
    computational_modeling_visualized_enable_hardening(computational_modeling_visualized_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(computational_modeling_visualized_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(computational_modeling_visualized_warnings INTERFACE)
  add_library(computational_modeling_visualized_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  computational_modeling_visualized_set_project_warnings(
    computational_modeling_visualized_warnings
    ${computational_modeling_visualized_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  include(cmake/Linker.cmake)
  # Must configure each target with linker options, we're avoiding setting it globally for now

  if(NOT EMSCRIPTEN)
    include(cmake/Sanitizers.cmake)
    computational_modeling_visualized_enable_sanitizers(
      computational_modeling_visualized_options
      ${computational_modeling_visualized_ENABLE_SANITIZER_ADDRESS}
      ${computational_modeling_visualized_ENABLE_SANITIZER_LEAK}
      ${computational_modeling_visualized_ENABLE_SANITIZER_UNDEFINED}
      ${computational_modeling_visualized_ENABLE_SANITIZER_THREAD}
      ${computational_modeling_visualized_ENABLE_SANITIZER_MEMORY})
  endif()

  set_target_properties(computational_modeling_visualized_options PROPERTIES UNITY_BUILD ${computational_modeling_visualized_ENABLE_UNITY_BUILD})

  if(computational_modeling_visualized_ENABLE_PCH)
    target_precompile_headers(
      computational_modeling_visualized_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(computational_modeling_visualized_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    computational_modeling_visualized_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(computational_modeling_visualized_ENABLE_CLANG_TIDY)
    computational_modeling_visualized_enable_clang_tidy(computational_modeling_visualized_options ${computational_modeling_visualized_WARNINGS_AS_ERRORS})
  endif()

  if(computational_modeling_visualized_ENABLE_CPPCHECK)
    computational_modeling_visualized_enable_cppcheck(${computational_modeling_visualized_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(computational_modeling_visualized_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    computational_modeling_visualized_enable_coverage(computational_modeling_visualized_options)
  endif()

  if(computational_modeling_visualized_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(computational_modeling_visualized_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(computational_modeling_visualized_ENABLE_HARDENING AND NOT computational_modeling_visualized_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR computational_modeling_visualized_ENABLE_SANITIZER_UNDEFINED
       OR computational_modeling_visualized_ENABLE_SANITIZER_ADDRESS
       OR computational_modeling_visualized_ENABLE_SANITIZER_THREAD
       OR computational_modeling_visualized_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    computational_modeling_visualized_enable_hardening(computational_modeling_visualized_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
