set -g verman_version 1.0
complete -xc verman -n __fish_use_subcommand -a version -d "Show version info"
complete -xc verman -n __fish_use_subcommand -a help  -d "Show usage help"

function verman -a cmd
    switch "$argv"
        case -v {--,-,}version
            echo "verman version $verman_version" (command uname) (fish_realpath (status -f) | string replace ~ \~)
            return
        case -h {--,-,}help
            _verman_help > /dev/stderr
            return
        case -\*
            echo "verman: '$argv[1]' is not a valid option" > /dev/stderr
            _verman_help > /dev/stderr
            return 1
    end

    if test -z "$XDG_CONFIG_HOME"
        set XDG_CONFIG_HOME ~/.config
    end
    set -g verman_config "$XDG_CONFIG_HOME/verman"

    command mkdir -p "$verman_config"
    or return

    set -l flag -g
    set -l cmds "node" "go" "ruby"
    set -e fish_user_paths

    if test ! -z "$cmd"
        if contains -- "$cmd" $cmds
            set cmds "$cmd"
        else
            echo "verman: not implemented: '$cmd'" > /dev/stderr
            return 1
        end
    end

    for i in $cmds
        set -l ver
        set -l bin

        for ver_file in {,~/}."$i"-version
            if test -f "$ver_file"
                read ver < "$ver_file"
                switch (printf "%.1s" "$ver")
                    case \*"#"
                        set -e ver
                        continue
                end
                if test -z "$ver"
                    echo "verman: empty version file: '$ver_file'" > /dev/stderr
                    continue
                end
                break
            end
        end

        if test -z "$ver"
            continue
        end

        set bin "$verman_config/$i/$ver/bin"
        if test ! -d "$bin"
            eval "_verman_$i" "$ver" "$verman_config/$i/$ver"
        end

        if test -d "$bin"
            if not contains -- "$bin" $fish_user_paths
                set -U fish_user_paths "$bin" $fish_user_paths
            end
        end
    end
end

function _verman_help
    set -l c (set_color normal)
    echo "Usage:"
    begin
        echo "echo x.x.x > .command-version"
        echo "verman"
    end | fish_indent --ansi | command sed 's/^/  /'
    echo $c
    echo "Supported commands:"
    echo "    node"
    echo "    go"
    echo "    ruby"
end

function _verman_tar_get -a cmd mirror file target
    set -l _mirror "verman_$cmd_mirror"
    if test ! -z "$$_mirror"
        set mirror "$$_mirror"
    end

    set -l url "$mirror/$file"
    set file (string split / $file)[-1]
    echo "$url" > /dev/stderr
    command mkdir -p "$target"
    pushd "$target"

    if not command curl --fail --progress-bar -SLO "$url"
        command rm -rf "$target"
        popd
        echo "verman: download error: $url" > /dev/stderr
        return 1
    end

    command tar -zx --strip-components=1 < "$file"
    command rm -f "$file"
    popd
end

function _verman_node -a ver target file
    switch (uname -s)
        case Linux
            set -l arch (uname -m)
            test "$arch" = "x86_64"
            and set arch 64
            or set arch 86
            set file "node-v$ver-linux-x$arch.tar.gz"
        case Darwin
            set file "node-v$ver-darwin-x64.tar.gz"
        case \*
            return 2
    end
    _verman_tar_get "node" "https://nodejs.org/dist" "v$ver/$file" "$target"
end

function _verman_go -a ver target file
    switch (uname -s)
        case Linux
            set -l arch (uname -m)
            test "$arch" = "x86_64"
            and set arch "amd64"
            or set arch "386"
            set file "go$ver.linux-$arch.tar.gz"
        case Darwin
            set file "go$ver.darwin-amd64.tar.gz"
        case \*
            return 2
    end
    _verman_tar_get "go" "https://golang.org/dl" "$file" "$target"
    set -Ux GOROOT "$target"
end

function _verman_ruby -a ver target file
    switch (uname -s)
        case Darwin
            sw_vers -productVersion | string split "." | read -lz 1 2 _
            set file "osx/$1.$2/x86_64/ruby-$ver.tar.bz2"
        case \*
            return 2
    end
    _verman_tar_get "ruby" "https://rvm.io/binaries" "$file" "$target"
end
