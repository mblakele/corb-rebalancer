xquery version "1.0-ml";

(:
 : Copyright (c) 2011-2012 Michael Blakeley. All Rights Reserved.
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 : http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : The use of the Apache License does not indicate that this project is
 : affiliated with the Apache Software Foundation.
 :
 :)

(:
 : This is a test script.
 : It sets up CoRB to move all documents into the first available forest.
 :
 : If you wish to alter it for other purposes, it is fairly easy to understand.
 :)

declare variable $DATABASE-FORESTS := xdmp:database-forests(
  xdmp:database(), false());

declare variable $URIS := cts:uris(
  (),
  'document',
  (),
  (),
  subsequence($DATABASE-FORESTS, 2)) ;

declare function local:server-fields-set() as empty-sequence()
{
  let $set := xdmp:set-server-field(
    'com.blakeley.corb-rebalancer.forests',
    $DATABASE-FORESTS[1])
  return ()
};

count($URIS),
local:server-fields-set(),
$URIS

(: uris-first-forest.xqy :)
