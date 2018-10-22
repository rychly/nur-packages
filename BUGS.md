# Bugs

## pkgs/xulrunner

Cannot load libraries and also run the binary `./xulrunner`. E.g., for Modelio see

~~~
org.eclipse.swt.SWTError: No more handles [MOZILLA_FIVE_HOME='/nix/store/31ik4ca6vxprylgzvy2j2mla68yb0l9k-xulrunner-1.9.2.29pre2012.05.03.03.32.04/lib/xulrunner'] (java.lang.UnsatisfiedLinkError: Could not load SWT library. Reasons: 
/home/rychly/.modelio/3.6/.eclipse/configuration.x86_64/org.eclipse.osgi/252/0/.cp/libswt-mozilla-gtk-4528.so: libxpcom.so: cannot open shared object file: No such file or directory
no swt-mozilla-gtk in java.library.path
/home/rychly/.swt/lib/linux/x86_64/libswt-mozilla-gtk-4528.so: libxpcom.so: cannot open shared object file: No such file or directory
Can't load library: /home/rychly/.swt/lib/linux/x86_64/libswt-mozilla-gtk.so
)
No more handles [MOZILLA_FIVE_HOME='/nix/store/31ik4ca6vxprylgzvy2j2mla68yb0l9k-xulrunner-1.9.2.29pre2012.05.03.03.32.04/lib/xulrunner'] (java.lang.UnsatisfiedLinkError: Could not load SWT library. Reasons: 
/home/rychly/.modelio/3.6/.eclipse/configuration.x86_64/org.eclipse.osgi/252/0/.cp/libswt-mozilla-gtk-4528.so: libxpcom.so: cannot open shared object file: No such file or directory
no swt-mozilla-gtk in java.library.path
/home/rychly/.swt/lib/linux/x86_64/libswt-mozilla-gtk-4528.so: libxpcom.so: cannot open shared object file: No such file or directory
Can't load library: /home/rychly/.swt/lib/linux/x86_64/libswt-mozilla-gtk.so
)
~~~
