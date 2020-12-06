xquery version "3.1";

declare namespace functx = "http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

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

declare function local:load-tei-all() as xs:string {
    let $filename := 'tei_all.rng'
    let $url := 'https://tei-c.org/release/xml/tei/custom/schema/relaxng/' || $filename
    let $request := <hc:request method="get" href="{$url}"/>
    let $data := hc:send-request($request)[2]
    
    return
        xmldb:store("/db", $filename, $data, 'application/xml')
};

let $baseUrl := "http://theatre-classique.fr/pages"
let $request :=
    <hc:request method="get" href="{$baseUrl}/programmes/PageEdition.php"/>
let $response := 
    hc:send-request($request)
let $documentUrls := 
    $response[2]//xhtml:a[contains(@href, '/documents/')][starts-with(@href, '..')]/string(@href)
let $count := 
    count($documentUrls)

let $targetCollectionName := "data"
let $targetCollectionPath := "/db/" || $targetCollectionName
let $prepareCollection :=
    if(xmldb:collection-available($targetCollectionPath))
    then xmldb:remove($targetCollectionPath)
    else true()
let $createCollection := xmldb:create-collection("/db", $targetCollectionName)
let $list := 
    for $url at $pos in $documentUrls
    let $filename := tokenize($url, "/")[last()] 
        => replace("\s", "%20") (: MARIVAUX _ACTEURSDEBONNEFOI.xml :)
    let $log := util:log-system-out( $pos || "/" || $count || ": " ||$filename)
    let $url := $baseUrl || "/documents/" || $filename
    let $doc := 
        try {
            let $request :=
                <hc:request method="get" href="{$url}" />
            let $response := 
                hc:send-request($request)
            return if(hc:send-request($request)/@status = "200")
            then $response[2]
            else <error href="{$url}">{ $response }</error>
        } catch * {
            try {
                doc( $url )
            } catch * {
                <error href="{$url}">Can not get document.</error>
            }
        }
    return
        xmldb:store($targetCollectionPath, $filename, $doc)

let $preprocessing :=
(: remove namespace to make all documents same :)
for $item in collection($targetCollectionPath)//tei:TEI/base-uri()
let $resource-name := tokenize($item, "/")[last()]
let $new := functx:change-element-ns-deep(doc($item), "", "")
return
    xmldb:store($targetCollectionPath, $resource-name, $new)

let $loadTeiAll := local:load-tei-all()

return
    string-join($list, "&#10;")
    => serialize(
        map{
            "method":"text",
            "media-type":"text/plain"
        }
    )