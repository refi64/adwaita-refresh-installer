$(shell mkdir -p _build)

XDG_DATA_HOME ?= $(HOME)/.local/share

help:
	# Makefile help:
	#
	# build-native           - Build the Adwaita theme files for standard use in _build/native.
	# build-flatpak          - Build Flatpak bundles for the themes in _build/flatpak/.
	# build                  - Runs both of the above.
	# install-system-native  - Install the theme files to /usr/share/themes.
	# install-system-flatpak - Install the Flatpak-ed theme system-wide.
	# install-system         - Runs both of the above.
	# install-user-native    - Install the theme files to ${XDG_DATA_HOME}/themes.
	# install-user-flatpak   - Install the Flatpak-ed theme for this user only.
	# install-user           - Runs both of the above.
	#
	# Each install target as an uninstall equivalent, e.g. uninstall-user-native.
	# In addition, the install targets run the build targets automatically.
	# The build targets also update the local GTK+ checkout in _build/gtk automatically.

_internal-repo:
	[ -d _build/gtk ] && (cd _build/gtk; git pull) || \
		git clone --depth=1 -b wip/jimmac/adwaita-3-32 \
			https://gitlab.gnome.org/GNOME/gtk.git _build/gtk

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

build: build-native build-flatpak

_internal-uninstall-native:
	rm -rf $(THEMES)/AdwaitaRefresh{,-dark}

_internal-uninstall-flatpak:
	if flatpak info --$(INSTALLATION) org.gtk.Gtk3theme.AdwaitaRefresh >/dev/null 2>&1; then\
		flatpak uninstall -y --$(INSTALLATION) org.gtk.Gtk3theme.AdwaitaRefresh; fi
	if flatpak info --$(INSTALLATION) org.gtk.Gtk3theme.AdwaitaRefresh-dark >/dev/null 2>&1; then\
		flatpak uninstall -y --$(INSTALLATION) org.gtk.Gtk3theme.AdwaitaRefresh; fi

uninstall-system-native:
	$(MAKE) _internal-uninstall-native THEMES=/usr/share/themes

uninstall-system-flatpak:
	$(MAKE) _internal-uninstall-flatpak INSTALLATION=system

uninstall-system: uninstall-system-native uninstall-system-flatpak

uninstall-user-native:
	$(MAKE) _internal-uninstall-native THEMES=$(XDG_DATA_HOME)/themes

uninstall-user-flatpak:
	$(MAKE) _internal-uninstall-flatpak INSTALLATION=user

uninstall-user: uninstall-user-native uninstall-user-flatpak

_internal-install-native: _internal-uninstall-native
	mkdir -p $(THEMES)
	cp -r _build/native/* $(THEMES)

_internal-install-flatpak:
	flatpak install -y --$(INSTALLATION) _build/flatpak/org.gtk.Gtk3theme.AdwaitaRefresh.flatpak
	flatpak install -y --$(INSTALLATION) \
		_build/flatpak/org.gtk.Gtk3theme.AdwaitaRefresh-dark.flatpak

install-system-native: build-native
	$(MAKE) _internal-install-native THEMES=/usr/share/themes

install-system-flatpak: build-flatpak
	$(MAKE) _internal-install-flatpak INSTALLATION=system

install-system: install-system-native install-system-flatpak

install-user-native: build-native
	$(MAKE) _internal-install-native THEMES=$(XDG_DATA_HOME)/themes

install-user-flatpak: build-flatpak
	$(MAKE) _internal-install-flatpak INSTALLATION=user

install-user: install-user-native install-user-flatpak
