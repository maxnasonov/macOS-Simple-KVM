#!/bin/bash

# make.sh: Generate customized libvirt XML.
# by Foxlet <foxlet@furcode.co>

[[ -z "$VM_NAME" ]] && {
    echo "Error: please provide VM_NAME"
    exit 1
}

if [[ -z "$VMDIR" ]]; then
    VMDIR=$PWD
fi

MAC_ADDRESS=$(python /scripts/random_mac_for_macos.py)
UUID=$(uuidgen)
MACHINE="$(qemu-system-x86_64 --machine help | grep q35 | cut -d" " -f1 | grep -Eoe ".*-[0-9.]+" | sort -rV | head -1)"
OUT="/tmp/template.xml"

print_usage() {
    echo
    echo "Usage: $0"
    echo
    echo " -a, --add   Add XML to virsh (uses sudo)."
    echo
}

error() {
    local error_message="$*"
    echo "${error_message}" 1>&2;
}

generate(){
    sed -e "s|VMDIR|$VMDIR|g" -e "s|VM_NAME|$VM_NAME|g" -e "s|MAC_ADDRESS|$MAC_ADDRESS|g" -e "s|UUID|$UUID|g"  -e "s|MACHINE|$MACHINE|g" tools/template.xml.in > $OUT
    echo "$OUT has been generated in $VMDIR"
}

generate

argument="$1"
case $argument in
    -a|--add)
        sudo virsh define $OUT
        ;;
    -h|--help)
        print_usage
        ;;
esac
