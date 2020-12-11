xquery version "3.1";

declare namespace tei='http://www.tei-c.org/ns/1.0';

declare variable $continue := false();

declare variable $who-tokenize-pattern := '/|,';

declare function local:write-on-filesystem($resource-name as xs:string, $node as node()) {
    let $path := '/fredracor/transformed'
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

declare function local:attribute-to-comment($node as attribute()+) {
    $node ! comment { ('@' || local-name(.) || '="' || string(.) || '"') }
};

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

            (:  👇 the incredible typo hack  :)
            case element(SPEAKER) return
                element {QName('', 'speaker')} {
                $node/node()} => local:transform()

            case element(P) return
                element {QName('', 'p')} {
                $node/node()} => local:transform()

            case text() return
                (: at ABEILLE_CORIOLAN.xml there is '4+' in the middle of nowhere, other case is a tei:sp with '****' :)
                if(
                    ($node/parent::*:sp
                    or $node/parent::*:div1
                    or $node/parent::*:div2
                    or $node/parent::*:castList
                    or $node/parent::*:body
                    or $node/parent::*:div) 
                    
                    and matches($node, '\S'))
                then
                    comment { 'text():' || replace($node, '-$', '- ') }
                else
                    $node

            case comment() return $node

            case processing-instruction() return $node

            case element(div1) return
                (: @id (numbering) removed :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except ($node/@stage, $node/@id),
                local:transform($node/node())
            }, $node/@stage ! local:attribute-to-comment(.))

            case element(div2) return
                let $exceptionsType := (
                                    $node/@tpe,
                                    $node/@typ,
                                    $node/@typê,
                                    $node/@typE
                                    )
                return
                (: @id (numbering) removed :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except ($node/@stage, $node/@id, $exceptionsType),
                $exceptionsType ! attribute type { string(.)},
                local:transform($node/node())
            }, $node/@stage ! local:attribute-to-comment(.))

            case element(sp) return
                let $exceptionsStage := (
                                $node/@stage,
                                $node/@stag,
                                $node/@styage,
                                $node/@stgae,
                                $node/@qtage,
                                $node/@sstage,
                                $node/@dtage,
                                $node/@stgage,
                                $node/@swardtage,
                                $node/@wardstage,
                                $node/@corstage,
                                $node/@satge,
                                $node/@s6tage,
                                $node/@stahe,
                                $node/@stagae,
                                $node/@stge,
                                $node/@sage,
                                $node/@wtage,
                                $node/@syage,
                                $node/@stagee,
                                $node/@wstage,
                                $node/@tstage,
                                $node/@stahge,
                                $node/@astage,
                                $node/@stange,
                                $node/@stand,
                                $node/@stagle
                                )
                let $exceptionsWho := (
                                $node/@who,
                                $node/@stwho,
                                $node/@givewho,
                                $node/@towardwho,
                                $node/@embarrassedwho,
                                $node/@breakwho,
                                $node/@ho
                                )
                return
                (element {QName('http://www.tei-c.org/ns/1.0', 'sp')} {
                $node/@* except ($exceptionsStage, $exceptionsWho, $node/@type, $node/@toward), (: typo in ancelot-arago-papillotes.xml, bernardt-mystere.xml  :)
                attribute who {
                    let $easy := tokenize(string-join($exceptionsWho, ' '), $who-tokenize-pattern)
                                     ! ('#' || local:translate(.))
                    return
                        if(string($easy[1]) != '')
                        then $easy
                        else
                            $node/speaker/text() => local:translate()
                },
                local:transform($node/node() except $node/text()) (: there is text within sp audiffret-albertdurer.xml :)
            }, ($exceptionsStage, $exceptionsWho, $node/@type, $node/@toward) ! local:attribute-to-comment(.) )
            
            case element(s) return
                (: minor correction to prevent multiple usage of an ID :)
                element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except ($node/@id, $node/@i2d, $node/@di, $node/@d, $node/@id1, $node/@kd, $node/@n),
                ($node/@id, $node/@di, $node/@i2d, $node/@d, $node/@id1, $node/@kd) ! attribute n {string(.)}, (: typo barreradet-candide.xml :)
                local:transform($node/node())
            }
            case element(l) return
                (: minor correction to prevent multiple usage of an ID :)
                (: removing unknown attributes @syll, @part :)
                (element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except ($node/@id, $node/@n, $node/@class, $node/@syll, $node/@part, $node/@par, $node/@pat, $node/@patr, $node/@prt, $node/@parrt, $node/@syl),
                attribute n {string($node/@id)},
                ($node/@part, $node/@par, $node/@pat, $node/@patr, $node/@prt, $node/@parrt) ! 
                    (if( upper-case(.) = ("F", "I", "M", "N", "Y") )
                    then (attribute part {upper-case(.)})  (: typo in andrieux-anaximandre.xml :)
                    else (comment {'WARNING: invalid @part in source.'}, local:attribute-to-comment(.))),
                if(not($node/@n)) then () else comment {'WARNING: source contains @n as well. it is removed here.'},
                local:transform($node/node())
            }, ($node/@syll, $node/@syl, $node/@class) ! local:attribute-to-comment(.) )
            
            case element(lg) return
                element {QName('http://www.tei-c.org/ns/1.0', 'lg')} {
                    $node/@* except ($node/@id),
                    $node/@id ! attribute n {string($node/@id)},
                    local:transform($node/node())
                }

            case element(p) return
                let $exceptionsType := (
                                $node/@type,
                                $node/@tyep,
                                $node/@typee,
                                $node/@tyope,
                                $node/@tpe,
                                $node/@class)

                let $exceptionsId := (
                                $node/@id,
                                $node/@i,
                                $node/@is,
                                $node/@di,
                                $node/@d,
                                $node/@n) (: put @n here, to integrate in new created @n by a single instruction :)

                (: move tei:p[@type='v'] to tei:l as it represents vers. distinction unclear. :)
                let $vers := ('v', 'vers')
                let $isVers := 
                            ($node/@type = $vers)
                            or ($node/@tyep = $vers)
                            or ($node/@typee = $vers)
                            or ($node/@tyope = $vers)
                            or ($node/@class = $vers)
                
                return
                    if($isVers)
                then
                    element {QName('http://www.tei-c.org/ns/1.0', 'l')} {
                    $node/@* except ($exceptionsId, $exceptionsType),
                    $exceptionsId ! attribute n {string(.)},
                    local:transform($node/node())
                }
                else
                    (element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                    $node/@* except ($exceptionsId, $exceptionsType),
                    $exceptionsId ! attribute n {string(.)},
                    local:transform($node/node())
                }, ($node/@class) ! local:attribute-to-comment(.) )
                
            case element(role) return
                (: correct invalid IDs here as well :)
                (: removing unknown attributes @sex, @type, @statut, @age, @stat_amour :)
                let $exceptionsRole := (
                                    $node/@sex,
                                    $node/@type,
                                    $node/@statut,
                                    $node/@age,
                                    $node/@stat_amour,
                                    $node/@statut_amoureux,
                                    $node/@statu
                                    )
                return
                (element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except ($node/@id, $exceptionsRole),
                attribute corresp {'#' || local:translate(string($node/@id))},
                local:transform($node/node())
            },
                ($exceptionsRole) ! local:attribute-to-comment(.) )

            case element(docDate) return
                (: correct unknown @value to @when :)
                element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except $node/@value,
                attribute when { replace($node/@value, '^v\.', '') },
                local:transform($node/node())
            }

            case element(docAuthor) return
                (: remove this element, when it will result empty :)
                if(not($node/text() or $node/*)) then () else
                (: remove unused and invalid @id, may replaced by @sameAs, @ref or @corresp :)
                (element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except ($node/@id, $node/@bio),
                local:transform($node/node())
            }, $node/@bio ! local:attribute-to-comment(.) )

        (: BEGIN 
            rename unknown or wrong used elements to div
            and preserve usage as @type
        :)
            case element(docImprint) return
                (: remove unknown element :)
                element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except $node/@type,
                attribute type {'docImprint'},
                local:transform($node/node())
            }

            case element(privilege) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except ($node/@id, $node/@date, $node/@value),
                attribute type {'privilege'},
                local:transform($node/node())
            }, ($node/@id, $node/@date, $node/@value) ! local:attribute-to-comment(.))

            case element(imprimeur) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except $node/@id,
                attribute type {'imprimeur'},
                element {QName('http://www.tei-c.org/ns/1.0', 'p')}{
                    local:transform($node/node())}
            }, ($node/@id) ! local:attribute-to-comment(.))
            
            case element(acheveImprime) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except ($node/@id, $node/@value),
                attribute type {'acheveImprime'},
                element {QName('http://www.tei-c.org/ns/1.0', 'p')} {
                    local:transform($node/node())
                }
            }, $node/@id ! local:attribute-to-comment(.) )

            case element(acheveImprimer) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except ($node/@id, $node/@value),
                attribute type {'acheveImprime'},
                element {QName('http://www.tei-c.org/ns/1.0', 'p')} {
                    local:transform($node/node())
                }
            }, $node/@id ! local:attribute-to-comment(.) )

            case element(achevedImprime) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except ($node/@id, $node/@value),
                attribute type {'acheveImprime'},
                element {QName('http://www.tei-c.org/ns/1.0', 'p')} {
                    local:transform($node/node())
                }
            }, $node/@id ! local:attribute-to-comment(.) )

            case element(copyright) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except ($node/@id, $node/@type, $node/@value),
                attribute type {'copyright'},
                $node/@type ! local:attribute-to-comment(.),
                element {QName('http://www.tei-c.org/ns/1.0', 'p')} {
                    local:transform($node/node())
                }
            }, ($node/@id, $node/@type, $node/@value) ! local:attribute-to-comment(.) )

            case element(printer) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except ($node/@id, $node/@type, $node/@value),
                attribute type {'printer'},
                $node/@type ! local:attribute-to-comment(.),
                element {QName('http://www.tei-c.org/ns/1.0', 'p')} {
                    local:transform($node/node())
                }
            }, ($node/@id, $node/@type, $node/@value) ! local:attribute-to-comment(.) )

            case element(approbation) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except ($node/@id, $node/@value),
                attribute type {'approbation'},
                local:transform($node/node())
            }, ($node/@id, $node/@value) ! local:attribute-to-comment(.) )
            case element(appobation) return (: typo :)
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except ($node/@id, $node/@value),
                attribute type {'approbation'},
                local:transform($node/node())
            }, ($node/@id, $node/@value) ! local:attribute-to-comment(.) )
            
            case element(enregistrement) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except $node/@id,
                attribute type {'enregistrement'},
                local:transform($node/node())
            }, $node/@id ! local:attribute-to-comment(.) )
            
            case element(postface) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except $node/@id,
                attribute type {'postface'},
                local:transform($node/node())
            }, $node/@id ! local:attribute-to-comment(.) )

            case element(epitre) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except $node/@id,
                attribute type {'epitre'},
                local:transform($node/node())
            }, $node/@id ! local:attribute-to-comment(.) )
        
            case element(preface) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except $node/@id,
                attribute type {'preface'},
                local:transform($node/node())
            }, $node/@id ! local:attribute-to-comment(.) )
        (: END :)
            
            case element(poem) return
                (: move poem to ab, preserve via comments :)
                (comment { '<poem>' },
                element {QName('http://www.tei-c.org/ns/1.0', 'ab')} {
                    $node/@*,
                    local:transform($node/node())
                },
                comment { '</poem>' })
            case element(sonnet) return
                element {QName('http://www.tei-c.org/ns/1.0', 'lg')} {
                    $node/@* except $node/@type,
                    attribute type {'sonnet'},
                    local:transform($node/node())
                }
            case element(stanza) return
                element {QName('http://www.tei-c.org/ns/1.0', 'lg')} {
                    $node/@* except $node/@type,
                    attribute type { if($node/@type) then $node/@type else 'stanza'},
                    local:transform($node/node())
                }

            case element(nombre) return
                if(matches(string($node), '\w'))
                then
                    (element {QName('http://www.tei-c.org/ns/1.0', 'ab')} {
                        $node/@* except $node/@value,
                        attribute type {'nombre'},
                        local:transform($node/node())
                    }, $node/@value ! local:attribute-to-comment(.) )
                else 
                    () (: remove this element, when it has no or whitespace only text inside :)

            case element(note) return
                let $exceptionsType := (
                                    $node/@typ,
                                    $node/@typr,
                                    $node/@typr,
                                    $node/@typpe,
                                    $node/@typep,
                                    $node/@tyep,
                                    $node/@tyê,
                                    $node/@tyype,
                                    $node/@tpe,
                                    $node/@tye,
                                    $node/@tyepe,
                                    $node/@tyope,
                                    $node/@typz,
                                    $node/@ytpe
                                    )
                return
                (: rename attribute typ to type :)
                element {QName('http://www.tei-c.org/ns/1.0', 'note')} {
                    $node/@*[. != ''] except ($exceptionsType), (: empty @type in anonyme-chapelaindecoiffe.xml :)
                    $exceptionsType ! attribute type {string( . )},
                    local:transform($node/node())
                }
        
            case element(titlePart) return
                (: rename attribute part to type :)
                element {QName('http://www.tei-c.org/ns/1.0', 'titlePart')} {
                    $node/@* except $node/@part,
                    $node/@part ! attribute type {string( $node/@part )},
                    local:transform($node/node())
                }

            case element(premiere) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'ab')} {
                attribute type {'premiere'},
                local:transform($node/node())
            }, $node/@* ! local:attribute-to-comment(.) )
            
            case element(adresse) return
                (: move this to opener/salute :)
                element {QName('http://www.tei-c.org/ns/1.0', 'opener')} {
                    element {QName('http://www.tei-c.org/ns/1.0', 'salute')} {
                        $node/@*,
                        local:transform($node/node())
                    }
                }

            case element(casting) return
                (element {QName('http://www.tei-c.org/ns/1.0', 'ab')} {
                    $node/@* except $node/@type,
                    attribute type {'casting'},
                    local:transform($node/node())
                }, $node/@type ! local:attribute-to-comment(.) )

            case element(recette) return
                (element {QName('http://www.tei-c.org/ns/1.0', 'ab')} {
                    $node/@* except ($node/@type, $node/@value),
                    attribute type {'revenue'},
                    local:transform($node/node())
                }, ($node/@type, $node/@value) ! local:attribute-to-comment(.) )

            case element(signature) return
                element {QName('http://www.tei-c.org/ns/1.0', 'signed')} {
                    $node/@*,
                    local:transform($node/node())
                }

        (: completely remove the folowing, as it is unclear what it means :)
            case element(set) return
                comment {
                    'TODO: usage of set in correct place but with unknown attributes',
                    serialize($node)
                }
            case element(editor) return 
                comment {
                    'TODO: handling of editor name at this place unclear',
                    serialize($node)
                }

            case element(stage) return
                (: element stage with attribute stage is invalid :)
                if($node/parent::*:body)
                then
                    (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                        (element {QName('http://www.tei-c.org/ns/1.0', 'stage')} {
                            $node/@* except $node/@stage,
                            local:transform($node/node())
                        }, $node/@stage ! local:attribute-to-comment(.))
                    })
                else
                (element {QName('http://www.tei-c.org/ns/1.0', 'stage')} {
                $node/@* except ($node/@stage, $node/@tye, $node/@tyepe, $node/@ype, $node/@tyep, $node/@typpe),
                ($node/@tye, $node/@tyepe, $node/@ype, $node/@tyep, $node/@typpe) ! attribute type { string(.) },
                local:transform($node/node())
            }, $node/@stage ! local:attribute-to-comment(.))

            case element(source) return
                (: unclear what "source" means here. should be part of the teiHeader :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'p')} {
                $node/@* except $node/@id, (: empty id attribute :)
                local:transform($node/node())
            }, comment { 'source' })

            case element(a) return
                element {QName('http://www.tei-c.org/ns/1.0', 'ref')} {
                    $node/@href ! attribute target {string(.)},
                    local:transform($node/node())
            }
            
            case element(em) return
                element {QName('http://www.tei-c.org/ns/1.0', 'hi')} {
                    $node/@*,
                    local:transform($node/node())
            }

            case element(ab) return
                if($node/@tpe = 'stances')
                then (: TODO: should become tei:lg :)
                    element {QName('http://www.tei-c.org/ns/1.0', 'ab')} {
                        $node/@* except $node/@tpe,
                        attribute type {'stances'},
                        local:transform($node/node())
                }
                else
                    element {QName('http://www.tei-c.org/ns/1.0', 'ab')} {
                    $node/@*,
                    local:transform($node/node())
                }

        default return
            element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except $node/@type,
                if($node/@type[. = '']) then () else $node/@type, (: empty @type is not allowed :)
                local:transform($node/node())
            }
};

let $target-collection := '/db/transformed',
    $cleanup := if( xmldb:collection-available($target-collection) and not($continue))
                then xmldb:remove($target-collection)
                else true(),
    $create := if($continue) then () else xmldb:create-collection('/db', 'transformed')

let $collection-uri := '/db/data/'
let $do := 
for $resource at $pos in xmldb:get-child-resources($collection-uri)
(: set position to continue previouse transformation :)
(:where $pos gt 28:)
(:where $pos lt 101:)
(:where $pos eq 100:)

let $log := util:log-system-out( substring-before(util:eval( 'current-time()' ), '.') || ' preparing ' || ($pos => format-number('0000') => replace('^0', ' ') => replace('^ 0', '  ') => replace('^  0', '   ')) || ': ' || $resource)
let $id-from-list := string( doc('/db/ids.xml')//play[@orig eq $resource]/@dracor )
let $id := if($id-from-list) then $id-from-list else format-number($pos, 'x00000') 
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

let $datePrint :=
    let $value := string(($doc//*:docDate)[1]/@value)
    let $when := ()
    return
        (element {QName('http://www.tei-c.org/ns/1.0', 'date')} {
            attribute type {'print'},
            $when ! attribute when {.},
            $value
        }, 
        ($doc//*:docDate)[2] ! comment {'WARNING: multiple docDate elements found in source. ' || serialize(.)})

let $tei :=
<TEI xmlns="http://www.tei-c.org/ns/1.0" xml:lang="fre">
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
                <idno type="dracor" xml:base="https://dracor.org/id/">{$id-from-list}</idno>
                <availability>
                    <licence>
                        <ab>CC BY-NC-SA 4.0</ab>
                        <ref target="https://creativecommons.org/licenses/by-nc-sa/4.0/">Licence</ref>
                    </licence>
                </availability>{'
                '}
                <!-- idno type="wikidata" xml:base="https://www.wikidata.org/entity/"></idno -->
            </publicationStmt>
            <sourceDesc>
                <bibl type="digitalSource">
                    <name>Théâtre Classique</name>
                    <idno type="URL">http://theatre-classique.fr/pages/programmes/edition.php?t=../documents/{$resource}</idno>
                    <idno type="URL">http://theatre-classique.fr/pages/documents/{$resource}</idno>
                    <availability>
                        <licence>
                            <ab>CC BY-NC-SA 4.0</ab>
                            <ref target="https://creativecommons.org/licenses/by-nc-sa/4.0/">Licence</ref>
                        </licence>
                    </availability>
                    <bibl type="originalSource">
                        {$datePrint}
{
    element {QName('http://www.tei-c.org/ns/1.0', 'date')} {
        attribute type {'premiere'},
        (($doc//*:premiere)[1])[matches(@date, '\d{4}')]/@date ! attribute when {.},
        string(($doc//*:premiere)[1])
    }
}
                            { if(($doc//*:premiere)[2]) then comment {'WARNING: multiple premiere elements found in source.'} else () }
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
    let $whos := ($doc//*:text//*:sp/tokenize(./@who || ./@ho, $who-tokenize-pattern) => distinct-values())
    let $whos := if(string($whos[1]) != '') then $whos else (($doc//*:speaker/string(.)) => distinct-values())
    for $who in (($whos) ! local:translate(.) => distinct-values())
    where $who (: do not parse empty @who :)
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
        <person xml:id="{$who}" sex="{$sex}">{if(not($castItem)) then comment { 'WARNING: no castItem found for reference in @who' } else ()}
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
        local:transform($doc/*:TEI/*:text),
        local:transform($doc/*:TEI.2/*:text)
    }
</TEI>

let $resource-name := $resource => lower-case() => replace('_', '-')
let $store := xmldb:store('/db/transformed', $resource-name, $tei)
let $validation := validation:jing-report(xs:anyURI($store), xs:anyURI('/db/tei_all.rng'))
let $log := 
    if($validation//status eq 'valid')
    then util:log-system-out('✔ tei_all')
    else (util:log-system-out('✘ tei_all'), util:log-system-out(serialize($validation, map{'method':'xml','indent': true()})))

let $serialize := local:write-on-filesystem($resource-name, $tei)

return
    $validation
    
return
    (count($do//status[. eq 'valid']),
    count($do//status[. eq 'invalid']))
