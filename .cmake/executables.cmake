# In this file you can define executables for your project
# The general syntax is:
#   add_executable(<name> <source0> <source1> ... <sourceN>)

find_package(Curses REQUIRED)

add_executable(tetris ./main.S ./game.S)
target_link_libraries(tetris ${CURSES_LIBRARIES})
add_executable(main ./main.S)
target_link_libraries(main ${CURSES_LIBRARIES})

