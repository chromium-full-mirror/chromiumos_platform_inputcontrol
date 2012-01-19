# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

SCRIPTS=\
	mouse_added \
	mousecontrol

SCRIPTS_DIR=/opt/google/mouse

UDEV_RULE=99-mouse.rules

UPSTART_CONF=mouse.conf

DESTDIR = .

install: $(SCRIPTS) $(UDEV_RULE) $(UPSTART_CONF)
	mkdir -p $(DESTDIR)/$(SCRIPTS_DIR)
	cp -p $(SCRIPTS) $(DESTDIR)/$(SCRIPTS_DIR)
	chmod 0755 $(DESTDIR)/$(SCRIPTS_DIR)/*
	install -D -m 0644 $(UDEV_RULE) \
		$(DESTDIR)/etc/udev/rules.d/$(UDEV_RULE)
	install -D -m 0644 $(UPSTART_CONF) \
		$(DESTDIR)/etc/init/$(UPSTART_CONF)
