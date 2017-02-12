project('IVala', 'c', 'vala')

add_project_arguments(['--vapidir=' + meson.current_source_dir() + '/vapi'],
                      language: 'vala')

glib = dependency('glib-2.0')
gio = dependency('gio-2.0')
zmq = dependency('libzmq')

subdir('src')
