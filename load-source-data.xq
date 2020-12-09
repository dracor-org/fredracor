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

declare function local:prepare-ids($documentUrls as xs:string+) {
    let $ids :=
    element ids {
        attribute dateTime { current-dateTime() => string() },
        for $url at $pos in $documentUrls
        return
            element play {
                attribute dracor {'fre' || format-number($pos, '000000')},
                attribute orig { tokenize($url, '/')[last()] },
                attribute url {$url}
            }
    }
    return
        xmldb:store('/db', 'ids.xml', $ids, 'application/xml')
};

declare function local:write-on-filesystem($resource-name as xs:string, $node as node()) {
    let $path := '/fredracor/data'
    let $fsAvailable := file:is-directory($path)
    return
        if($fsAvailable)
        then
            let $options :=
                map{
                    'method': 'xml',
                    'omit-xml-declaration': false(),
                    'indent': true()
                }
            let $do := file:serialize($node, $path || '/' || $resource-name, $options)
            return () (: silence :)
        else () (: silence :)
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
    (: [position() lt 61]    DEBUG :)
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
            else util:log-system-out('got status ' || hc:send-request($request)/@status || 'for url ' || $url)
        } catch * {
            try {
                doc( $url )
            } catch * {
                util:log-system-out('got status ' || hc:send-request($request)/@status || 'for url ' || $url)
            }
        }
    return
        if(not($doc)) then () else 
        xmldb:store($targetCollectionPath, replace($filename, '%20', ''), $doc)

let $preprocessing :=
(: remove namespace to make all documents same :)
for $item in collection($targetCollectionPath)//tei:TEI/base-uri()
let $resource-name := tokenize($item, "/")[last()]
let $new := functx:change-element-ns-deep(doc($item), "", "")
return
    (xmldb:store($targetCollectionPath, $resource-name, $new),
    local:write-on-filesystem($resource-name, $new))

let $loadTeiAll := local:load-tei-all()

let $prepareIdList := local:prepare-ids($documentUrls)

return
    string-join($list, "&#10;")
    => serialize(
        map{
            "method":"text",
            "media-type":"text/plain"
        }
    )