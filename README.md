Corb Scripts for Forest Rebalancing
===

Sometimes a MarkLogic Server database will have several forests.
If the forests are present from the time when the database was created,
they will each have approximately the same number of forests.
But if the administrator adds more forests later on,
the newer forests will tend to have fewer documents.
In cases like this, we can rebalance the forests.

But before using this tool, consider that
rebalancing is generally slower than clearing the database and reloading.
That is because every document must be updated,
and updates are more expensive than inserts.
So rebalancing the forests may not be the best way to solve the problem.
If you have the luxury of clearing the database and reloading everything, do it.

Finally, note that following this procedure may result in forests
containing many deleted fragments. To recover disk space,
you may wish to force some forests to merge.

Setup
---

This project contains a shell script and a pair of XQuery modules,
intended for use with [CoRB](http://marklogic.github.com/corb/).
Corb requires a configured XDBC server,
and the root of that XCC server must contain the corb-rebalancer modules:

    uris.xqy
    rebalance.xqy

If Corb crashes with `SVC-FILOPN` then the root is likely to be the problem.
Check your settings carefully.

When run, `crb.sh` will download jar files for Corb and XCC.
If you are not connected to the Internet, then you must place both jar files
in the corb-rebalance directory.

    [corb.jar](http://marklogic.github.com/corb/corb.jar)
    [marklogic-xcc-5.0.1.jar](http://developer.marklogic.com/products/xcc/5.0)

The MarkLogic XCC client API is generally backward-compatible,
so this jar file should also work with earlier versions of the server.

Usage
---

    ./crb.sh XCC [ THREADS [ URIS [ VMARGS ] ] ]

Normally only the first two arguments will be used.
An XCC connection string is of the form:

    xcc://user:password@host:port/database-name

where the database-name is optional. The corresponding XDBC application server
must be listening on the correct port, and the corb-rebalancer XQuery
must be in its root directory.

The default value of THREADS is 2. To speed up processing,
try setting it to twice the number of CPU threads. For example,
a Xeon E5645 CPU has 12 threads. So for a pair of those CPUs
you might try 48 threads.

Troubleshooting
---

As mentioned above, `SVC-FILOPN` generally means that CoRB
cannot find the `uris.xqy` and `rebalance.xqy` modules.
Make sure they are in the root directory as specified for the XDBC server,
and that the modules database is set to `(filesystem)`.
Make sure that the MarkLogic Server process can read the files.

The error CRB-EMPTYSOURCES means that the forests are already well-balanced.
Note that these scripts only look at document counts, not fragment counts.
That is because sub-fragments of a document must all live in the same forest.
Also, this tool does not balance on-disk size.
For most workloads, document count is the more appropriate metric.

If CoRB reports "nothing to process" then the forests are already well-balanced.
If you disagree, check to make sure that CoRB is using the right database,
either in the XCC connection string or in the XDBC server configuration.

License
---
Copyright (c) 2011 Michael Blakeley. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

The use of the Apache License does not indicate that this project is
affiliated with the Apache Software Foundation.

