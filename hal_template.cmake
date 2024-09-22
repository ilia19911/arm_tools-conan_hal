cmake_minimum_required(VERSION 3.28)

set(@HAL@_PATH @PATH@)
# Определяем функцию, которая принимает два списка: файлов и строк
function(filter_files_by_strings files_list strings_list)
    # Преобразуем списки в списки CMake
    list(APPEND cmake_files_list ${files_list})
    list(APPEND cmake_strings_list ${strings_list})

    # Создаем пустой список для результатов
    set(filtered_files_list "")

    # Обрабатываем каждый файл
    foreach(file_path IN LISTS cmake_files_list)
        get_filename_component(filename ${file_path} NAME)
        string(REGEX REPLACE ".*hal_(.*)\\.c" "\\1" module_name ${filename})
        string(FIND ${filename} "hal.c" main )
        if(NOT main EQUAL -1)
            list(APPEND HAL_SOURCE_LIST ${file_path})
        endif ()
        # Проверяем, содержит ли имя файла хотя бы одну строку из списка строк
        foreach(string IN LISTS cmake_strings_list)
            if(${string} STREQUAL ${module_name} OR ${string}_ex STREQUAL ${module_name})
                # Если содержит, добавляем файл в список результатов
                list(APPEND HAL_SOURCE_LIST ${file_path})
                break()  # Прерываем цикл, если строка найдена
            endif()
        endforeach()
    endforeach()

    #    message(STATUS "files: " ${HAL_SOURCE_LIST})
    # Возвращаем результат
    set(HAL_SOURCE_LIST "${HAL_SOURCE_LIST}" PARENT_SCOPE)
endfunction()

# Функция для обрезания строк типа HAL_*_MODULE_ENABLED и перевода в нижний регистр
function(trim_and_lowercase_module_lines MODULE_LINES)
    foreach(module_line ${MODULE_LINES})
        # Обрезаем строку до аббревиатуры HAL_..._MODULE_ENABLED
        string(REGEX REPLACE ".*HAL_(.*)_MODULE_ENABLED" "\\1" module_abbrev ${module_line})
        # Удаляем пробелы с начала и конца строки
        string(STRIP "${module_abbrev}" module_abbrev)
        # Переводим аббревиатуру в нижний регистр
        string(TOLOWER ${module_abbrev} module_abbrev_lower)
        # Добавляем обрезанную и переведенную строку в список
        list(APPEND RESULT ${module_abbrev_lower})
    endforeach()
    set(TRIMMED_MODULE_LINES ${RESULT} PARENT_SCOPE)
endfunction()

# Функция для удаления комментариев и поиска строк с #define _MODULE_ENABLED в файле
function(remove_comments_and_find_define_module_enabled INPUT_FILE OUTPUT_FILE)
    if(NOT EXISTS ${INPUT_FILE})
        message(FATAL_ERROR "${INPUT_FILE} does not exist.")
    endif()

    # Выполняем gcc для удаления комментариев
    execute_process(
            COMMAND ${CMAKE_C_COMPILER} -fpreprocessed -dD -E ${INPUT_FILE} -o ${OUTPUT_FILE}
            RESULT_VARIABLE CMD_RESULT
    )

    if(CMD_RESULT)
        message(FATAL_ERROR "Failed to remove comments from ${INPUT_FILE}.")
    endif()

    # Читаем результат в CMake
    file(READ ${OUTPUT_FILE} FILE_CONTENTS)

    # Разбиваем файл на строки
    string(REGEX REPLACE "\r" "" FILE_CONTENTS ${FILE_CONTENTS})  # Удаляем символы \r
    string(REPLACE "\n" ";" FILE_LINES ${FILE_CONTENTS})           # Разбиваем на список строк

    # Находим строки с #define _MODULE_ENABLED
    foreach(line ${FILE_LINES})
        if(line MATCHES "^#define.*_MODULE_ENABLED")
            list(APPEND RESULT ${line})
        endif()
    endforeach()



    set(MODULE_ENABLED_LINES ${RESULT} PARENT_SCOPE)
endfunction()

function(ADD_@HAL@_TO_TARGET TARGET HAL_CONFIG_FILE)
    message(STATUS "HAL_PATH: " ${CMAKE_CURRENT_LIST_DIR})
    SET(HAL_INCLUDE_DIRS "${@HAL@_PATH}/Include" "${@HAL@_PATH}/Include/Legacy")
    FILE(GLOB_RECURSE SRC_FILES "${@HAL@_PATH}/HALSource/*.c")
    #set(HAL_SOURCE_LIST "${CMAKE_CURRENT_LIST_DIR}/../source/stm32h7xx_hal.c")
    message(STATUS "HAL_INCLUDE_DIRS: " ${HAL_INCLUDE_DIRS})
#    file(GLOB_RECURSE HAL_CONFIG_FILE "${CMAKE_CURRENT_SOURCE_DIR}/*_hal_conf.h")
    message(STATUS "HAL_CONFIG_FILE: " ${HAL_CONFIG_FILE})
    get_filename_component(HAL_CONFIG_PATH "${HAL_CONFIG_FILE}" DIRECTORY)
    message(STATUS "HAL_CONFIG_PATH: " ${HAL_CONFIG_PATH})
    # Чтение конфигурационного файла
    file(READ "${HAL_CONFIG_FILE}" CONFIG_CONTENTS)



    set(OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/processed_file.c")

    remove_comments_and_find_define_module_enabled(${HAL_CONFIG_FILE} ${OUTPUT_FILE} )

    trim_and_lowercase_module_lines("${MODULE_ENABLED_LINES}")
    #message("Trimmed and lowercased module lines:")
    foreach(line ${TRIMMED_MODULE_LINES})
        message("  ${line}")
    endforeach()
    filter_files_by_strings("${SRC_FILES}" "${TRIMMED_MODULE_LINES}")

    #add_definitions(-DUSE_HAL_DRIVER)
    message(STATUS "HAL_SOURCE_LIST: " ${HAL_SOURCE_LIST})
#    add_library(@HAL@ STATIC ${HAL_SOURCE_LIST} )
    target_sources(${TARGET} PUBLIC ${HAL_SOURCE_LIST})

    target_include_directories(${TARGET} PUBLIC
            ${HAL_INCLUDE_DIRS}
            ${HAL_CONFIG_PATH}
    )
    #include_directories(${HAL_INCLUDE_DIRS})
    target_compile_definitions(${TARGET} PRIVATE USE_HAL_DRIVER)
    file(GLOB_RECURSE HAL_MAIN_FILE "${@HAL@_PATH}/Include/*_hal.h")
    MESSAGE("HAL_MAIN_FILE IS" ${HAL_MAIN_FILE})

    target_compile_definitions(${TARGET} PUBLIC HAL_CONFIG="${HAL_MAIN_FILE}")
    #target_compile_definitions(HAL PRIVATE fno-lto)
    #target_link_options(HAL PRIVATE "-Wl,-fno-lto"  )
    # Устанавливаем путь для выходных файлов библиотеки

    ## Обрабатываем каждый путь
    #foreach(file_path IN LISTS HAL_SOURCE_LIST)
    #    # Извлекаем имя файла без пути
    #    get_filename_component(filename ${file_path} NAME)
    #
    #    # Выводим имя файла в новой строке
    #    message("${filename}")
    #endforeach()

endfunction()


