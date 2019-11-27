#!/bin/bash

OSK="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"

[[ -z "$MAC_ADDRESS" ]] && {
    MAC_ADDRESS=$(python /scripts/random_mac_for_macos.py)
}

[[ -z "$MEM" ]] && {
	MEM="1G"
}

[[ -z "$CPUS" ]] && {
	CPUS=1
}

[[ -z "$INSTALLATION_DISK" ]] && {
    INSTALLATION_DISK=BaseSystem.img
}

[[ -z "$VM_NAME" ]] && {
    VM_NAME=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
}

if [[ -z "$VMDIR" ]]; then
    VMDIR=$PWD
else
    cp $PWD/firmware/OVMF_CODE.fd $VMDIR/${VM_NAME}_OVMF_CODE.fd
    cp $PWD/firmware/OVMF_VARS-1024x768.fd $VMDIR/${VM_NAME}_OVMF_VARS-1024x768.fd
    cp $PWD/ESP.qcow2 $VMDIR/${VM_NAME}_ESP.qcow2
fi

[[ -z "$VMDIR/${VM_NAME}.qcow2" ]] && {
    echo "Please set the SYSTEM_DISK environment variable"
    exit 1
}

[[ -r "$VMDIR/${VM_NAME}.qcow2" ]] || {
    echo "Can't read system disk image: $VMDIR/${VM_NAME}.qcow2"
    exit 1
}


MOREARGS=()

[[ "$HEADLESS" = "1" ]] && {
    MOREARGS+=(-nographic -vnc 127.0.0.1:0,to=100 -k en-us)
}

qemu-system-x86_64 \
    -name ${VM_NAME} \
    -enable-kvm \
    -m $MEM \
    -machine q35,accel=kvm \
    -smp $CPUS \
    -cpu Penryn,vendor=GenuineIntel,kvm=on,+sse3,+sse4.2,+aes,+xsave,+avx,+xsaveopt,+xsavec,+xgetbv1,+avx2,+bmi2,+smep,+bmi1,+fma,+movbe,+invtsc \
    -device isa-applesmc,osk="$OSK" \
    -smbios type=2 \
    -drive if=pflash,format=raw,readonly,file="$VMDIR/${VM_NAME}_OVMF_CODE.fd" \
    -drive if=pflash,format=raw,file="$VMDIR/${VM_NAME}_OVMF_VARS-1024x768.fd" \
    -vga qxl \
    -usb -device usb-kbd -device usb-tablet \
    -netdev user,id=net0 \
    -device e1000-82545em,netdev=net0,id=net0,mac=${MAC_ADDRESS} \
    -device ich9-ahci,id=sata \
    -drive id=ESP,if=none,format=qcow2,file="$VMDIR/${VM_NAME}_ESP.qcow2" \
    -device ide-hd,bus=sata.2,drive=ESP \
    -drive id=InstallMedia,format=raw,if=none,file="${INSTALLATION_DISK}" \
    -device ide-hd,bus=sata.3,drive=InstallMedia \
    -drive id=SystemDisk,if=none,file="$VMDIR/${VM_NAME}.qcow2" \
    -device ide-hd,bus=sata.4,drive=SystemDisk \
    "${MOREARGS[@]}"
