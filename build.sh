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

repopick -it Q_asb_2023-03;
repopick -it Q_asb_2023-04;
repopick -it Q_asb_2023-05;
repopick -it Q_asb_2023-06;
repopick -it Q_asb_2023-07;
repopick -it Q_asb_2023-08;
repopick -it Q_asb_2023-09;
repopick -it Q_asb_2023-10;
repopick -it Q_asb_2023-11;
repopick -it Q_asb_2023-12;
repopick -it Q_asb_2024-01;
repopick -it Q_asb_2024-02;
repopick -it Q_asb_2024-03;
repopick -it Q_asb_2024-04;
repopick -it Q_asb_2024-05;
repopick -it Q_asb_2024-06;
repopick -it Q_asb_2024-07;
repopick -it Q_asb_2024-08;
repopick -it Q_asb_2024-09;
repopick -it Q_asb_2024-10;
repopick -it Q_asb_2024-11;
repopick -it Q_asb_2024-12;
repopick -it Q_asb_2025-01;
repopick -it Q_asb_2025-02;
repopick -it Q_asb_2025-03;
repopick -it Q_asb_2025-04;
repopick -it Q_asb_2025-05;
 
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