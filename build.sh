#!/usr/bin/env bash

setup_src() {
    repo init -u https://github.com/LineageOS/android.git -b lineage-18.1 --groups=all,-notdefault,-darwin,-mips --git-lfs --depth=1

    git clone -q https://github.com/rovars/rom x
    git clone -q https://codeberg.org/lin18-microG/local_manifests .repo/local_manifests
    rm -rf .repo/local_manifests/setup*
    mv x/11/device.xml .repo/local_manifests/

    sed -i 's#<project path="build/make" name="lin18-microG/android_build_make" groups="pdk" remote="codeberg" >#<project path="build/make" name="bimuafaq/android_build_make" groups="pdk" remote="github" >#g' .repo/local_manifests/updates.xml

    retry_rc repo sync -j8 -c --no-clone-bundle --no-tags

    rm -rf external/AOSmium-prebuilt
    rm -rf external/chromium-webview
    git clone -q --depth=1 https://github.com/LineageOS/android_external_chromium-webview -b master external/chromium-webview

    zpatch=$rom_src/z_patches
    xpatch=$rom_src/x/11

    patch -p1 < $xpatch/*build.patch  

    rm -rf vendor/lineage
    git clone https://github.com/bimuafaq/android_vendor_lineage vendor/lineage -b lineage-18.1 --depth=1

    rm -rf frameworks/base
    git clone https://github.com/bimuafaq/android_frameworks_base frameworks/base -b lineage-18.1 --depth=1

    rm -rf packages/apps/Settings
    git clone https://github.com/bimuafaq/android_packages_apps_Settings packages/apps/Settings -b lineage-18.1 --depth=1

    rm -rf packages/apps/Trebuchet
    git clone https://github.com/rovars/android_packages_apps_Trebuchet packages/apps/Trebuchet -b exthm-11 --depth=1

    rm -rf packages/apps/DeskClock
    git clone https://github.com/rovars/android_packages_apps_DeskClock -b exthm-11 --depth=1

    git clone -q https://github.com/rovars/build r

    cd packages/apps/LineageParts
    rm -rf src/org/lineageos/lineageparts/lineagestats/ res/xml/anonymous_stats.xml res/xml/preview_data.xml
    git am $rom_src/r/Patches/LineageOS-18.1/android_packages_apps_LineageParts/0001-Remove_Analytics.patch
    cd $rom_src

}

build_src() {
    source build/envsetup.sh
    setup_rbe_vars
 
    export INSTALL_MOD_STRIP=1
    export BOARD_USES_MTK_HARDWARE=true
    export MTK_HARDWARE=true
    export USE_OPENGL_RENDERER=true

    export KBUILD_BUILD_USER=nobody
    export KBUILD_BUILD_HOST=android-build
    export BUILD_USERNAME=nobody
    export BUILD_HOSTNAME=android-build

    export OWN_KEYS_DIR=$rom_src/x/keys
    # export RELEASE_TYPE=UNOFFICIAL

    sudo ln -s $OWN_KEYS_DIR/releasekey.pk8 $OWN_KEYS_DIR/testkey.pk8
    sudo ln -s $OWN_KEYS_DIR/releasekey.x509.pem $OWN_KEYS_DIR/testkey.x509.pem
    
    brunch RMX2185 user 2>&1 | tee build.txt
}

upload_src() {
    REPO="rovars/release"
    RELEASE_TAG="lineage-18.1"
    ROM_FILE=$(find out/target/product -name "*-RMX*.zip" -print -quit)
    ROM_X="https://github.com/$REPO/releases/download/$RELEASE_TAG/$(basename "$ROM_FILE")"

    echo "$tokenpat" > tokenpat.txt
    gh auth login --with-token < tokenpat.txt

    if ! gh release view "$RELEASE_TAG" -R "$REPO" > /dev/null 2>&1; then
        gh release create "$RELEASE_TAG" -t "$RELEASE_TAG" -R "$REPO" --generate-notes
    fi

    gh release upload "$RELEASE_TAG" "$ROM_FILE" -R "$REPO" --clobber

    echo "$ROM_X"
    MSG_XC2="( <a href='https://cirrus-ci.com/task/${CIRRUS_TASK_ID}'>Cirrus CI</a> ) - $CIRRUS_COMMIT_MESSAGE ( <a href='$ROM_X'>$(basename "$CIRRUS_BRANCH")</a> )"
    xc -s "$MSG_XC2"

    mkdir -p ~/.config
    mv x/config/* ~/.config
    timeout 15m telegram-upload $ROM_FILE --to $idtl --caption "$CIRRUS_COMMIT_MESSAGE"
    xc -c "build.txt"
}