#!/usr/bin/env bash

setup_src() {
    repo init -u https://github.com/LineageOS/android.git -b lineage-17.1
    git clone -q https://github.com/rovars/rom xx
    mkdir -p .repo/local_manifests/
    mv xx/10/lin10.xml .repo/local_manifests
    repo sync -j8
}

build_src() {    
    source build/envsetup.sh

    repopick -f 378458 || exit 1
    #2023-03-05
    repopick -f 352333 || exit 1
    cp -v ./android/default.xml ./.repo/manifests/ || exit 1
    repo sync -v -j 1 -c --no-tags --no-clone-bundle --force-sync --fail-fast 2>&1 external/zlib || exit 1
    repopick -f -t Q_asb_2023-03 || exit 1
    #2023-04-05
    repopick -f -t Q_asb_2023-04 || exit 1
    #2023-05-05
    repopick -f -t Q_asb_2023-05 || exit 1
    #2023-06-05
    repopick -f -t Q_asb_2023-06 || exit 1
    #2023-07-05
    repopick -f 362202 || exit 1
    cp -v ./android/default.xml ./.repo/manifests || exit 1
    repo sync -v -j 1 -c --no-tags --no-clone-bundle --force-sync --fail-fast tools/apksig 2>&1 || exit 1
    repopick -f -t Q_asb_2023-07 || exit 1
    #2023-08-05
    repopick -f 365443 || exit 1
    cp -v ./android/default.xml ./.repo/manifests || exit 1
    repo sync -v -j 1 -c --no-tags --no-clone-bundle --force-sync --fail-fast system/ca-certificates 2>&1 || exit 1
    repopick -f -t Q_asb_2023-08 || exit 1
    #2023-09-05
    repopick -f -t Q_asb_2023-09 || exit 1
    #2023-10-05
    repopick -f 376554 || exit 1
    cp -v ./android/default.xml ./.repo/manifests/ || exit 1
    repo sync -v -j 1 -c --no-tags --no-clone-bundle --force-sync --fail-fast 2>&1 external/libxml2 2>&1 || exit 1
    repopick -f -t Q_asb_2023-10 || exit 1
    #2023-11-05
    repopick -f 376556 || exit 1
    cp -v ./android/default.xml ./.repo/manifests/ || exit 1
    repo sync -v -j 1 -c --no-tags --no-clone-bundle --force-sync --fail-fast 2>&1 external/webp || exit 1
    repopick -f -t prp-Q-for-CVE-2023-4863 || exit 1
    repopick -f -t CVE-2023-4863 || exit 1
    repopick -f 376555 || exit 1
    cp -v ./android/default.xml ./.repo/manifests/ || exit 1
    repo sync -v -j 1 -c --no-tags --no-clone-bundle --force-sync --fail-fast 2>&1 external/libcups || exit 1
    repopick -f -t Q_asb_2023-11 || exit 1
    #2023-12-05
    repopick -f 377251 || exit 1
    cp -v ./android/default.xml ./.repo/manifests || exit 1
    repo sync -v -j 1 -c --no-tags --no-clone-bundle --force-sync --fail-fast external/pdfium 2>&1 || exit 1
    repopick -f -t Q_asb_2023-12 || exit 1
    #2024-01-05
    repopick -f -t Q_asb_2024-01 || exit 1
    #2024-02-05
    repopick -f -t Q_asb_2024-02 || exit 1
    #2024-03-05
    repopick -f -t Q_asb_2024-03 || exit 1
    #2024-04-05
    repopick -f -t Q_asb_2024-04 || exit 1
    #2024-05-05
    repopick -f -t Q_asb_2024-05 || exit 1
    #2024-06-05
    repopick -f -t Q_asb_2024-06 || exit 1
    #2024-07-05
    repopick -f -t Q_asb_2024-07 || exit 1
    #2024-08-05
    repopick -f -t Q_asb_2024-08 || exit 1
    #2024-09-05
    repopick -f -t Q_asb_2024-09 || exit 1
    #2024-10-05
    repopick -f -t Q_asb_2024-10 || exit 1
    #2024-11-05
    repopick -f -t Q_asb_2024-11 || exit 1
    #2024-12-05
    repopick -f -t Q_asb_2024-12 || exit 1
    #2025-01-05
    repopick -f 418454 || exit 1
    cp -v ./android/default.xml ./.repo/manifests || exit 1
    repo sync -v -j 1 -c --no-tags --no-clone-bundle --force-sync --fail-fast external/giflib 2>&1 || exit 1
    repopick -f -t Q_asb_2025-01 || exit 1
    #2025-02-05
    repopick -t Q_asb_2025-02 || exit 1
    #2025-03-05
    repopick -f 421785 || exit 1
    cp -v ./android/default.xml ./.repo/manifests || exit 1
    repo sync -v -j 1 -c --no-tags --no-clone-bundle --force-sync --fail-fast external/dng_sdk 2>&1 || exit 1
    repopick -t Q_asb_2025-03 || exit 1
    #2025-04-05
    repopick -t Q_asb_2025-04 || exit 1
    #2025-05-05
    repopick -t Q_asb_2025-05 || exit 1
 
    export OWN_KEYS_DIR=$PWD/xx/keys
    sudo ln -s $OWN_KEYS_DIR/releasekey.pk8 $OWN_KEYS_DIR/testkey.pk8
    sudo ln -s $OWN_KEYS_DIR/releasekey.x509.pem $OWN_KEYS_DIR/testkey.x509.pem

    # brunch RMX2185 user
}

upload_src() {
    REPO="rovars/release"
    RELEASE_TAG="lineage-17.1"
    ROM_FILE=$(find out/target/product -name "*-RMX*.zip" -print -quit)
    ROM_X="https://github.com/$REPO/releases/download/$RELEASE_TAG/$(basename "$ROM_FILE")"

    echo "$tokenpat" > tokenpat.txt
    gh auth login --with-token < tokenpat.txt

    if ! gh release view "$RELEASE_TAG" -R "$REPO" > /dev/null 2>&1; then
    gh release create "$RELEASE_TAG" -t "$RELEASE_TAG" -R "$REPO" --generate-notes
    fi

    #gh release upload "$RELEASE_TAG" "$ROM_FILE" -R "$REPO" --clobber

    echo "$ROM_X"
    MSG_XC2="( <a href='https://cirrus-ci.com/task/${CIRRUS_TASK_ID}'>Cirrus CI</a> ) - $CIRRUS_COMMIT_MESSAGE ( <a href='$ROM_X'>$(basename "$CIRRUS_BRANCH")</a> )"
    xc -s "$MSG_XC2"

    mkdir -p ~/.config
    mv x/config/* ~/.config
    timeout 15m telegram-upload $ROM_FILE --to $idtl --caption "$CIRRUS_COMMIT_MESSAGE"
}