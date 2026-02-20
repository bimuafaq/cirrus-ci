#!/bin/bash

# Load rovx as a function to allow environment exports
source rovx

setup_src() {
    repo init -u https://github.com/LineageOS/android.git -b lineage-18.1 --groups=all,-notdefault,-darwin,-mips --git-lfs --depth=1
    
    git clone -q https://codeberg.org/lin18-microG/local_manifests -b lineage-18.1 .repo/local_manifests
    git clone -q https://github.com/rovars/rom rovx

    rm -rf .repo/local_manifests/setup*
    mv rovx/script/device.xml .repo/local_manifests/

    rovx -c run_retry repo sync -j8 -c --no-clone-bundle --no-tags

    rm -rf external/AOSmium-prebuilt 
    rm -rf external/hardened_malloc
    rm -rf prebuilts/AuroraStore
    rm -rf packages/overlays/CaptivePortal204

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
    
    rm -rf packages/apps/Settings
    git clone https://github.com/bimuafaq/android_packages_apps_Settings packages/apps/Settings -b lineage-18.1 --depth=1

    rm -rf packages/apps/Trebuchet
    git clone https://github.com/bimuafaq/android_packages_apps_Trebuchet packages/apps/Trebuchet -b lineage-18.1 --depth=1

    rm -rf packages/apps/DeskClock
    git clone https://github.com/bimuafaq/android_packages_apps_DeskClock packages/apps/DeskClock -b lineage-18.1 --depth=1

    rm -rf packages/apps/LineageParts
    git clone https://github.com/bimuafaq/android_packages_apps_LineageParts packages/apps/LineageParts -b lineage-18.1 --depth=1

    rm -rf frameworks/opt/telephony
    git clone https://github.com/bimuafaq/android_frameworks_opt_telephony frameworks/opt/telephony -b lineage-18.1 --depth=1

    patch -p1 < $PWD/rovx/script/permissive.patch
    source $PWD/rovx/script/constify.sh

}

build_src() {
    source build/envsetup.sh
    rovx rbe

    export KBUILD_BUILD_USER=nobody
    export KBUILD_BUILD_HOST=android-build
    export BUILD_USERNAME=nobody
    export BUILD_HOSTNAME=android-build

    export OWN_KEYS_DIR="$PWD/rovx/keys"
    sudo ln -sf "$OWN_KEYS_DIR/releasekey.pk8" "$OWN_KEYS_DIR/testkey.pk8"
    sudo ln -sf "$OWN_KEYS_DIR/releasekey.x509.pem" "$OWN_KEYS_DIR/testkey.x509.pem"

    lunch lineage_RMX2185-user
    
    mka bacon
}

upload_src() {
    local release_file=$(find out/target/product -name "*-RMX*.zip" -print -quit)
    local release_name=$(basename "$release_file" .zip)
    local release_tag=$(date +%Y%m%d)
    local repo_releases="bimuafaq/releases"

    UPLOAD_GH=false

    if [[ -f "$release_file" ]]; then
        if [[ "${UPLOAD_GH}" == "true" && -n "$GITHUB_TOKEN" ]]; then
            echo "$GITHUB_TOKEN" > tokenpat.txt
            gh auth login --with-token < tokenpat.txt
            rm tokenpat.txt
            rovx tg post "Uploading to GitHub Releases..."
            gh release create "$release_tag" -t "$release_name" -R "$repo_releases" -F "rovx/script/notes.txt" || true
            if gh release upload "$release_tag" "$release_file" -R "$repo_releases" --clobber; then
                rovx tg post "GitHub Release upload successful: <a href=\"https://github.com/$repo_releases/releases/tag/$release_tag\">$release_name</a>"
            else
                rovx tg post "GitHub Release upload failed"
            fi
        fi

        unzip -q rovx/config.zip -d ~/.config
        rovx tg post "Uploading build result to Telegram..."
        if timeout 15m telegram-upload "$release_file" --to "$TG_CHAT_ID" --caption "$CIRRUS_COMMIT_MESSAGE"; then
            rovx tg post "Telegram upload successful"
        else
            rovx tg post "telegram-upload failed"
            return 1
        fi
    else
        rovx tg post "Build file not found"
        return 0
    fi
}

main() {
    case "${1:-}" in
        -s|--sync)
            setup_src
            ;;
        -b|--build)
            build_src 
            ;;
        -u|--upload)
            upload_src
            ;;
        *)
            echo "Usage: ./build.sh [FLAGS]"
            echo "Options:"
            echo "  -s, --sync      Sync source"
            echo "  -b, --build     Start build process"
            echo "  -u, --upload    Upload build results"
            return 1
            ;;
    esac
}

main "$@"