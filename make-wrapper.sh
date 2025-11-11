#!/bin/bash
# Wrapper script that allows running 'make dev' from subdirectories
# Usage: alias make='bash /path/to/make-wrapper.sh' (or just use directly)

# If Makefile exists in current directory, use it normally
if [ -f "Makefile" ]; then
    /usr/bin/make "$@"
    exit $?
fi

# Otherwise, find parent Makefile and use it
CURRENT_DIR="$(pwd)"
PARENT_DIR="$(dirname "$CURRENT_DIR")"

while [ "$PARENT_DIR" != "/" ]; do
    if [ -f "$PARENT_DIR/Makefile" ] && [ -d "$PARENT_DIR/docker" ] && [ -d "$PARENT_DIR/scripts" ]; then
        # Use parent Makefile, but run from current directory
        /usr/bin/make -C "$CURRENT_DIR" -f "$PARENT_DIR/Makefile" "$@"
        exit $?
    fi
    PARENT_DIR="$(dirname "$PARENT_DIR")"
done

# No parent Makefile found, try system make (will error if no Makefile)
/usr/bin/make "$@"

