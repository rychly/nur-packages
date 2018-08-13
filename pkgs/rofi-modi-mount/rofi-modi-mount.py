#!/usr/bin/env python2
# vim:fileencoding=UTF-8:ts=4:sw=4:sta:et:sts=4:ai

from __future__ import print_function

__license__ = 'GPL v3'
__copyright__ = '2010, Kovid Goyal <kovid@kovidgoyal.net>; 2017, Marek Rychly <marek.rychly@gmail.com>'
__docformat__ = 'restructuredtext en'

# ########## (c) 2010, Kovid Goyal <kovid@kovidgoyal.net> ##########
# adopted from https://github.com/kovidgoyal/calibre/blob/master/src/calibre/devices/udisks.py

import os, re


def node_mountpoint(node):
    def de_mangle(raw):
        return raw.replace('\\040', ' ').replace('\\011', '\t').replace('\\012',
                                                                        '\n').replace('\\0134', '\\')

    for line in open('/proc/mounts').readlines():
        line = line.split()
        if line[0] == node:
            return de_mangle(line[1])
    return None


class NoUDisks1(Exception):
    pass


class UDisks(object):

    def __init__(self):
        import dbus
        self.bus = dbus.SystemBus()
        try:
            self.main = dbus.Interface(self.bus.get_object('org.freedesktop.UDisks',
                                                           '/org/freedesktop/UDisks'), 'org.freedesktop.UDisks')
        except dbus.exceptions.DBusException as e:
            if getattr(e, '_dbus_error_name', None) == 'org.freedesktop.DBus.Error.ServiceUnknown':
                raise NoUDisks1()
            raise

    def device(self, device_node_path):
        import dbus
        devpath = self.main.FindDeviceByDeviceFile(device_node_path)
        return dbus.Interface(self.bus.get_object('org.freedesktop.UDisks',
                                                  devpath), 'org.freedesktop.UDisks.Device')

    def mount(self, device_node_path):
        d = self.device(device_node_path)
        try:
            return unicode(d.FilesystemMount('',
                                             ['auth_no_user_interaction', 'rw', 'noexec', 'nosuid',
                                              'nodev', 'uid=%d' % os.geteuid(), 'gid=%d' % os.getegid()]))
        except:
            # May be already mounted, check
            mp = node_mountpoint(str(device_node_path))
            if mp is None:
                raise
            return mp

    def unmount(self, device_node_path):
        d = self.device(device_node_path)
        d.FilesystemUnmount(['force'])

    def eject(self, device_node_path):
        parent = device_node_path
        while parent[-1] in '0123456789':
            parent = parent[:-1]
        d = self.device(parent)
        d.DriveEject([])


class NoUDisks2(Exception):
    pass


class UDisks2(object):
    BLOCK = 'org.freedesktop.UDisks2.Block'
    FILESYSTEM = 'org.freedesktop.UDisks2.Filesystem'
    DRIVE = 'org.freedesktop.UDisks2.Drive'

    def __init__(self):
        import dbus
        self.bus = dbus.SystemBus()
        try:
            self.bus.get_object('org.freedesktop.UDisks2',
                                '/org/freedesktop/UDisks2')
        except dbus.exceptions.DBusException as e:
            if getattr(e, '_dbus_error_name', None) == 'org.freedesktop.DBus.Error.ServiceUnknown':
                raise NoUDisks2()
            raise

    def device(self, device_node_path):
        device_node_path = os.path.realpath(device_node_path)
        devname = device_node_path.split('/')[-1]

        # First we try a direct object path
        bd = self.bus.get_object('org.freedesktop.UDisks2',
                                 '/org/freedesktop/UDisks2/block_devices/%s' % devname)
        try:
            device = bd.Get(self.BLOCK, 'Device',
                            dbus_interface='org.freedesktop.DBus.Properties')
            device = bytearray(device).replace(b'\x00', b'').decode('utf-8')
        except:
            device = None

        if device == device_node_path:
            return bd

        # Enumerate all devices known to UDisks
        devs = self.bus.get_object('org.freedesktop.UDisks2',
                                   '/org/freedesktop/UDisks2/block_devices')
        xml = devs.Introspect(dbus_interface='org.freedesktop.DBus.Introspectable')
        for dev in re.finditer(r'name=[\'"](.+?)[\'"]', type(u'')(xml)):
            bd = self.bus.get_object('org.freedesktop.UDisks2',
                                     '/org/freedesktop/UDisks2/block_devices/%s2' % dev.group(1))
            try:
                device = bd.Get(self.BLOCK, 'Device',
                                dbus_interface='org.freedesktop.DBus.Properties')
                device = bytearray(device).replace(b'\x00', b'').decode('utf-8')
            except:
                device = None
            if device == device_node_path:
                return bd

        raise ValueError('%r not known to UDisks2' % device_node_path)

    def mount(self, device_node_path):
        d = self.device(device_node_path)
        mount_options = ['rw', 'noexec', 'nosuid',
                         'nodev', 'uid=%d' % os.geteuid(), 'gid=%d' % os.getegid()]
        try:
            return unicode(d.Mount(
                {
                    'auth.no_user_interaction': True,
                    'options': ','.join(mount_options)
                },
                dbus_interface=self.FILESYSTEM))
        except:
            # May be already mounted, check
            mp = node_mountpoint(str(device_node_path))
            if mp is None:
                raise
            return mp

    def unmount(self, device_node_path):
        d = self.device(device_node_path)
        d.Unmount({'force': True, 'auth.no_user_interaction': True},
                  dbus_interface=self.FILESYSTEM)

    def drive_for_device(self, device):
        drive = device.Get(self.BLOCK, 'Drive',
                           dbus_interface='org.freedesktop.DBus.Properties')
        return self.bus.get_object('org.freedesktop.UDisks2', drive)

    def eject(self, device_node_path):
        drive = self.drive_for_device(self.device(device_node_path))
        drive.Eject({'auth.no_user_interaction': True},
                    dbus_interface=self.DRIVE)


def get_udisks(ver=None):
    if ver is None:
        try:
            u = UDisks2()
        except NoUDisks2:
            u = UDisks()
        return u
    return UDisks2() if ver == 2 else UDisks()


def get_udisks1():
    u = None
    try:
        u = UDisks()
    except NoUDisks1:
        try:
            u = UDisks2()
        except NoUDisks2:
            pass
    if u is None:
        raise EnvironmentError('UDisks not available on your system')
    return u


def mount(node_path):
    u = get_udisks1()
    u.mount(node_path)


def eject(node_path):
    u = get_udisks1()
    u.eject(node_path)


def umount(node_path):
    u = get_udisks1()
    u.unmount(node_path)


# ########## (c) 2017, Marek Rychly <marek.rychly@gmail.com> ##########

# requires: dbus-python, PyGObject
import sys, math, dbus
from gi import require_version

require_version('Gio', '2.0')
from gi.repository import Gio

Application = Gio.Application.new("rofi.modi.mount", Gio.ApplicationFlags.FLAGS_NONE)
Application.register()

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)
    Notification = Gio.Notification.new("Error in rofi-modi-mount")
    Notification.set_body(*args)
    Application.send_notification(None, Notification)


def convert_size(size_bytes):
    if (size_bytes == 0):
        return '0B'
    size_name = ("B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB")
    i = int(math.floor(math.log(size_bytes, 1024)))
    p = math.pow(1024, i)
    s = round(size_bytes / p, 2)
    return '%s%s' % (s, size_name[i])


def get_devices():
    devices = []
    bus = dbus.SystemBus()
    ud_manager_obj = bus.get_object('org.freedesktop.UDisks2', '/org/freedesktop/UDisks2')
    om = dbus.Interface(ud_manager_obj, 'org.freedesktop.DBus.ObjectManager')
    try:
        for k, v in om.GetManagedObjects().iteritems():
            drive_info = v.get('org.freedesktop.UDisks2.Block', {})
            # if it contains a filesystem and it is not considered a system device
            if drive_info.get('IdUsage') == "filesystem" and not drive_info.get('HintSystem'):
                device = drive_info.get('Device')
                device = bytearray(device).replace(b'\x00', b'').decode('utf-8')
                devices.append(device)
    except Exception as e:
        eprint("DBus error when using org.freedesktop.DBus.ObjectManager at /org/freedesktop/UDisks2: %s" % e)
    return devices


def device_mounted(device):
    return node_mountpoint(device) is not None


def device_details(device):
    bd = get_udisks(ver=2).device(device)
    try:
        device_name = device.split('/')[-1]
        device_label = bd.Get('org.freedesktop.UDisks2.Block', 'IdLabel',
                              dbus_interface='org.freedesktop.DBus.Properties')
        device_size = bd.Get('org.freedesktop.UDisks2.Block', 'Size', dbus_interface='org.freedesktop.DBus.Properties')
        device_fs = bd.Get('org.freedesktop.UDisks2.Block', 'IdType', dbus_interface='org.freedesktop.DBus.Properties')
        print("%smount %s %s (%s %s)" % (
            "un" if device_mounted(device) else "", device_name, device_label, convert_size(device_size), device_fs))
        print("eject %s %s (%s %s)" % (device_name, device_label, convert_size(device_size), device_fs))
    except Exception as e:
        eprint("Error processing device by /org/freedesktop/UDisks2/block_devices: %s" % e)


if len(sys.argv) < 2:
    for device in get_devices():
        device_details(device)
else:
    argv = sys.argv[1].split(' ')
    action = argv[0]
    device = "/dev/" + argv[1]
    try:
        Notification = Gio.Notification.new("udisks")
        Notification.set_icon(Gio.ThemedIcon.new("dialog-information"))
        u = get_udisks(ver=2)
        if action == "mount":
            mountpoint = u.mount(device)
            Notification.set_body("udisks: mounted %s as %s" % (device, mountpoint))
        elif action == "unmount":
            u.unmount(device)
            Notification.set_body("udisks: unmounted %s" % device)
        elif action == "eject":
            if device_mounted(device):
                u.unmount(device)
            u.eject(device)
            Notification.set_body("udisks: ejected %s" % device)
        else:
            Notification.set_body("Wrong udisks action: %s" % action)
        Application.send_notification(None, Notification)
    except Exception as e:
        eprint("%s" % e)
