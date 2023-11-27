#!/bin/bash -e

# Check if UID and GID are passed as environment variables, if not, extract from the space folder owner
if [ -z "$PUID" ]; then
    # Get the UID of the folder owner
    PUID=$(stat -c "%u" "$SB_FOLDER")
    echo "Will run SilverBullet with UID $PUID, inferred from the owner of $SB_FOLDER (set PUID environment variable to override)"
fi
if [ -z "$PGID" ]; then
    # Get the GID of the folder owner
    PGID=$(stat -c "%g" "$SB_FOLDER")
fi

if [ "$PUID" -eq "0" ]; then
    echo "Will run SilverBullet as root"
    deno run -A --unstable /silverbullet.js $@
else
    # Create silverbullet user and group ad-hoc mapped to PUID and PGID
    groupadd -g $PGID silverbullet
    useradd -M -u $PUID -g $PGID silverbullet
    # And make sure /deno-dir (Deno cache) is accessible
    chown -R $PUID:$PGID /deno-dir
    # And run via su as the newly mapped 'silverbullet' user
    args="$@"
    su silverbullet -s /bin/bash -c "deno run -A --unstable /silverbullet.js $args"
fi

