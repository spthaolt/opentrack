macro(opentrack_module n dir)
    file(GLOB ${n}-c ${dir}/*.cpp ${dir}/*.c ${dir}/*.h ${dir}/*.hpp)
    file(GLOB ${n}-res ${dir}/*.rc)
    foreach(f ${n}-res)
        set_source_files_properties(${f} PROPERTIES LANGUAGE RC)
    endforeach()
    file(GLOB ${n}-ui ${dir}/*.ui)
    file(GLOB ${n}-rc ${dir}/*.qrc)
endmacro()

macro(opentrack_boilerplate opentrack-project-name)
    set(extra_macro_args ${ARGN})
    set(spliced ${extra_macro_args})
    project(${opentrack-project-name})
    opentrack_library(${opentrack-project-name} ${PROJECT_SOURCE_DIR} ${spliced})
    set(spliced)
endmacro()

macro(opentrack_qt n)
    qt5_wrap_cpp(${n}-moc ${${n}-c} OPTIONS --no-notes)
    QT5_WRAP_UI(${n}-uih ${${n}-ui})
    QT5_ADD_RESOURCES(${n}-rcc ${${n}-rc})
    set(${n}-all ${${n}-c} ${${n}-rc} ${${n}-rcc} ${${n}-uih} ${${n}-moc} ${${n}-res})
endmacro()

set(msvc-subsystem "/VERSION:5.1 /SUBSYSTEM:WINDOWS,5.01")
function(opentrack_compat target)
    if(MSVC)
        set_target_properties(${target} PROPERTIES LINK_FLAGS "${msvc-subsystem} /DEBUG /OPT:ICF")
    endif()
endfunction()

macro(opentrack_library n dir)
    cmake_parse_arguments(opentrack-foolib
        "NO-LIBRARY;STATIC;NO-COMPAT;NO-LINKER-SCRIPT"
        "LINK;COMPILE;GNU-LINK;GNU-COMPILE"
        ""
        ${ARGN}
    )
    if(NOT " ${opentrack-foolib_UNPARSED_ARGUMENTS}" STREQUAL " ")
        message(FATAL_ERROR "opentrack_library bad formals ${opentrack-foolib_UNPARSED_ARGUMENTS}")
    endif()
    opentrack_module(${n} ${dir})
    opentrack_qt(${n})
    set(link-mode SHARED)
    if(NOT opentrack-foolib_NO-LIBRARY)
        if (opentrack-foolib_STATIC)
            set(link-mode STATIC)
        endif()
        add_library(${n} ${link-mode} ${${n}-all})
        set(link-mode)
        if(NOT opentrack-foolib_NO-COMPAT)
            target_link_libraries(${n} opentrack-api ${MY_QT_LIBS} opentrack-compat)
        endif()
        if(CMAKE_COMPILER_IS_GNUCXX AND NOT APPLE AND NOT NO-LINKER-SCRIPT)
            SET_TARGET_PROPERTIES(${n} PROPERTIES
                LINK_FLAGS "${opentrack-foolib_LINK} ${opentrack-foolib_GNU-LINK} -Wl,--as-needed -Wl,--version-script=\"${CMAKE_SOURCE_DIR}/opentrack-compat/${version-script}-version-script.txt\""
                COMPILE_FLAGS "${opentrack-foolib_COMPILE} ${opentrack-foolib_GNU-COMPILE} -fvisibility=hidden -fvisibility-inlines-hidden"
            )
        else()
            set(link-flags)
            if(MSVC)
                set(link-flags "${msvc-subsystem} /DEBUG /OPT:ICF")
            endif()
            set_target_properties(${n} PROPERTIES LINK_FLAGS "${link-flags} ${opentrack-foolib_LINK}" COMPILE_FLAGS "${opentrack-foolib_COMPILE}")
            set(link-flags)
        endif()
        if(NOT opentrack-foolib_STATIC)
            install(TARGETS ${n} RUNTIME DESTINATION . LIBRARY DESTINATION .)
        endif()
        opentrack_compat(${n})
    endif()
endmacro()

function(link_with_dinput8 n)
    if(WIN32)
        target_link_libraries(${n} dinput8 dxguid strmiids)
    endif()
endfunction()