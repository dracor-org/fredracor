xquery version "3.1";

declare namespace tei='http://www.tei-c.org/ns/1.0';

declare variable $continue :=
    (: set to true to preserve older transformations.
       set to false to remove all previouse transformations at first.
    :)
    true();

declare variable $who-tokenize-pattern := '/|,';

declare function local:translate($string as xs:string)
as xs:string{
    let $work :=
        translate(lower-case($string), "*[]’' áàâéèêíìîóòôúùû", '------aaaeeeiiiooouuu')
        => replace('^\-', '')
        => replace('^\d', 'num')
        => replace('^[|]$', '')
    return
        (: quality assurance :)
        if($work => matches('^\s*?$'))
        then 'empty-string'
        else $work
};

declare function local:transform($nodes) {
    for $node in $nodes
    return
        typeswitch ( $node )
            case text() return $node
            case comment() return $node
            case processing-instruction() return $node
            case element(div1) return
                element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@*,
                local:transform($node/node())
            }
            case element(div2) return
                element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@*,
                local:transform($node/node())
            }
            case element(sp) return
                element {QName('http://www.tei-c.org/ns/1.0', 'sp')} {
                $node/@* except $node/@who,
                attribute who {
                    tokenize($node/@who, $who-tokenize-pattern) ! ('#' || local:translate(.))},
                local:transform($node/node())
            }
            case element(s) return
                (: minor correction to prevent multiple usage of an ID :)
                element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except ($node/@id, $node/@n),
                attribute n {string($node/@id)},
                local:transform($node/node())
            }
            case element(l) return
                (: minor correction to prevent multiple usage of an ID :)
                (: removing unknown attributes @syll, @part :)
                (element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except ($node/@id, $node/@n, $node/@syll, $node/@part),
                attribute n {string($node/@id)},
                $node/@part ! attribute part {upper-case(.)},
                if(not($node/@n)) then () else comment {'WARNING: source contains @n as well. it is removed here.'},
                local:transform($node/node())
            }, if($node/@syll) then comment { '@syll=' || string($node/@syll)  } else ())
            case element(role) return
                (: correct invalid IDs here as well :)
                (: removing unknown attributes @sex, @type, @statut, @age, @stat_amour :)
                (element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except ($node/@id, $node/@sex, $node/@type, $node/@statut, $node/@age, $node/@stat_amour),
                attribute corresp {'#' || local:translate(string($node/@id))},
                local:transform($node/node())
            }, comment {
                ($node/@sex, $node/@type, $node/@statut, $node/@age, $node/@stat_amour)
                ! ('@' || local-name(.) || '=' || string(.))
            })
            case element(docDate) return
                (: correct unknown @value to @when :)
                element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except $node/@value,
                attribute when { $node/@value },
                local:transform($node/node())
            }
            case element(docAuthor) return
                (: remove unused and invalid @id, may replaced by @sameAs, @ref or @corresp :)
                element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except $node/@id,
                local:transform($node/node())
            }
            case element(privilege) return
                (: remove unknown element :)
                element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except $node/@id,
                local:transform($node/node())
            }
            case element(set) return
                comment {
                    'usage of set in correct place but with unknown attributes',
                    serialize($node)
                }
        default return
            element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@*,
                local:transform($node/node())
            }
};

let $target-collection := '/db/transformed',
    $cleanup := if( xmldb:collection-available($target-collection) and not($continue))
                then xmldb:remove($target-collection)
                else true(),
    $create := if($continue) then () else xmldb:create-collection('/db', 'transformed')

let $collection-uri := '/db/data/'
for $resource at $pos in xmldb:get-child-resources($collection-uri)
(: set position to continue previouse transformation :)
(: where $pos gt 1330:)

let $log := util:log-system-out('preapring ' || $pos || '.')
let $doc := doc('/db/data/' || $resource)
let $title := 
    if($doc//*:titlePart/@type="main")
    then
        for $titlePart in $doc//*:titlePart[@type="main"]
        return
            element {QName('http://www.tei-c.org/ns/1.0', 'title')} {
                attribute type {'main'},
                string($titlePart)
            }
    else
        element {QName('http://www.tei-c.org/ns/1.0', 'title')} {
            attribute type {'main'},
            $doc//*:fileDesc[1]/*:titleStmt[1]/*:title[1]/text()
        }
let $subtitle := 
    if($doc//*:titlePart/@type="sub")
    then
        for $titlePart in $doc//*:titlePart[@type="sub"]
        return
            element {QName('http://www.tei-c.org/ns/1.0', 'title')} {
                attribute type {'sub'},
                string($titlePart)
            }
    else
        ()
let $author :=
    for $author in $doc//*:author
    let $isni := 
        if($author/@ISNI)
        then attribute key {"isni:" || replace($author/@ISNI, "\s", "")}
        else ()
    let $name := string($author)
    return
        element {QName('http://www.tei-c.org/ns/1.0', 'author')} {
            $isni,
            $name
        }
let $editor := 
    if($doc//*:editor)
    then
        for $node in $doc//*:teiHeader//*:editor
        let $string := string($node)
        let $name1 :=
            if($string => contains('par '))
            then $string => substring-after('par ')
            else $string
        let $name2 :=
            if($name1 => contains(', '))
            then $name1 => substring-before(", ")
            else $name1
        return
            element {QName('http://www.tei-c.org/ns/1.0', 'editor')} {$name2}
    else ()

let $tei :=
<TEI xmlns='http://www.tei-c.org/ns/1.0' xml:lang="fre">
    <teiHeader>
        <fileDesc>
            <titleStmt>
                {$title}
                {$author}
                {$editor}
            </titleStmt>
            <publicationStmt>
                <publisher xml:id="dracor">DraCor</publisher>
                <idno type="URL">https://dracor.org</idno>
                <idno type="dracor" xml:base="https://dracor.org/id/">fre{format-number($pos, '000000')}</idno>
                <availability>
                    <licence>
                        <ab>CC BY NC SA 3.0</ab>
                        <ref target="https://creativecommons.org/licenses/by-nc-sa/3.0/de/">Licence</ref>
                    </licence>
                </availability>
                <!-- idno type="wikidata" xml:base="https://www.wikidata.org/entity/"></idno -->
            </publicationStmt>
            <sourceDesc>
                <bibl type="digitalSource">
                    <name>Théâtre Classique </name>
                    <idno type="URL">http://theatre-classique.fr/pages/programmes/edition.php?t=../documents/{$resource}</idno>
                    <idno type="URL">http://theatre-classique.fr/pages/documents/{$resource}</idno>
                    <availability>
                        <licence>
                            <ab>CC BY NC SA 3.0</ab>
                            <ref target="https://creativecommons.org/licenses/by-nc-sa/3.0/de/">Licence</ref>
                        </licence>
                    </availability>
                    <bibl type="originalSource">
                        <date type="print" when="{string(($doc//*:docDate)[1]/@value)}">{string(($doc//*:docDate)[1]/@value)}</date>{ if(($doc//*:docDate)[2]) then comment {'WARNING: multiple docDate elements found in source.'} else () }
                        <date type="premiere">{attribute when {string(($doc//*:premiere)[1]/@date)}}{string(($doc//*:premiere)[1])}</date>{ if(($doc//*:premiere)[2]) then comment {'WARNING: multiple premiere elements found in source.'} else () }
                        <date type="written"/>
                        <idno type="URL">{string($doc//*:permalien)}</idno>
                    </bibl>
                </bibl>
            </sourceDesc>
        </fileDesc>
        <profileDesc>
            <particDesc>
                <listPerson>
{
    for $who in (($doc//*:text//*:sp/tokenize(@who, $who-tokenize-pattern) => distinct-values()) ! local:translate(.))
    (: inconsistent usage of @id with @who. we have to translate/normalize to match. :)
    let $castItem := $doc//*:role[local:translate(@id) eq $who]/parent::*
    let $sex := switch (string($castItem[1]/*:role[1]/@sex))
        case "1" return "MALE"
        case "2" return "FEMALE"
        default return "UNKNOWN"
    let $comment :=
        if($castItem[2])
        then comment {'WARNING: multiple roles/castItems found in source, may result of local:translate#1'}
        else ()
    let $persName := string($castItem[1]/*:role)
    let $persName := substring($persName, 1, 1) || lower-case(substring($persName, 2, 900))
    let $persName :=
        if($persName eq '')
        then upper-case(substring($who, 1, 1)) || substring($who, 2, 900)
        else $persName
    return
        <person xml:id="{$who}" sex="{$sex}">
            <persName>{$persName}</persName>
        </person>
}
                </listPerson>
            </particDesc>
            <textClass>
                <keywords>
                    <term type="genreTitle">{string($doc//*:SourceDesc/*:genre)}</term>
                    <term type="genreTitle">{string($doc//*:SourceDesc/*:type)}</term>
                </keywords>
            </textClass>
        </profileDesc>
        <revisionDesc>
            <listChange>
                <change when="2020-12-04">(mg) file conversion from source</change>
            </listChange>
        </revisionDesc>
    </teiHeader>
    {
        local:transform($doc/*:TEI/*:text)
    }
</TEI>

return
    xmldb:store('/db/transformed', $resource => lower-case() => replace('_', '-'), $tei)