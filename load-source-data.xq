xquery version "3.1";

declare namespace xhtml="http://www.w3.org/1999/xhtml";

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

let $transform := 
    
return
    string-join($list, "&#10;")
    => serialize(
        map{
            "method":"text",
            "media-type":"text/plain"
        }
    )