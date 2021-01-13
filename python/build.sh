#!/bin/bash -x

# Copyright (c) 2018-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation
#

export SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)
export PYTHON_LS_VERSION=0.36.1
export PYTHON_IMAGE="registry.access.redhat.com/ubi8/python-38:1"

cd $SCRIPT_DIR
[[ -e target ]] && rm -Rf target

echo ""
echo "CodeReady Workspaces :: Stacks :: Language Servers :: Python Dependencies"
echo ""

mkdir -p target/python-ls

PODMAN=$(command -v podman || true)
if [[ ! -x $PODMAN ]]; then
  echo "[WARNING] podman is not installed."
 PODMAN=$(command -v docker || true)
  if [[ ! -x $PODMAN ]]; then
    echo "[ERROR] docker is not installed. Aborting."; exit 1
  fi
fi

${PODMAN} run --rm -v $SCRIPT_DIR/target/python-ls:/python -u root ${PYTHON_IMAGE} sh -c "
    /usr/bin/python3 --version && \
    /usr/bin/python3 -m pip install -q --upgrade pip && \
    /usr/bin/python3 -m pip install -q python-language-server[all]==${PYTHON_LS_VERSION} ptvsd jedi wrapt --prefix=/python && \
    /usr/bin/python3 -m pip install -q pylint --prefix=/python && \
    chmod -R 777 /python && \
    # fix exec line in pylint executable to use valid python interpreter - replace /opt/app-root/ with /usr/
    for d in \$(find /python/bin -type f); do sed -i \${d} -r -e 's#/opt/app-root/#/usr/#'; done && 
    export PATH=\${PATH}:/python/bin
    ls -la /python/bin
    cat /python/bin/pylint
    "
tar -czf target/codeready-workspaces-stacks-language-servers-dependencies-python-$(uname -m).tar.gz -C target/python-ls .

# ${PODMAN} rmi -f ${PYTHON_IMAGE}