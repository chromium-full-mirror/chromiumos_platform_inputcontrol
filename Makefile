# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

MOUSE_SCRIPTS=\
	common \
	mousecontrol

MOUSE_SCRIPTS_DIR=/opt/google/mouse

TP_SCRIPTS=\
	tpcontrol \
	tpcontrol_synclient \
	tpcontrol_xinput

TP_SCRIPTS_DIR=/opt/google/touchpad

TS_SCRIPTS=toggle_touch_event_logging

TS_SCRIPTS_DIR=/opt/google/touchscreen

SCRIPTS=\
	device_added

X_SCRIPTS=\
	xinput.sh \
	mouse_cpi.sh \
	inputcontrol \
	cmt_feedback \
	evdev_feedback \
	touch_noise_feedback \
	send_input_metrics \
	curve_experiment

SCRIPTS_DIR=/opt/google/input/

UDEV_RULE=99-inputcontrol.rules

INIT_DIR=/etc/init

UPSTART_CONF=\
	input-metrics.conf \
	mouse.conf

DESTDIR = .

X_DEPS := $(MOUSE_SCRIPTS) $(TP_SCRIPTS) $(X_SCRIPTS) \
	$(UDEV_RULE) $(UPSTART_CONF)

install_x: $(X_DEPS)
	mkdir -p $(DESTDIR)/$(MOUSE_SCRIPTS_DIR)
	cp -p $(MOUSE_SCRIPTS) $(DESTDIR)/$(MOUSE_SCRIPTS_DIR)
	chmod 0755 $(DESTDIR)/$(MOUSE_SCRIPTS_DIR)/*
	mkdir -p $(DESTDIR)/$(TP_SCRIPTS_DIR)
	cp -p $(TP_SCRIPTS) $(DESTDIR)/$(TP_SCRIPTS_DIR)
	chmod 0755 $(DESTDIR)/$(TP_SCRIPTS_DIR)/*
	mkdir -p $(DESTDIR)/$(TS_SCRIPTS_DIR)
	cp -p $(TS_SCRIPTS) $(DESTDIR)/$(TS_SCRIPTS_DIR)
	chmod 0755 $(DESTDIR)/$(TS_SCRIPTS_DIR)/*
	mkdir -p $(DESTDIR)/$(SCRIPTS_DIR)
	cp -p $(X_SCRIPTS) $(DESTDIR)/$(SCRIPTS_DIR)
	chmod 0755 $(DESTDIR)/$(SCRIPTS_DIR)/*

	install -d $(DESTDIR)$(INIT_DIR)
	install -m 0644 $(UPSTART_CONF) $(DESTDIR)$(INIT_DIR)

ifneq ($(HAVE_XINPUT),0)
install: install_x
endif

install: $(SCRIPTS)
	mkdir -p $(DESTDIR)/$(SCRIPTS_DIR)
	cp -p $(SCRIPTS) $(DESTDIR)/$(SCRIPTS_DIR)
	chmod 0755 $(DESTDIR)/$(SCRIPTS_DIR)/*
	install -D -m 0644 $(UDEV_RULE) \
		$(DESTDIR)/lib/udev/rules.d/$(UDEV_RULE)
