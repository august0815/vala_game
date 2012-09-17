#!/usr/bin/env python

VERSION = "0.0.1"
VERSION_MAJOR_MINOR =  ".".join(VERSION.split(".")[0:2])
APPNAME = "race"

srcdir = '.'
blddir = '_build_'

def set_options(opt):
    opt.tool_options('compiler_cc')
    opt.tool_options('gnu_dirs')

def configure(conf):
    conf.check_tool('compiler_cc vala gnu_dirs')

    conf.check_cfg(package='glib-2.0', uselib_store='GLIB',
            atleast_version='2.14.0', mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='gtk+-3.0', uselib_store='GTK+',
            atleast_version='2.10.0', mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='gee-1.0', uselib_store='GEE', atleast_version='0.1.5', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='sdl', uselib_store='SDL',
            atleast_version='1.2', mandatory=True, args='--cflags --libs')  
    conf.check_cfg(package='SDL_image', uselib_store='SDLIMAGE',
            atleast_version='1.2', mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='SDL_gfx', uselib_store='SDLGraphics',
            atleast_version='1.2', mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='sqlite3', uselib_store='Sqlite',
            atleast_version='3.0', mandatory=True, args='--cflags --libs')
    conf.define('PACKAGE', APPNAME)
    conf.define('PACKAGE_NAME', APPNAME)
    conf.define('PACKAGE_STRING', APPNAME + '-' + VERSION)
    conf.define('PACKAGE_VERSION', APPNAME + '-' + VERSION)

    conf.define('VERSION', VERSION)
    conf.define('VERSION_MAJOR_MINOR', VERSION_MAJOR_MINOR)

def build(bld):
    bld.add_subdirs('src')
    

