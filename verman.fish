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
    set -l cmds "node" "python" "ruby"
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
            eval "_verman_$i" $ver "$verman_config/$i/$ver"
            or continue
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
        echo "echo VERSION > .COMMAND-version"
        echo "verman"
    end | fish_indent --ansi | command sed 's/^/  /'
    echo $c
    echo "where COMMAND can be one of: "
    echo "  node, ruby, python or go"
    echo
    echo "Docs: <github.com/fisherman/verman>"
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

function _verman_make -a source target
    pushd "$source"
    ./configure --prefix="$target"
    command make
    command make install
    popd
    command rm -rf "$source"
end

function _verman_python -a ver target
    _verman_tar_get "python" "https://www.python.org/ftp/python" "$ver/Python-$ver.tar.xz" "$target-build"
    _verman_make "$target-build" "$target"
    if test -L "$target/bin/python3"
        command ln -s "$target/bin/python3" "$target/bin/python"
    end
end

function _verman_ruby -a ver target
    _verman_tar_get "ruby" "https://cache.ruby-lang.org/pub/ruby" "ruby-$ver.tar.gz" "$target-build"
    _verman_make "$target-build" "$target"
end

function _verman_node -a ver target
    set -l os (uname -s)
    switch "$os"
        case Linux
            set -l arch (uname -m)
            if test "$arch" = "x86_64"
                set arch 64
            else
                set arch 86
            end
            set file "node-v$ver-linux-x$arch.tar.gz"
        case Darwin
            set file "node-v$ver-darwin-x64.tar.gz"
        case \*
            return 2
    end
    _verman_tar_get "node" "http://nodejs.org/dist" "v$ver/$file" "$target"
end
