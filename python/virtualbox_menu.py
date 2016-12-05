#!/usr/bin/python

import sys,os,ConfigParser

#FIXME: expand python path for VirtualBox XPCOM
#http://code.google.com/p/vboxweb/issues/detail?id=12
#http://code.google.com/p/vboxweb/issues/detail?id=16
vbox = "/usr/lib/virtualbox"
sys.path.append(vbox+"/sdk/bindings/xpcom/python")
sys.path.append(vbox) #for VBoxPython.so
import vboxapi

path = os.path.expanduser("~/.config/xfce4/panel")
match = ("launcher-",".rc")
option = ("Entry 0","Name")
title = "VirtualBox"
keep = ("Global",option[0])

def image(k):
   images = {
   "Other":"os_other",
   "WindowsXP":"os_winxp",
   "Linux":"os_linux_other"
   }
   return images.has_key(k) and images[k] or None

def template(m):
   return {
   "Name":m.name,
   "Icon":image(m.OSTypeId),
   "Exec":"VBoxManage startvm "+m.id
   }

def load():
   result = []
   for file in os.listdir(path):
      if file.startswith(match[0]) and file.endswith(match[1]):
         config = ConfigParser.ConfigParser()
         config.optionxform = str #case sensitive!
         config.read(os.path.join(path,file))
         if config.has_option(*option) and config.get(*option)==title:
            print "VirtualBox launcher configuration:",file
            result.append((config,file))
   return result
            
def generate(config,machines):
   for section in config.sections():
      if not section in keep:
         config.remove_section(section)
   count = 0
   print "Generate machine entries ..."
   for m in machines:
      t = m.getGuestProperty("/VirtualBox/GuestInfo/OS/Product")[0]
      print "%s (%s)"%(m.name,t)
      count += 1
      section = option[0][:-1]+str(count)
      config.add_section(section)
      for item in config.items(option[0]):
         if template(m).has_key(item[0]) and template(m)[item[0]]:
            config.set(section, item[0], template(m)[item[0]])
         else:
            config.set(section, *item)
   return config

def write(config,launcher):
   file = os.path.join(path,launcher[1]+".new")
   with open(file, 'wb') as fp:
      config.write(fp)
      print "New configuration written to",file

def main():
   virtualBoxManager = vboxapi.VirtualBoxManager(None,None)
   machines = virtualBoxManager.getArray(virtualBoxManager.vbox, 'machines')
   for launcher in load():
      config = generate(launcher[0],machines)
      write(config,launcher)
   
if __name__=="__main__":
   main()