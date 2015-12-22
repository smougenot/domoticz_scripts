#!/usr/bin/env bash
#
# Find device by mac address
# Check if they ping
# Report device status

_netMask='192.168.1.0/24'
_login=
_password=
_domoticz=192.168.1.17
_port=8080
_device_file=devices.txt

function info {
  echo -e "$1"
}

#
# Scan to find devices
function scan {
  info "scanning network ${_netMask}"
  # update arp table by full scanning my IPs
  fping -g -c 1 -r 1 "$_netMask"
}

#
# $1 mac of the device to check
_deviceStatus=
function checkDevice {
  _deviceStatus=0
  # find ip in arp
  _infos=$(arp -n | grep -i $1)
  info "device : '$_infos'"
  re="([0-9.]+)"
  if [[ $_infos =~ ([0-9\.]+) ]]; then
    echo "bash found ${BASH_REMATCH[1]}"
    ping -c 2 -W 2 -q ${BASH_REMATCH[1]}
    _ret=$?
    if [ $_ret -eq 0 ]; then
      _deviceStatus=1
    fi
  fi
  # ping

}

# update status
function sendStatus {
  info "device $1 status $2"
  curl -s "http://${_login}:${_password}@${_domoticz}:${_port}/json.htm?type=command&param=udevice&idx=$1&nvalue=$2"
}

#
# Run check
#

scan

# config MAC/domoticz id
while read _mac _idx; do
  info "Checking MAC: ${_mac}, idx: ${_idx}"
  # check device is here
  checkDevice ${_mac}
  # send status
  sendStatus ${_idx} ${_deviceStatus}
done < ${_device_file}

