#!/usr/bin/env bash
set -e
source "$CI_DIR/build.sh"

_nfy_script() {
    tle -t "${CIRRUS_COMMIT_MESSAGE} ( <a href='https://cirrus-ci.com/task/${CIRRUS_TASK_ID}'>$CIRRUS_BRANCH</a> )"
    echo "$credensial" > ~/.git-credentials
    echo "$gitconfigs" > ~/.gitconfig
}

retry_rc() {
    local max_retries=20
    local delay=5
    local attempt=1
    
    while [[ $attempt -le $max_retries ]]; do
        "$@" && return 0
        [[ $attempt -lt $max_retries ]] && sleep "$delay"
        ((attempt++))
    done
    return 1
}

copy_cache() {
    mkdir -p ~/.ccache
    cd ~/
    
    if retry_rc rclone copy "$rclonedir/$rclonefile" . --progress; then
        tar -xzf "$rclonefile" -C .
        rm -f "$rclonefile"
        tle -t "Cache copied and extracted successfully"
    else
        rm -f "$rclonefile"
        tle -t "Cache not found on remote, proceeding without cache"
    fi
}

save_cache() {
    export CCACHE_DISABLE=1
    ccache -s    
    ccache --cleanup
    ccache --zero-stats

    cd ~/
    tar -czf "$rclonefile" -C . .ccache --warning=no-file-changed || {
        tle -t "Failed to create cache archive"
        return 1
    }

    if retry_rc rclone copy "$rclonefile" "$rclonedir" --progress; then
        rm -f "$rclonefile"
    else
        tle -t "Failed to copy cache to remote"
        return 1
    fi
}

set_ccache_vars() {
    export USE_CCACHE=1
    export CCACHE_EXEC="$(command -v ccache)"
    export CCACHE_DIR="$HOME/.ccache"
    ccache -M 50G -F 0
    ccache -o compression=true
}

unset_ccache_vars() {
    unset USE_CCACHE CCACHE_EXEC CCACHE_DIR USE_GOMA
}

main() {
    cd "$SRC_DIR"
    case "${1:-}" in
        sync) _nfy_script; setup_src ;;
        build) build_src ;;
        upload) upload_src ;;
        copy_cache) copy_cache ;;
        save_cache) save_cache ;;
        *)
            echo "Error: Invalid argument." >&2
            echo "Usage: $0 {sync|build|upload|copy_cache|save_cache}" >&2
            exit 1
            ;;
    esac
}

main "$@"