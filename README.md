# adwaita-refresh-installer

A Makefile for installing the GNOME 3.32 Adwaita theme both natively and as a Flatpak.

```
# **************************************** WARNING ****************************************
# This theme is installed under the name "AdwaitaRefresh", HOWEVER many apps change their
# behavior based on the name "Adwaita". IN ADDITION, some parts of the new theme require
# corresponding GTK3 code changes. Therefore, not everything will display 100% correctly.
# Examples include switches, the pathbar and find floats.
# *******DO NOT, I repeat, DO NOT FILE BUGS WITH GTK+ BASED ON THE BEHAVIOR OF THIS.*******
# If something appears to be a bug, test it with the proper, *named* Adwaita first.
# **************************************** WARNING ****************************************
```

## Usage

Run `make help`:

```
# Makefile help:
#
# build-native           - Build the Adwaita theme files for standard use in _build/native.
# build-flatpak          - Build Flatpak bundles for the themes in _build/flatpak/.
# build                  - Runs both of the above.
# install-system-native  - Install the theme files to /usr/share/themes.
# install-system-flatpak - Install the Flatpak-ed theme system-wide.
# install-system-icons   - Install the icons system-wide.
# install-system         - Runs all the install-system-* targets.
# install-user-native    - Install the theme files to /home/ryan/.local/share/themes.
# install-user-flatpak   - Install the Flatpak-ed theme for this user only.
# install-user-icons     - Install the icons for to /home/ryan/.local/share/icons.
# install-user           - Runs all the install-user-* targets.
#
# Each install target as an uninstall equivalent, e.g. uninstall-user-native.
# In addition, the install targets run the build targets automatically.
# The build targets also update the local GTK+ checkout in _build/gtk automatically.
```
