xquery version "3.1";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace functx = "http://www.functx.com";
declare function functx:change-element-ns-deep
  ( $nodes as node()* ,
    $newns as xs:string ,
    $prefix as xs:string )  as node()* {

  for $node in $nodes
  return if ($node instance of element())
         then (element
               {QName ($newns,
                          concat($prefix,
                                    if ($prefix = '')
                                    then ''
                                    else ':',
                                    local-name($node)))}
               {$node/@*,
                functx:change-element-ns-deep($node/node(),
                                           $newns, $prefix)})
         else if ($node instance of document-node())
         then functx:change-element-ns-deep($node/node(),
                                           $newns, $prefix)
         else $node
 } ;

let $nodes := collection("/db/data")//tei:TEI/base-uri()

for $node in $nodes
let $new := functx:change-element-ns-deep(doc($node), "", "")
return
    xmldb:store("/db/data", $node, $new)