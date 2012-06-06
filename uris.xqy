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

declare namespace fs="http://marklogic.com/xdmp/status/forest" ;

(: forests will be balanced within 3% :)
declare variable $TOLERANCE := xs:double(0.03) ;

(: This code is designed to minimize FLWOR expressions,
 : and maximize streaming.
 :)
declare variable $DATABASE-FORESTS := xdmp:database-forests(
  xdmp:database(), false()) ;

(: NB - pointless to count fragments,
 : because all fragments for a given document
 : must be co-resident in a single forest.
 :)
declare variable $COUNTS-MAP := (
  let $m := map:map()
  let $build := (
    for $f in $DATABASE-FORESTS
    return map:put(
      $m,
      string($f),
      sum(xdmp:forest-counts($f, 'document-count')/fs:document-count)))
  return $m) ;

declare variable $COUNTS-MAP-AVG as xs:double := avg(
  map:get($COUNTS-MAP, map:keys($COUNTS-MAP))) ;

declare variable $COUNTS-MAX := (1.0 + $TOLERANCE) * $COUNTS-MAP-AVG ;

declare variable $COUNTS-MIN := (1.0 - $TOLERANCE) * $COUNTS-MAP-AVG ;

declare variable $SOURCE-FOREST-IDS as xs:unsignedLong* := (
  let $d := xdmp:log(
    text { 'corb-rebalancer/uris.xqy: max =', $COUNTS-MAX }, 'debug')
  for $f in map:keys($COUNTS-MAP)
  let $id := xs:unsignedLong($f)
  where map:get($COUNTS-MAP, $f) gt $COUNTS-MAX
  return (
    $id,
    xdmp:log(
      text {
        'corb-rebalancer/uris.xqy: adding source forest',
        $f, xdmp:forest-name($id) },
      'debug'))) ;

(: Calculate number of documents to move, based on document count :)
declare variable $LIMIT-COUNT as xs:long := (
  (: best to truncate, not round - default to not moving anything :)
  xs:long(
    sum(
      for $f in $SOURCE-FOREST-IDS
      return map:get($COUNTS-MAP, string($f)) - $COUNTS-MAP-AVG))) ;

declare variable $TARGET-FOREST-IDS as xs:unsignedLong* := (
  let $d := xdmp:log(
    text { 'corb-rebalancer/uris.xqy: min =', $COUNTS-MIN }, 'debug')
  for $f in map:keys($COUNTS-MAP)
  let $id := xs:unsignedLong($f)
  where map:get($COUNTS-MAP, $f) lt $COUNTS-MIN
  return (
    $id,
    xdmp:log(
      text {
        'corb-rebalancer/uris.xqy: adding target forest',
        $f, xdmp:forest-name($id) },
      'debug'))) ;

(: This is a little sloppy. We could loop through the forests
 : and select the "right" number of uris for each,
 : but this way we can stream. If the results
 : aren't satisfying, just run it again.
 :)
declare variable $URIS := cts:uris(
  (), (
    'document',
    for $i in ('limit', 'sample', 'truncate')
    return concat($i, '=', $LIMIT-COUNT)),
  (: fodder for the sample and truncate options :)
  cts:and-query(()),
  (),
  $SOURCE-FOREST-IDS) ;

declare function local:server-fields-set() as empty-sequence()
{
  let $set := xdmp:set-server-field(
    'com.blakeley.corb-rebalancer.forests',
    $TARGET-FOREST-IDS)
  return ()
};

(: module body :)
if (exists($SOURCE-FOREST-IDS)) then () else error(
  (), 'CRB-EMPTYSOURCES',
  text {
    'No forests are overloaded by the set tolerance', $TOLERANCE })
,
if (exists($TARGET-FOREST-IDS)) then () else error(
  (), 'CRB-EMPTYTARGETS',
  text {
    'No forests are underloaded by the set tolerance', $TOLERANCE })
,
(: Ready to proceed.
 : NB - Keep this order of expressions,
 : so that the URIS are known before the field is set,
 : but the field is set before the tasks begin to spawn.
 :)
xdmp:log(text {'corb-rebalancer/uris.xqy: LIMIT', $LIMIT-COUNT }),
count($URIS),
local:server-fields-set(),
$URIS

(: uris.xqy :)
