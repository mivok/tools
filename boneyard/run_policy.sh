#!/bin/bash
# Runs a policyfile on a remote server over ssh, installing chef if necessary.
# Similar to chef-run/chef-apply with chef workstation, but works with a
# policyfile instead, and with fewer options.
#
# Steps:
# * Runs chef update (and/or chef install) on the policyfile
# * Generates a policyfile export
# * Copies the export to the server
# * Installs chef if it isn't there already
# * Runs chef on the server

set -euo pipefail

WORKDIR="chef_policy"
REMOTE_HOST="$1"
POLICYFILE="${2:-Policyfile.rb}"

function msg() {
    local HIGHLIGHT
    HIGHLIGHT="$(tput setaf 2)$(tput bold)"
    local NORMAL
    NORMAL="$(tput sgr0)"
    echo "$HIGHLIGHT* $*$NORMAL"
}

if [[ -z $1 ]]; then
    echo "Usage: $0 [USER@]HOSTNAME [POLICYFILERB]"
    exit 1
fi

if [[ ! -e "$POLICYFILE" ]]; then
    echo "ERROR: $POLICYFILE doesn't exist. Please make sure this file"
    echo "exists and run this command again."
    exit 1
fi

TMPDIR=$(mktemp -d)

msg "Running chef update or chef install"
chef update "$POLICYFILE" || chef install "$POLICYFILE"
msg "Running chef export"
chef export -a "$POLICYFILE" "$TMPDIR"

msg "Making $WORKDIR on remote side"
# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "mkdir -p $WORKDIR"

msg "Copying over policyfile export"
cd "$TMPDIR" || exit 1
ARCHIVE_FILE=$(ls -- *.tgz)
scp "$ARCHIVE_FILE" "$REMOTE_HOST:$WORKDIR/"
cd - || exit 1
rm -rf "$TMPDIR"

msg "Creating remote script"
# shellcheck disable=SC2029 disable=SC2087
ssh "$REMOTE_HOST" "cat > $WORKDIR/doit.sh" <<EOF
#!/bin/bash
set -euo pipefail
cd ~/$WORKDIR

function msg() {
    local HIGHLIGHT
    HIGHLIGHT="$(tput setaf 6)$(tput bold)"
    local NORMAL
    NORMAL="$(tput sgr0)"
    echo "\$HIGHLIGHT* \$*\$NORMAL"
}

msg "Removing any old policyfile exports"
rm -rf .chef cookbook_artifacts policies policy_groups \\
    Policyfile.lock.json README.md

msg "Extracting the policyfile archive"
tar xvzf "$ARCHIVE_FILE" --no-overwrite-dir

msg "Removing policyfile archive"
rm -f "$ARCHIVE_FILE"

if ! command -v chef-client > /dev/null; then
    msg "Installing chef"
    curl -o install.sh -L https://www.chef.io/chef/install.sh
    chmod +x install.sh
    sudo ./install.sh
fi

msg "Running chef-client -z"
sudo chef-client -z
EOF

msg "Running remote script"
# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "chmod +x $WORKDIR/doit.sh; sudo $WORKDIR/doit.sh"
