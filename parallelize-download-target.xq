xquery version "3.1";
let $collection-uri := "/db/transformed"

for $item in xmldb:get-child-resources($collection-uri)
let $doc := doc($collection-uri || "/" || $item)
let $export := file:serialize($doc, "/fredracor/transformed/" || $item, (), false())
return
    xmldb:remove($collection-uri)