# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

MOUSE_SCRIPTS=\
	common \
	mouse_added \
	mousecontrol

MOUSE_SCRIPTS_DIR=/opt/google/mouse

TP_SCRIPTS=\
	generate_userfeedback \
	send_input_metrics \
	touchpad_added \
	tpcontrol \
	tpcontrol_synclient \
	tpcontrol_xinput

TP_SCRIPTS_DIR=/opt/google/touchpad

TS_SCRIPTS=\
	   touchscreen_feedback

TS_SCRIPTS_DIR=/opt/google/touchscreen

UDEV_RULE=99-inputcontrol.rules

INIT_DIR=/etc/init

UPSTART_CONF=\
	input-metrics.conf \
	mouse.conf

DESTDIR = .

install: $(MOUSE_SCRIPTS) $(TP_SCRIPTS) $(UDEV_RULE) $(UPSTART_CONF)
	mkdir -p $(DESTDIR)/$(MOUSE_SCRIPTS_DIR)
	cp -p $(MOUSE_SCRIPTS) $(DESTDIR)/$(MOUSE_SCRIPTS_DIR)
	chmod 0755 $(DESTDIR)/$(MOUSE_SCRIPTS_DIR)/*
	mkdir -p $(DESTDIR)/$(TP_SCRIPTS_DIR)
	cp -p $(TP_SCRIPTS) $(DESTDIR)/$(TP_SCRIPTS_DIR)
	chmod 0755 $(DESTDIR)/$(TP_SCRIPTS_DIR)/*
	mkdir -p $(DESTDIR)/$(TS_SCRIPTS_DIR)
	cp -p $(TS_SCRIPTS) $(DESTDIR)/$(TS_SCRIPTS_DIR)
	chmod 0755 $(DESTDIR)/$(TS_SCRIPTS_DIR)/*

	install -D -m 0644 $(UDEV_RULE) \
		$(DESTDIR)/lib/udev/rules.d/$(UDEV_RULE)
	install -d $(DESTDIR)$(INIT_DIR)
	install -m 0644 $(UPSTART_CONF) $(DESTDIR)$(INIT_DIR)
