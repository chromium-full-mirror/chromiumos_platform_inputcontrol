#!/bin/sh
# Copyright (c) 2014 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Returns the CPI (counts per inch) of the newly attached mouse. Since mice
# generally don't report CPI, we use the following approach: By default, we
# assume a CPI of 1000, as this is quite close to most mice on the market today
# (2012 time frame). For mice that we know aren't near 1000, we have a database
# of CPI values.
get_mouse_cpi() {
  local xinput_id="$1"

  local vp="$(device_get_vendor_product $xinput_id)"

  # Database of mice that have CPI (DPI) significantly off from 1000.
  local cpi=1000;  # Default CPI
  local trackpoint_cpi=400;  # Approximate, since CPI doesn't exactly apply
  case "$vp" in
    "0002:000a") cpi=$trackpoint_cpi;;  # PS/2 IBM Trackpoint
    "045e:0024") cpi=400;;  # Microsoft Corp. Trackball Explorer*
    "045e:0040") cpi=416;;  # Microsoft Corp. Wheel Mouse Optical
    "0461:4d22") cpi=474;;  # Standard Dell
    "046d:1028") cpi=600;;  # M570 trackball[u]
    "046d:400e") cpi=400;;  # K400 touchpad[u]
    "046d:4024") cpi=400;;  # K400r touchpad[u]
    "046d:c00f") cpi=385;;  # Logitech MouseMan Traveler/Mobile
    "046d:c00"*) cpi=385;;  # Old Logitech Mice (copying 0xc00f setting)
    "046d:c014") cpi=425;;  # HP branded "Logitech Optical USB Mouse"
    "046d:c016") cpi=377;;  # HP branded "Logitech, Inc. Optical Wheel Mouse"
    "046d:c018") cpi=530;;  # "Logitech, Inc. Optical Wheel Mouse" model M-UAE96
    "046d:c03d") cpi=434;;  # Logitech M-BT96a Pilot Optical Mouse
    "046d:c03e") cpi=464;;  # Logitech Premium Optical Wheel Mouse (M-BT58)
    "046d:c077") cpi=580;;  # HP branded "Logitech USB Optical Mouse"
    # According to http://www.linux-usb.org/usb.ids , these are 4 trackballs:
    "046d:c40"*) cpi=300;;  # Logitech Trackballs*
    "046d:c508") cpi=300;;  # Cordless Trackball
    "047d:1002") cpi=300;;  # Kensington Turbo Mouse Pro (trackball)*
    "047d:1003") cpi=300;;  # Kensington Orbit TrackBall (trackball)*
    "047d:1005") cpi=300;;  # Kensington TurboBall (trackball)*
    "047d:1006") cpi=300;;  # Kensington TurboRing (trackball)*
    "047d:1009") cpi=300;;  # Kensington Orbit TrackBall for Mac (trackball)*
    "047d:1020") cpi=300;;  # Kensington Expert Mouse (trackball)*
    "047d:2041") cpi=300;;  # Kensington SlimBlade Trackball (trackball)*
    "04d9:2519") cpi=400;;  # FAVI Wireless Keyboard (TouchPad)*
    "05ac:0304") cpi=400;;  # Apple USB Optical Mouse (Mighty Mouse)
    "05ac:030c") cpi=400;;  # Apple BT Optical Mouse (Mighty Mouse)
    "05ac:030d") cpi=1780;; # Apple magicmouse (BT)
    "05ac:"*)    cpi=373;;  # Apple mice (other)
    "06cb:0009") cpi=$trackpoint_cpi;;  # USB IBM Trackpoint
    "0a5c:8502") cpi=400;;  # FAVI Wireless Keyboard (TouchPad), Bluetooth*
    "0c45:7000") cpi=400;;  # FAVI Entertainment Wireless Keyboard (TouchPad)*
    "1532:0016") cpi=1714;; # Razer USA, Ltd DeathAdder RZ01-0015
    "17ef:6009") cpi=$trackpoint_cpi;;  # Lenovo ThinkPad Keyboard w/ TrackPoint
    "17ef:6014") cpi=400;;  # Lenovo N5901 multimedia keyboard/trackball*
    "17ef:602b") cpi=400;;  # Lenovo N5902 multimedia keyboard/OFN*
    "1997:0409") cpi=400;;  # Riitek Rii Mote i6 (TouchPad)*
    "413c:3012") cpi=502;;  # Dell Computer Corp. Optical Wheel Mouse
  esac
  # * Trackball/touchpad measurements are approximate
  # [u] This device uses the unifying receiver
  echo $cpi
}