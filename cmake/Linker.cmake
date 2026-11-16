macro(computational_modeling_visualized_configure_linker project_name)
  set(computational_modeling_visualized_USER_LINKER_OPTION
    "DEFAULT"
      CACHE STRING "Linker to be used")
    set(computational_modeling_visualized_USER_LINKER_OPTION_VALUES "DEFAULT" "SYSTEM" "LLD" "GOLD" "BFD" "MOLD" "SOLD" "APPLE_CLASSIC" "MSVC")
  set_property(CACHE computational_modeling_visualized_USER_LINKER_OPTION PROPERTY STRINGS ${computational_modeling_visualized_USER_LINKER_OPTION_VALUES})
  list(
    FIND
    computational_modeling_visualized_USER_LINKER_OPTION_VALUES
    ${computational_modeling_visualized_USER_LINKER_OPTION}
    computational_modeling_visualized_USER_LINKER_OPTION_INDEX)

  if(${computational_modeling_visualized_USER_LINKER_OPTION_INDEX} EQUAL -1)
    message(
      STATUS
        "Using custom linker: '${computational_modeling_visualized_USER_LINKER_OPTION}', explicitly supported entries are ${computational_modeling_visualized_USER_LINKER_OPTION_VALUES}")
  endif()

  set_target_properties(${project_name} PROPERTIES LINKER_TYPE "${computational_modeling_visualized_USER_LINKER_OPTION}")
endmacro()
