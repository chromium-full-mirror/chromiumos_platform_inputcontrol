#!/bin/sh
# Copyright (c) 2014 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

XINPUT=/usr/bin/xinput

export DISPLAY=:0
export XAUTHORITY=/home/chronos/.Xauthority

pref_folder="/home/chronos/user/cmt"
if ! [ -d $pref_folder ]; then
  mkdir $pref_folder
fi
chown chronos:chronos $pref_folder

# Functions for storing preferences
# A preference requires the following global variables:
# pref_${pref}_type: device type this preference is appllied on
# pref_${pref}_validator: a batch match to validate the preference value
# pref_${pref}_default: default value
# apply_${pref}: function to apply the preference to a device
# Also a list of all preference names is stored in the variable: preferences

apply_preference() {
  local pref="$1"
  local type="$(eval echo \"\${pref_${pref}_type}\")"
  local value="$3"
  for device in $2; do
    if device_is_${type} $device; then
      log "Applying $pref=$value to device $device"
      apply_${pref} "$device" "$value"
    fi
  done
}

apply_all_preferences() {
  local devices="$1"
  for pref in $preferences; do
    local value=$(load_preference $pref)
    for device in $devices; do
      apply_preference $pref $device $value
    done
  done
}

validate_preference() {
  local pref="$1"
  local value="$2"
  local validator="$(eval echo \"\${pref_${pref}_validator}\")"
  case $value in
    $validator) true ;;
    *)
      echo "invalid value '${value}' for preference ${pref}" >&2
      false
    ;;
  esac
}

transition_legacy_pref_file() {
  local pref=$1
  local new_file="$pref_folder/$pref"

  case $pref in
    "mouse_sensitivity") filename="mouse_sensitivity" ;;
    "touchpad_sensitivity") filename="touchpad_sensitivity" ;;
    "mouse_swap_lr") filename="mouse_swap_lr_buttons" ;;
    "tapclick") filename="touchpad_tap_enable" ;;
    "tapdrag") filename="touchpad_tap_drag_enable" ;;
    "t5r2_three_finger_click") filename="touchpad_t5r2_3f_click_enable" ;;
    *) return ;;
  esac

  legacy_file="/home/chronos/user/$filename"
  if [ -f $legacy_file ]; then
    log "mv $legacy_file $new_file"
    mv $legacy_file $new_file
    chown chronos:chronos $new_file
  fi
}

load_preference() {
  assert_eq $# 1
  local pref="$1"
  local default="$(eval echo \"\${pref_${pref}_default}\")"
  local file="$pref_folder/$pref"

  # The new inputcontrol script uses a different file path to store preferences
  # Make sure to copy the old setting over when the new file does not yet exist.
  if [ ! -f $file ]; then
    transition_legacy_pref_file $pref
  fi

  if [ ! -f $file ]; then
    echo $default
    return
  fi

  local file_size="$(stat -c %s $file)"
  if [ "$file_size" != "2" ]; then
    # invalid file size
    echo $default
    return
  fi

  local value=$(cat ${file})
  if validate_preference $pref $value; then
    echo $value
  else
    echo $default
  fi
}

save_preference() {
  assert_eq $# 2
  local pref="$1"
  local value="$2"
  local pref_file="$pref_folder/$pref"

  if validate_preference "$pref" "$value"; then
    log "echo $value > $pref_file"
    echo "$value" > $pref_file
  fi
}

# Functions to access information about a device

device_get_name() {
  assert_eq $# 1
  xinput --list --name-only $1
}

device_get_canonical_name() {
  assert_eq $# 1
  device_get_name $device | sed 's/[^a-zA-Z0-9]/_/g'
}

device_set_prop() {
  assert_eq $# 3
  log "$XINPUT set-prop \"$1\" \"$2\" \"$3\""
  $XINPUT set-prop "$1" "$2" "$3"
}

device_get_prop() {
  assert_eq $# 2
  $XINPUT list-props $1 | awk "/$2/ { print \$4 }"
}

device_get_bool_prop() {
  assert_eq $# 2
  prop=$(device_get_prop $1 "$2")
  [ "$prop" = "1" ]
}

device_is_mouse() {
  assert_eq $# 1
  device_get_bool_prop $1 "Device Mouse"
}

device_is_multitouch() {
  assert_eq $# 1
  device_get_bool_prop $1 "Device Touchpad"
}

device_is_touchpad() {
  assert_eq $# 1
  ! device_is_mouse $1 && device_is_multitouch $1
}

device_is_multitouch_mouse() {
  assert_eq $# 1
  device_is_mouse $1 && device_is_multitouch $1
}

device_is_nontouch_mouse() {
  assert_eq $# 1
  device_is_mouse $1 && ! device_is_multitouch $1
}

device_is_touchscreen() {
  assert_eq $# 1
  device_get_name $1 | grep -q '[tT]ouch[sS]creen'
}

device_is_valid() {
  assert_eq $# 1
  device_is_mouse $1 || device_is_multitouch $1 || device_is_touchscreen $1
}

device_status() {
  assert_eq $# 1
  if device_is_valid $1; then
    echo
    echo "ID $1:"
    $XINPUT list-props $1
  fi;
}

# Functions to list devices

list_devices() {
  # optional first argument is filter method
  local filter=device_is_valid
  if ! [ -z $1 ]; then
    filter=$1
  fi

  # Search for an xinput entry that contains the "slave pointer"
  # Then, find a field that matches "id=".
  # Lastly, return the part of the field after the '='.
  local devices="$($XINPUT list | \
    awk '/.*slave.*/ { for (i=1; i<NF; i++) \
    if ($i ~/id=/) print substr($i, 4) }')"

  for device in $devices ; do
    if $filter $device; then
      echo -n " ${device}"
    fi
  done
}

list_mice() {
  list_devices device_is_mouse
}

list_touchpads() {
  list_devices device_is_touchpad
}

list_touchscreens() {
  list_devices device_is_touchscreen
}

list_multitouch() {
  list_devices device_is_multitouch
}

list_multitouch_mice() {
  list_devices device_is_multitouch_mouse
}

# Returns the xinput ID of the newly attached mouse. If X hasn't loaded a driver
# for the new mouse, yet, this will not print anything. If found, it prints the
# xinput ID.
get_device_by_devname() {
  # Get the list of xinput IDs:
  local ids="$(list_devices)"
  if [ -z "$ids" ]; then
    return
  fi
  for id in $ids; do
    local test_node=$(device_get_prop $id "Device Node")
    if [ "$test_node" = "\"$1\"" ]; then
      echo $id
      return
    fi
  done
}

wait_and_get_added_device() {
  tries=10
  while [ "$tries" -ne "0" ]; do
    tries=$((tries - 1))
    newid=$(get_device_by_devname $1)
    if [ -n "$newid" ]; then
      echo $newid
      return
    fi
    sleep 1
  done
}


canonical_ids() {
  # In case minus number is passed, truncate it to the last 4 hexdigits.
  # e.g., -16360 -> ffffffffffffc018 -> c018
  local id_strings id_str first
  read id_strings
  for id_str in $id_strings; do
    if [ -n "$first" ]; then
      printf ":"
    fi
    printf "%04x" "$id_str" | sed 's/.*\(.\{4\}\)$/\1/'
    first="not"
  done
}

device_get_vendor_product() {
  local xinput_id="$1"

  local vp="$(xinput list-props $xinput_id 2>/dev/null \
              | fgrep "Device Product ID" | \
              cut -d : -f 2 | sed 's/,//' | canonical_ids)"
  if ! echo "${vp}" | grep -q ':'; then
    vp="$(xinput list-props $xinput_id 2>/dev/null \
          | fgrep "Device Vendor ID" | \
          cut -d : -f 2 | canonical_ids)"
    vp="${vp}:$(xinput list-props $xinput_id 2>/dev/null \
          | fgrep "Device Product ID" | \
          cut -d : -f 2 | canonical_ids)"
  fi
  echo "$vp"
}


# Helper for debugging in bash

log() {
  if [ ${FLAGS_verbose} -eq ${FLAGS_TRUE} ] ; then
    echo "$@" >&2
  fi
}

assert_eq() {
  if [ "$1" -ne "$2" ]; then
    echo "${FUNCNAME[1]}: Assertion '$1' == '$2' failed" >&2
    exit -1
  fi
}

# FUNCNAME is only available in BASH. Disable assert_eq on all other shells.
if [ -z "$BASH_VERSION" ]; then
  assert_eq() { true; }
fi
