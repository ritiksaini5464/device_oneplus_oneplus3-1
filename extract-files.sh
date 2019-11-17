#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

DEVICE=oneplus3
VENDOR=oneplus

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

VALIDUS_ROOT="$MY_DIR"/../../..

HELPER="$VALIDUS_ROOT"/vendor/validus/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC=$1
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$VALIDUS_ROOT" false "$CLEAN_VENDOR"

extract "$MY_DIR"/proprietary-files.txt "$SRC" "$SECTION"

"$MY_DIR"/setup-makefiles.sh

DEVICE_BLOB_ROOT="$VALIDUS_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary

CAMERA_HAL="$DEVICE_BLOB_ROOT"/vendor/lib/hw/camera.msm8996.so

sed -i \
    -e 's/_ZN7qcamera17QCameraParameters16setQuadraCfaModeEjb/_ZN7qcamera17QCameraParameters16setQuadraCfaModSHIM/' \
    -e 's/_ZN7qcamera17QCameraParameters12setQuadraCfaERKS0_/_ZN7qcamera17QCameraParameters12setQuadraCfaERSHIM/' \
    -e 's/_ZN7qcamera17QCameraParameters12getQuadraCfaEv/_ZN7qcamera17QCameraParameters12getQuadraCSHIM/' \
    -e 's/_ZN7qcamera15isOneplusCameraEv/_ZN7qcamera15isOneplusCameSHIM/' \
    -e 's/_ZN7qcamera17QCameraParameters15is3p8spLowLightEv/_ZN7qcamera17QCameraParameters15is3p8spLowLigSHIM/' \
    -e 's/_ZN7qcamera17QCameraParameters21handleSuperResoultionEv/_ZN7qcamera17QCameraParameters21handleSuperResoultiSHIM/' \
    -e 's/_ZN7qcamera17QCameraParameters17isSuperResoultionEv/_ZN7qcamera17QCameraParameters17isSuperResoultiSHIM/' \
    "$CAMERA_HAL"

#
# Correct android.hidl.manager@1.0-java jar name
#
sed -i "s|name=\"android.hidl.manager-V1.0-java|name=\"android.hidl.manager@1.0-java|g" \
    "$DEVICE_BLOB_ROOT"/etc/permissions/qti_libpermissions.xml

patchelf --set-soname "vulkan.msm8996.so" "$DEVICE_BLOB_ROOT"/vendor/lib/hw/vulkan.msm8996.so
patchelf --set-soname "vulkan.msm8996.so" "$DEVICE_BLOB_ROOT"/vendor/lib64/hw/vulkan.msm8996.so
