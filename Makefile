$(shell mkdir -p _build)

SHELL = bash -O extglob
XDG_DATA_HOME ?= $(HOME)/.local/share

help:
	# Makefile help:
	#
	# build-native           - Build the Adwaita theme files for standard use in _build/native.
	# build-flatpak          - Build Flatpak bundles for the themes in _build/flatpak/.
	# build                  - Runs both of the above.
	# install-system-native  - Install the theme files to /usr/share/themes.
	# install-system-flatpak - Install the Flatpak-ed theme system-wide.
	# install-system-icons   - Install the icons system-wide.
	# install-system         - Runs all the install-system-* targets.
	# install-user-native    - Install the theme files to ${XDG_DATA_HOME}/themes.
	# install-user-flatpak   - Install the Flatpak-ed theme for this user only.
	# install-user-icons     - Install the icons for to ${XDG_DATA_HOME}/icons.
	# install-user           - Runs all the install-user-* targets.
	#
	# Each install target as an uninstall equivalent, e.g. uninstall-user-native.
	# In addition, the install targets run the build targets automatically.
	# The build targets also update the local GTK+ checkout in _build/gtk automatically.

_build/warning:
	# **************************************** WARNING ****************************************
	# This theme is installed under the name "AdwaitaRefresh", HOWEVER many apps change their
	# behavior based on the name "Adwaita". Therefore, not everything will display 100%
	# correctly. Examples include the pathbar and find floats.
	# *******DO NOT, I repeat, DO NOT FILE BUGS WITH GTK+ BASED ON THE BEHAVIOR OF THIS.*******
	# If something appears to be a bug, test it with the proper, *named* Adwaita first.
	# **************************************** WARNING ****************************************
	@echo -n '* Press Enter to confirm this warning (this will time out in 60 seconds)... '
	@read -t 60
	@touch $@

_internal-repo: _build/warning
	[ -d _build/gtk ] && \
		(cd _build/gtk; git fetch origin; git reset --hard origin/wip/jimmac/adwaita-3-32-noshadow) || \
		git clone --depth=1 -b wip/jimmac/adwaita-3-32-noshadow \
			https://gitlab.gnome.org/GNOME/gtk.git _build/gtk
	[ -d _build/adwaita-icon-theme ] && \
		(cd _build/adwaita-icon-theme; git fetch origin; git reset --hard origin/master) || \
		git clone --depth=1 https://gitlab.gnome.org/GNOME/adwaita-icon-theme.git \
		_build/adwaita-icon-theme

build-native: _internal-repo
	rm -rf _build/native

	mkdir -p _build/native/AdwaitaRefresh/gtk-3.0
	echo '@import url("gtk-contained.css");' > _build/native/AdwaitaRefresh/gtk-3.0/gtk.css
	echo '@import url("gtk-contained-dark.css");' > \
		_build/native/AdwaitaRefresh/gtk-3.0/gtk-dark.css
	cp _build/gtk/gtk/theme/Adwaita/gtk-contained{,-dark}.css \
		_build/native/AdwaitaRefresh/gtk-3.0
	cp -r _build/gtk/gtk/theme/Adwaita/assets _build/native/AdwaitaRefresh/gtk-3.0

	mkdir -p _build/native/AdwaitaRefresh-dark/gtk-3.0
	cp _build/native/AdwaitaRefresh/gtk-3.0/gtk{,-contained-dark}.css \
		_build/native/AdwaitaRefresh-dark/gtk-3.0
	mv _build/native/AdwaitaRefresh-dark/gtk-3.0/gtk-contained{-dark,}.css
	cp -r _build/native/AdwaitaRefresh{,-dark}/gtk-3.0/assets

	sed 's/@NAME/AdwaitaRefresh/' index.theme.in > _build/native/AdwaitaRefresh/index.theme
	sed 's/@NAME/AdwaitaRefresh-dark/' index.theme.in > \
		_build/native/AdwaitaRefresh-dark/index.theme

build-flatpak: build-native
	rm -rf _build/flatpak/repo
	mkdir -p _build/flatpak
	ostree init --mode=archive --repo=_build/flatpak/repo
	ostree --repo=_build/flatpak/repo config set core.min-free-space-percent 0

	$(MAKE) _internal-build-flatpak VARIANT=AdwaitaRefresh
	$(MAKE) _internal-build-flatpak VARIANT=AdwaitaRefresh-dark

build-icons: _internal-repo
	rm -rf _build/icons _build/adwaita-icon-theme/index.theme

	# XXX: Generate a basic Makefile without autotools.
	echo 'SVGOUTDIR=Adwaita' > _build/adwaita-icon-theme/Makefile
	echo -n 'THEME_DIRS=' >> _build/adwaita-icon-theme/Makefile
	(cd _build/adwaita-icon-theme/Adwaita; echo !(cursors)/*) >> \
		_build/adwaita-icon-theme/Makefile
	awk '/^THEME_DIRS=/{p=1;next;}; p; /done/{p=0;}' \
		_build/adwaita-icon-theme/Makefile.am >> _build/adwaita-icon-theme/Makefile
	make -C _build/adwaita-icon-theme index.theme

	mkdir -p _build/icons
	cp -r _build/adwaita-icon-theme/Adwaita _build/icons/AdwaitaRefresh
	cp _build/adwaita-icon-theme/index.theme _build/icons/AdwaitaRefresh
	rm -rf _build/icons/AdwaitaRefresh/cursors

_internal-build-flatpak:
	rm -rf _build/flatpak/$(VARIANT)
	flatpak build-init --type=extension _build/flatpak/$(VARIANT) org.gtk.Gtk3theme.$(VARIANT) \
		org.freedesktop.Sdk org.freedesktop.Platform 18.08

	cp -r _build/native/$(VARIANT)/gtk-3.0/* _build/flatpak/$(VARIANT)/files
	mkdir -p _build/flatpak/$(VARIANT)/files/share/appdata
	sed 's/@NAME/$(VARIANT)/' appdata.xml.in > \
		_build/flatpak/$(VARIANT)/files/share/appdata/org.gtk.Gtk3theme.$(VARIANT).appdata.xml
	appstream-compose --prefix=_build/flatpak/$(VARIANT)/files \
		--basename=org.gtk.Gtk3theme.$(VARIANT) --origin=flatpak org.gtk.Gtk3theme.$(VARIANT)

	flatpak build-finish _build/flatpak/$(VARIANT)
	flatpak build-export _build/flatpak/repo _build/flatpak/$(VARIANT) 3.22
	flatpak build-bundle --runtime _build/flatpak/repo \
		_build/flatpak/org.gtk.Gtk3theme.$(VARIANT).flatpak org.gtk.Gtk3theme.$(VARIANT) 3.22

build: build-native build-flatpak build-icons

_internal-uninstall-native:
	rm -rf $(THEMES)/AdwaitaRefresh{,-dark}

_internal-uninstall-flatpak:
	if flatpak info --$(INSTALLATION) org.gtk.Gtk3theme.AdwaitaRefresh >/dev/null 2>&1; then\
		flatpak uninstall -y --$(INSTALLATION) org.gtk.Gtk3theme.AdwaitaRefresh; fi
	if flatpak info --$(INSTALLATION) org.gtk.Gtk3theme.AdwaitaRefresh-dark >/dev/null 2>&1; then\
		flatpak uninstall -y --$(INSTALLATION) org.gtk.Gtk3theme.AdwaitaRefresh; fi

_internal-uninstall-icons:
	rm -rf $(ICONS)/AdwaitaRefresh

uninstall-system-native:
	$(MAKE) _internal-uninstall-native THEMES=/usr/share/themes

uninstall-system-flatpak:
	$(MAKE) _internal-uninstall-flatpak INSTALLATION=system

uninstall-system-icons:
	$(MAKE) _internal-uninstall-icons ICONS=/usr/share/icons

uninstall-system: uninstall-system-native uninstall-system-flatpak uninstall-system-icons

uninstall-user-native:
	$(MAKE) _internal-uninstall-native THEMES=$(XDG_DATA_HOME)/themes

uninstall-user-flatpak:
	$(MAKE) _internal-uninstall-flatpak INSTALLATION=user

uninstall-user-icons:
	$(MAKE) _internal-uninstall-icons ICONS=$(XDG_DATA_HOME)/icons

uninstall-user: uninstall-user-native uninstall-user-flatpak uninstall-user-icons

_internal-install-native: _internal-uninstall-native
	mkdir -p $(THEMES)
	cp -r _build/native/* $(THEMES)

_internal-install-flatpak:
	flatpak install -y --$(INSTALLATION) _build/flatpak/org.gtk.Gtk3theme.AdwaitaRefresh.flatpak
	flatpak install -y --$(INSTALLATION) \
		_build/flatpak/org.gtk.Gtk3theme.AdwaitaRefresh-dark.flatpak

_internal-install-icons: _internal-uninstall-icons
	mkdir -p $(ICONS)
	cp -r _build/icons/AdwaitaRefresh $(ICONS)

install-system-native: build-native
	$(MAKE) _internal-install-native THEMES=/usr/share/themes

install-system-flatpak: build-flatpak
	$(MAKE) _internal-install-flatpak INSTALLATION=system

install-system-icons: build-icons
	$(MAKE) _internal-install-icons ICONS=/usr/share/icons

install-system: install-system-native install-system-flatpak install-system-icons

install-user-native: build-native
	$(MAKE) _internal-install-native THEMES=$(XDG_DATA_HOME)/themes

install-user-flatpak: build-flatpak
	$(MAKE) _internal-install-flatpak INSTALLATION=user

install-user-icons: build-icons
	$(MAKE) _internal-install-icons ICONS=$(XDG_DATA_HOME)/icons

install-user: install-user-native install-user-flatpak install-user-icons
