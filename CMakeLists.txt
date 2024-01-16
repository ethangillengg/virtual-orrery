cmake_minimum_required(VERSION 3.14)
project(Virtual-Orrery)

#================================#
# Compiler                       #
#================================#
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_EXTENSIONS OFF)

#================================#
# Git Submodules                 #
#================================#
find_package(Git QUIET)
if(GIT_FOUND AND EXISTS "${PROJECT_SOURCE_DIR}/.git")
# Update submodules as needed
    option(GIT_SUBMODULE "Check submodules during build" ON)
    if(GIT_SUBMODULE)
        message(STATUS "Submodule update")
        execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive# --remote
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        RESULT_VARIABLE GIT_SUBMOD_RESULT)
        if(NOT GIT_SUBMOD_RESULT EQUAL "0")
            message(FATAL_ERROR "git submodule update --init --recursive --remote failed with ${GIT_SUBMOD_RESULT}, please checkout submodules")
        endif()
    endif()
endif()

if(NOT EXISTS "${PROJECT_SOURCE_DIR}/VulkanLaunchpad/CMakeLists.txt")
    message(FATAL_ERROR "The submodules were not downloaded! GIT_SUBMODULE was turned off or failed. Please update submodules and try again.")
endif()


#=======================================#
# Dependencies                          #
#=======================================#

### Launchpad ############################################

add_subdirectory(VulkanLaunchpad)
include_directories(VulkanLaunchpad/src)
link_libraries(VulkanLaunchpad)

### Imgui ###############################################

add_subdirectory("${CMAKE_SOURCE_DIR}/imgui")
include_directories("${CMAKE_SOURCE_DIR}/imgui")
link_libraries(Imgui)

### Shared ###############################################

add_subdirectory("${CMAKE_SOURCE_DIR}/shared")
include_directories("${CMAKE_SOURCE_DIR}/shared")
link_libraries(Shared)

#=======================================#
# Executable                            #
#=======================================#
set(PROJECT_NAME main)

add_compile_definitions("ASSET_DIR=${CMAKE_SOURCE_DIR}/assets")

file(GLOB sources src/*.cpp)
add_executable(${PROJECT_NAME} 
    ${sources}
)

install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
