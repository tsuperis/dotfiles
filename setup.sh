#!/bin/bash

cd $(dirname $0)

readonly ROOT_DIR=$(pwd)
readonly DOTFILES_DIR=$ROOT_DIR/files
readonly UTILITY_DIR=$ROOT_DIR/utils
readonly LOCAL_SCRIPT_DIR=$DOTFILES_DIR/bash_local
readonly BACKUP_DIR=$ROOT_DIR/backups

source $ROOT_DIR/utils/io.sh
source $ROOT_DIR/utils/cmd.sh

# --------------------------------------------------
# Main
# --------------------------------------------------

# initialize submodules
git submodule init
git submodule update --recursive --recommend-shallow --depth 1 

mkdir -p $BACKUP_DIR

# create symbolic links
function add_link() {
    echo "$1 ===> $2"
    ln -s "$1" "$2"
}

for f in `\ls $DOTFILES_DIR`; do
    src_path=$DOTFILES_DIR/$f
    dst_path=$HOME/.$f

    if [ ! -e "$dst_path" ]; then
        add_link "$src_path" "$dst_path"
    elif [ ! -L "$dst_path" ]; then
        warn -n "$dst_path is already exist. Do you want to override? [yN] "
        read OVERRIDE

        case $OVERRIDE in
            "" | [yY]* )
                mv "$dst_path" "$BACKUP_DIR/$f"
                add_link $src_path $dst_path
                ;;
            *)
                echo "cancel copy $src_path"
                ;;
        esac
    elif [ "$src_path" != "`\readlink $dst_path`" ]; then
        warn -n "$dst_path is already exist."
    fi
done

# --------------------------------------------------
# Import Utility
# --------------------------------------------------

readonly local UTILITY_SCRIPT="$LOCAL_SCRIPT_DIR/.utils.sh"

echo "#!$(which bash)" > $UTILITY_SCRIPT
for util_file in `\find "$UTILITY_DIR/" -type f -name \*.sh -or -name \*.bash`; do
    echo "source $util_file" >> $UTILITY_SCRIPT
done

# --------------------------------------------------
# Apply Config
# --------------------------------------------------

eval "$(cat $HOME/.bashrc | tail -n +10)"


# --------------------------------------------------
# Install Thirdparty
# --------------------------------------------------

# anyenv
if check-command anyenv; then
    readonly ANYENV_PLUGIN_DIR=$(anyenv root)/plugins
    mkdir -p $ANYENV_PLUGIN_DIR

    if ! [ -d $ANYENV_PLUGIN_DIR/anyenv-update ]; then
        git clone https://github.com/znz/anyenv-update.git ${ANYENV_PLUGIN_DIR}/anyenv-update
    fi
fi
