#!/bin/bash

# Test script. Output of this script can be saved and compared to test for regressions.
# Double-spacing between commands here makes the script output easier to read.

# We turn on exit on error, so that any status code changes cause a test failure.
set -e -o pipefail

prog_name=instaclone
base_dir=`dirname $0`
config=$base_dir/instaclone.yml
prog=$base_dir/../${prog_name}/main.py

args=
#args=--debug

# Run harness to set test config externally.
run() {
  $prog $args "$@"
}

# A trick to test for error conditions.
expect_error() {
  echo "(got expected error: status $?)"
}

# A trick to do ls portably, showing just permissions, file types, and symlinks.
ls_portable() {
  ls -lF "$@" | tail +2 | awk '{print $1, $9, $10, $11}'
}

# This will echo all commands as they are read. Bash commands plus their
# outputs will be used for validating regression tests pass (set -x is similar
# but less readable and sometimes not deterministic).
set -v

# --- Start of tests ---

unset INSTACLONE_DIR

# Platform and Python version we're using to run tests.
uname

python -V

run purge

# Error invocations.
run bad_command || expect_error

run configs

run configs test-dir

# Check contents before.
ls_portable

ls_portable test-dir/

ls_portable test-dir/subdir/

head -10 test-dir/file-* test-file{1,2}

run install || expect_error

run publish

# Check for results of publish.
ls_portable

ls_portable test-dir/

head -10 test-dir/file-* test-file{1,2}

# Publish again.
run publish || expect_error

run install -f

find $HOME/.instaclone/cache -type f

# Try cleaning cache again and re-installing.

run purge

# This should fail since we installed before.
run install || expect_error

run install -f

# Check contents once more.
ls_portable

ls_portable test-dir/

# Try a copy installation.
rm test-file1 test-file2 test-dir
rm -rf *.bak

run install --copy

ls_portable

ls_portable test-dir/

# Test installation of a single item, as well as command line override.
run install test-dir --local-path alt-test-dir

ls_portable

diff -r test-dir alt-test-dir

# Try non-default instaclone cache directory.
export INSTACLONE_DIR=/tmp/instaclone-dir
chmod -R +w $INSTACLONE_DIR || true
rm -rf $INSTACLONE_DIR

run install -f

# Leave files installed in case it's helpful to debug anything.

# --- End of tests ---
