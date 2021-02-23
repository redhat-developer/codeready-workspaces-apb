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

export KAMEL_VERSION="1.3.1"
export GOLANG_IMAGE="registry.access.redhat.com/ubi8/go-toolset:1.14.7-15"

cd $SCRIPT_DIR
[[ -e target ]] && rm -Rf target

echo ""
echo "CodeReady Workspaces :: Kamel"
echo ""

mkdir -p target/kamel

PODMAN=$(command -v podman || true)
if [[ ! -x $PODMAN ]]; then
  echo "[WARNING] podman is not installed."
 PODMAN=$(command -v docker || true)
  if [[ ! -x $PODMAN ]]; then
    echo "[ERROR] docker is not installed. Aborting."; exit 1
  fi
fi

${PODMAN} run --rm -v $SCRIPT_DIR/target/kamel:/kamel -u root ${GOLANG_IMAGE} sh -c "
    wget https://github.com/apache/camel-k/archive/v${KAMEL_VERSION}.tar.gz -O /tmp/camel-k-client-${KAMEL_VERSION}-src.tar.gz
    cd /tmp
    tar xzf /tmp/camel-k-client-${KAMEL_VERSION}-src.tar.gz
    ls -1 camel*
    cd camel-k-${KAMEL_VERSION}
    make build-kamel
    cp  /tmp/camel-k-${KAMEL_VERSION}/kamel /kamel/kamel
    "
tar -czf target/kamel-${KAMEL_VERSION}-$(uname -m).tar.gz -C target/kamel .

${PODMAN} rmi -f ${GOLANG_IMAGE}
