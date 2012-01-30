#!/bin/sh
#
# sample bash script for running corb-rebalancer
#
# Copyright (c)2011 Michael Blakeley.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# The use of the Apache License does not indicate that this project is
# affiliated with the Apache Software Foundation.
#
#
# USAGE: see README.md
#

XQY=rebalance.xqy
URIS=uris.xqy
ROOT=/

set -x
set -e

XCC=$1
shift

THREADS=2
if [ -n "$1" ]; then
    THREADS=$1
    shift;
fi

if [ -n "$1" ]; then
    URIS=$1
    shift
fi

VMARGS=$*

# look for GNU readlink first (OS X, BSD, Solaris)
set +e
READLINK=`type -P greadlink`
set -e
if [ -z "$READLINK" ]; then
    # if readlink is not GNU-style, setting BASE will fail
    READLINK=`type -P readlink`
fi
BASE=`$READLINK -f $0`
BASE=`dirname $BASE`
if [ -z "$BASE" ]; then
    echo Error initializing environment from $READLINK
    $READLINK --help
    exit 1
fi

echo BASE=$BASE

cd $BASE

if [ -r corb.jar ]; then
    ls -l corb.jar
else
    wget -O corb.jar http://marklogic.github.com/corb/corb.jar
fi
CP=$BASE:corb.jar

if [ -r marklogic-xcc-5.0.1.jar ]; then
    ls -l corb.jar
else
    wget -O /tmp/xcc.zip \
        http://developer.marklogic.com/download/binaries/5.0/MarkXCC.Java-5.0-1.zip
    unzip -j /tmp/xcc.zip lib/marklogic-xcc-5.0.1.jar
fi
CP=$CP:marklogic-xcc-5.0.1.jar

CORB=com.marklogic.developer.corb.Manager
JAVA=java
if [ -n "$JAVA_HOME" ]; then
    JAVA=$JAVA_HOME/bin/java
fi

$JAVA -cp $CP $VMARGS $CORB $XCC '' $XQY $THREADS $URIS $ROOT 0 0

# crb.sh
