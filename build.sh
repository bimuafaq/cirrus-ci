#!/usr/bin/env bash

# Import automation features from Docker environment
source /opt/cirrus_env

setup_src() {
    repo init -u https://github.com/LineageOS/android.git -b lineage-18.1 --groups=all,-notdefault,-darwin,-mips --git-lfs --depth=1

    git clone -q https://github.com/rovars/rom xx
    git clone -q https://codeberg.org/lin18-microG/local_manifests -b lineage-18.1 .repo/local_manifests

    rm -rf .repo/local_manifests/setup*
    mv xx/device/device.xml .repo/local_manifests/

    run_retry repo sync -j8 -c --no-clone-bundle --no-tags

    rm -rf external/AOSmium-prebuilt 
    rm -rf external/hardened_malloc
    rm -rf prebuilts/AuroraStore
    rm -rf prebuilts/prebuiltapks

    rm -rf external/chromium-webview
    git clone -q https://github.com/LineageOS/android_external_chromium-webview external/chromium-webview -b master --depth=1

    rm -rf lineage-sdk
    git clone https://github.com/bimuafaq/android_lineage-sdk lineage-sdk -b lineage-18.1 --depth=1

    rm -rf build/make
    git clone https://github.com/bimuafaq/android_build_make build/make -b lineage-18.1 --depth=1

    rm -rf system/core
    git clone https://github.com/bimuafaq/android_system_core system/core -b lineage-18.1 --depth=1

    rm -rf vendor/lineage
    git clone https://github.com/bimuafaq/android_vendor_lineage vendor/lineage -b lineage-18.1 --depth=1

    rm -rf frameworks/base
    git clone https://github.com/bimuafaq/android_frameworks_base frameworks/base -b lineage-18.1 --depth=1
    sed -i 's#\(<bool[^>]*name="config_cellBroadcastAppLinks"[^>]*>\)\s*true\s*\(</bool>\)#\1false\2#g' frameworks/base/core/res/res/values/config.xml
    grep -n 'config_cellBroadcastAppLinks' frameworks/base/core/res/res/values/config.xml

    rm -rf packages/apps/Settings
    git clone https://github.com/bimuafaq/android_packages_apps_Settings packages/apps/Settings -b lineage-18.1 --depth=1

    rm -rf packages/apps/Trebuchet
    git clone https://github.com/rovars/android_packages_apps_Trebuchet packages/apps/Trebuchet -b wip --depth=1


    rm -rf packages/apps/DeskClock
    git clone https://github.com/rovars/android_packages_apps_DeskClock packages/apps/DeskClock -b exthm-11 --depth=1

    rm -rf packages/apps/LineageParts
    git clone https://github.com/bimuafaq/android_packages_apps_LineageParts packages/apps/LineageParts -b lineage-18.1 --depth=1

    rm -rf frameworks/opt/telephony
    git clone https://github.com/bimuafaq/android_frameworks_opt_telephony frameworks/opt/telephony -b lineage-18.1 --depth=1

    patch -p1 < $PWD/xx/device/permissive.patch

    chmod +x $PWD/xx/device/constify.sh
    source $PWD/xx/device/constify.sh
}

build_src() {
    source build/envsetup.sh
    rbe_setup

    export OWN_KEYS_DIR="$PWD/xx/keys"
    sudo ln -sf "$OWN_KEYS_DIR/releasekey.pk8" "$OWN_KEYS_DIR/testkey.pk8"
    sudo ln -sf "$OWN_KEYS_DIR/releasekey.x509.pem" "$OWN_KEYS_DIR/testkey.x509.pem"

    lunch lineage_RMX2185-user
    mka bacon
}

upload_src() {
    local release_file=$(find out/target/product -name "*-RMX*.zip" -print -quit)

    if [[ -f "$release_file" ]]; then
        cp xx/config/* ~/.config
        tg_post "Uploading build result to Telegram..."
        if timeout 15m telegram-upload "$release_file" --to "$TG_CHAT_ID" --caption "$CIRRUS_COMMIT_MESSAGE"; then
            tg_post "Upload successful"
        else
            tg_post "telegram-upload failed"
            return 1
        fi
    else
        tg_post "Build file not found"
        return 1
    fi
}

main "$@"