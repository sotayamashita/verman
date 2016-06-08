[slack-link]: https://fisherman-wharf.herokuapp.com
[slack-badge]: https://fisherman-wharf.herokuapp.com/badge.svg
[travis-link]: https://travis-ci.org/fisherman/verman
[travis-badge]: https://img.shields.io/travis/fisherman/verman.svg

[fish]: https://fishshell.com
[fisherman]: https://github.com/fisherman/fisherman

[![][travis-badge]][travis-link]
[![][slack-badge]][slack-link]

# Verman

Verman is a multi-command version manager in [fish] >=2.3.

## Install

Manually

```
curl -Lo ~/.config/fish/functions/verman.fish --create-dirs git.io/verman
```

With [fisherman]

```
fisher i verman
```

## Usage

```fish
echo VERSION > .COMMAND-version
verman
```

For example, to use Node.js 6.2.0:

```fish
echo 6.2.0 > .node-version
verman
```
```fish
node -v
v6.2.0
```

## Supported languages

* [x] Node.js
* [ ] Python
* [ ] Ruby
* [ ] Golang
* [ ] Haskell

## Automatic version switching

Create a shim for the command to auto-switch in your ~/.config/fish/functions, e.g, for Node.js:

```fish
function node -d "Server-side JavaScript runtime"
    verman "node"
    command node $argv
end
```

## Global versions

Create the .command-version file inside your $HOME directory.

```fish
echo 6.2.0 > ~/.node-version
```

## Customize download mirror

For example, to use an alternatve Node.js binary mirror:

```fish
set -U verman_node_mirror "http://npm.taobao.org/mirrors/node"
```
