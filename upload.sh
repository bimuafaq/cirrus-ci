#!/bin/bash

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
            rovx tg post "GitHub Release upload successful: <a href="https://github.com/$repo_releases/releases/tag/$release_tag">$release_name</a>"
        else
            rovx tg post "GitHub Release upload failed"
        fi
    fi
    mkdir -p ~/.config
    unzip -q rox/config.zip -d ~/.config
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
