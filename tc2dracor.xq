xquery version "3.1";

import module namespace tcf = "http://dracor.org/ns/exist/titlecase-french"
  at "titlecase.xq";

declare namespace functx = "http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

(: XML document mapping original file names to DraCor IDs :)
declare variable $id-map := doc('ids.xml');

(: XML document mapping original author info to normalized author names :)
declare variable $author-map := doc('authors.xml');

declare variable $who-tokenize-pattern := '/|,';

declare function functx:change-element-ns-deep (
  $nodes as node()*,
  $newns as xs:string,
  $prefix as xs:string
) as node()* {
  for $node in $nodes
  return if ($node instance of element()) then (
    element {QName (
      $newns,
      concat($prefix, if ($prefix = '') then '' else ':', local-name($node))
    )} {$node/@*, functx:change-element-ns-deep(
      $node/node(), $newns, $prefix
    )})
  else if ($node instance of document-node()) then
    functx:change-element-ns-deep($node/node(), $newns, $prefix)
  else $node
};

(: Prepare document before actual transformation :)
declare function local:prepare ($doc as node()) as item()* {
  (: Only a few original documents have the TEI namespace. We remove it to have
  a consistent base to work with. :)
  if ($doc/tei:TEI) then (
    util:log-system-out("stripping ns from " || base-uri($doc)),
    functx:change-element-ns-deep($doc/tei:TEI, "", "")
    ) else $doc/*
};

declare function local:titlecase ($input as node()*) as xs:string? {
   string-join($input, " ") => normalize-space() => tcf:convert-ou()
};

declare function local:attribute-to-comment($node as attribute()+) {
    $node ! comment { ('@' || local-name(.) || '="' || string(.) || '"') }
};

declare function local:translate($string as xs:string) as xs:string {
    let $work :=
        translate(lower-case($string), "*[]’' áàâéèêíìîóòôúùû", '------aaaeeeiiiooouuu')
        => replace('\.', '')
        => replace('^\-', '')
        => replace('^(\d)', 'num') (: FIXME: this can effectively createe the same ID for different characters :)
        => replace('^[|]$', '')
        => replace('&#xfffd;', '')
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
            case element(acheverImprimer) return
                element {QName('', 'acheveImprime')} {
                $node/node()} => local:transform()
            case element(achevedImprime) return
                element {QName('', 'acheveImprime')} {
                $node/node()} => local:transform()
            case element(acheveImprimer) return
                element {QName('', 'acheveImprime')} {
                $node/node()} => local:transform()
            case element(appobation) return
                element {QName('', 'approbation')} {
                $node/node()} => local:transform()
            case element(pinter) return
                element {QName('', 'printer')} {
                $node/node()} => local:transform()
            

            case text() return
                (: at ABEILLE_CORIOLAN.xml there is '4+' in the middle of nowhere, other case is a tei:sp with '****' :)
                if(
                    ($node/parent::*:sp
                    or $node/parent::*:div1
                    or $node/parent::*:div2
                    or $node/parent::*:castList
                    or $node/parent::*:body
                    or $node/parent::*:front
                    or $node/parent::*:div
                    or $node/parent::*:docImprint)
                    
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

            case element(div) return
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                    $node/@* except ($node/@id, $node/@typê, $node/@typ, $node/@type),
                    ($node/@typê, $node/@typ, $node/@type)[. != ''] ! attribute type { string(.)},
                    local:transform($node/node())
            }, ($node/@stage, $node/@id) ! local:attribute-to-comment(.))

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
                                $node/@owardstage,
                                $node/@corstage,
                                $node/@satge,
                                $node/@s6tage,
                                $node/@stahe,
                                $node/@stagae,
                                $node/@stge,
                                $node/@sage,
                                $node/@sgage,
                                $node/@stagge,
                                $node/@wtage,
                                $node/@syage,
                                $node/@stagee,
                                $node/@wstage,
                                $node/@tstage,
                                $node/@stahge,
                                $node/@sttage,
                                $node/@astage,
                                $node/@stange,
                                $node/@stand,
                                $node/@stagle,
                                $node/@stagek,
                                $node/@sgtage,
                                $node/@staage,
                                $node/@sytage,
                                $node/@strage,
                                $node/@smtage,
                                $node/@oward,
                                $node/@syahe,
                                $node/@stageward,
                                $node/@rtestage,
                                $node/@stagepull,
                                $node/@age,
                                $node/@get,
                                $node/@chstage
                                )
                let $exceptionsWho := (
                                $node/@who,
                                $node/@stwho,
                                $node/@givewho,
                                $node/@towardwho,
                                $node/@embarrassedwho,
                                $node/@breakwho,
                                $node/@ho,
                                $node/@w4ho
                                )
                return
                if( not(exists($node/* except $node/*:speaker)) ) then comment { 'ERROR: ', serialize($node)} else (: nearly empty sp in corneillet-geolierdesoismeme.xml :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'sp')} {
                $node/@* except ($exceptionsStage, $exceptionsWho, $node/@type, $node/@toward, $node/@ge, $node/@syll, $node/@class, $node/@aparte), (: typo in ancelot-arago-papillotes.xml, bernardt-mystere.xml  :)
                attribute who {
                    let $easy := tokenize(string-join($exceptionsWho, ' '), $who-tokenize-pattern)
                                     ! ('#' || local:translate(.))
                    return
                        if(string($easy[1]) != '')
                        then $easy
                        else
                            '#' || (normalize-space($node/speaker) => local:translate())
                },
                local:transform($node/node() except $node/text()) (: there is text within sp audiffret-albertdurer.xml :)
            }, ($exceptionsStage, $exceptionsWho, $node/@type, $node/@toward, $node/@ge, $node/@syll, $node/@aparte) ! local:attribute-to-comment(.) ) (: @class was used a single time, so we do not take the effort to write it to a comment :)
            
            case element(s) return
                (: minor correction to prevent multiple usage of an ID :)
                element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except ($node/@id, $node/@i2d, $node/@i3, $node/@ic, $node/@if, $node/@di, $node/@od, $node/@iid, $node/@d, $node/@id1, $node/@i, $node/@is, $node/@kd, $node/@n),
                ($node/@id, $node/@di, $node/@od, $node/@iid, $node/@i2d, $node/@i3, $node/@ic, $node/@if, $node/@d, $node/@id1, $node/@i, $node/@is, $node/@kd) ! attribute n {string(.)}, (: typo barreradet-candide.xml :)
                local:transform($node/node())
            }
            case element(l) return
                (: minor correction to prevent multiple usage of an ID :)
                (: removing unknown attributes @syll, @part :)
                let $exceptionsId := ($node/@id, $node/@is, $node/@Id, $node/@l)
                let $exceptionsPart := (
                                    $node/@part,
                                    $node/@par,
                                    $node/@pat,
                                    $node/@patr,
                                    $node/@prt,
                                    $node/@parrt,
                                    $node/@parT,
                                    $node/@partt,
                                    $node/@aprt,
                                    $node/@pArt,
                                    $node/@paRt,
                                    $node/@art
                                    )
                let $exceptionsEtc := (
                                    $node/@syll,
                                    $node/@syl,
                                    $node/@stll,
                                    $node/@n,
                                    $node/@class,
                                    $node/@stage
                                    )
                return
                (element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except ($exceptionsId, $exceptionsPart, $exceptionsEtc),
                    if(not($exceptionsId)) then () else
                attribute n { $exceptionsId ! string(.) },
                $exceptionsPart !
                    (if( upper-case(.) = ("F", "I", "M", "N", "Y") )
                    then (attribute part {upper-case(.)})  (: typo in andrieux-anaximandre.xml :)
                    else (comment {'WARNING: invalid @part in source.'}, local:attribute-to-comment(.))),
                if(not($node/@n)) then () else comment {'WARNING: source contains @n as well. it is removed here.'},
                local:transform($node/node())
            }, ($exceptionsEtc) ! local:attribute-to-comment(.) )
            
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
                                $node/@if,
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
                    let $value := replace($node/@value, '^v\.', '')
                    return if($value = '') then () else
                attribute when { $value },
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
                $node/text()[matches(., '\S')]
                    ! element {QName('http://www.tei-c.org/ns/1.0', 'head')} { . },
                local:transform($node/node() except $node/text()[matches(., '\S')])
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
                $node/@* except ($node/@id, $node/@value, $node/@date),
                attribute type {'approbation'},
                local:transform($node/node())
            }, ($node/@id, $node/@value, $node/@date) ! local:attribute-to-comment(.) )

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

            case element(errata) return
                (: remove unknown element :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                $node/@* except $node/@id,
                attribute type {'errata'},
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
                    $node/@* except $node/@tpe,
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

            case element(q) return
                (element {QName('http://www.tei-c.org/ns/1.0', 'q')} {
                    $node/@* except $node/@direct,
                    attribute type { if($node/@type) then $node/@type else 'stanza'},
                    local:transform($node/node())
            }, $node/@direct ! local:attribute-to-comment(.) )

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
                                    $node/@typee,
                                    $node/@typep,
                                    $node/@tyep,
                                    $node/@tyê,
                                    $node/@tyype,
                                    $node/@tpe,
                                    $node/@tye,
                                    $node/@tyepe,
                                    $node/@tyope,
                                    $node/@typz,
                                    $node/@ytpe,
                                    $node/@tppe,
                                    $node/@typp,
                                    $node/@typoe,
                                    $node/@tyhpe,
                                    $node/@Type,
                                    $node/@stage, (: used as @type in schelandre-tyrsidon-i.xml :)
                                    $node/@id, (: used as @type in campistron-tachmas.xml :)
                                    $node/@note
                                    )
                return
                (: rename attribute typ to type :)
                (element {QName('http://www.tei-c.org/ns/1.0', 'note')} {
                    $node/@*[. != ''] except ($exceptionsType), (: empty @type in anonyme-chapelaindecoiffe.xml :)
                    $exceptionsType ! attribute type {string( . )},
                    local:transform($node/node())
                }, $node/@note ! local:attribute-to-comment(.) )
        
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
            case element(performance) return
                if(not( $node/* )) (: remove placeholder :)
                then ()
                else
                    element {QName('http://www.tei-c.org/ns/1.0', 'performance')} {
                        $node/@*,
                        local:transform($node/node())
                    }


            case element(stage) return
                let $exceptionsType := (
                                    $node/@tye,
                                    $node/@typ,
                                    $node/@tyepe,
                                    $node/@ype,
                                    $node/@tyep,
                                    $node/@typpe,
                                    $node/@typr,
                                    $node/@type
                                    )
                let $newType :=
                    ($exceptionsType)[. != ''] ! attribute type { string(.) }
                
                return

                (: element stage with attribute stage is invalid :)
                if($node/parent::*:body)
                then
                    (element {QName('http://www.tei-c.org/ns/1.0', 'div')} {
                        (element {QName('http://www.tei-c.org/ns/1.0', 'stage')} {
                            $node/@* except ($node/@stage, $exceptionsType),
                            local:transform($node/node())
                        }, $node/@stage ! local:attribute-to-comment(.))
                    })
                else
                (element {QName('http://www.tei-c.org/ns/1.0', 'stage')} {
                $node/@* except ($node/@id, $node/@stage, $exceptionsType),
                $newType,
                $node/@id ! attribute n {string(.)},
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

            case element(pd) return
                element {QName('http://www.tei-c.org/ns/1.0', 'pb')} {
                    $node/@*,
                    local:transform($node/node())
            }

            case element(titre) return (: single occurence in benserade-cleopatre.xml :)
                element {QName('http://www.tei-c.org/ns/1.0', 'head')} {
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

            case element(bottom) return
                element {QName('http://www.tei-c.org/ns/1.0', 'back')} {
                    $node/@*,
                    local:transform($node/node())
            }

            case element(suivante) return
                element {QName('http://www.tei-c.org/ns/1.0', 'closer')} {
                    $node/@*,
                    local:transform($node/node())
            }

            case element(speaker) return (: usually nothing we have to touch, but correcting a single usage as child of div2 (not allowede here) :)
            if($node/parent::*:div2)
            then
                element {QName('http://www.tei-c.org/ns/1.0', 'head')} {
                    $node/@*,
                    local:transform($node/node())
                }
            else
                element {QName('http://www.tei-c.org/ns/1.0', 'speaker')} {
                    $node/@*,
                    local:transform($node/node())
                }

            case element(castList) return
                if($node/following::*:castItem)
                then
                    element {QName('http://www.tei-c.org/ns/1.0', 'castList')} {
                        $node/@*,
                        local:transform($node/node()),
                        $node/following::*:castItem => local:transform()
                    }
                else
                    element {QName('http://www.tei-c.org/ns/1.0', 'castList')} {
                        $node/@*,
                        local:transform($node/node())
                    }
            case element(castItem) return
                if(not($node/parent::*:castList))
                then ()
                    (: do nothing as we includ the castItem outside of castList via the castList instruction :)
                else
                    element {QName('http://www.tei-c.org/ns/1.0', 'castItem')} {
                        $node/@*,
                        local:transform($node/node())
                    }

        default return
            (element {QName('http://www.tei-c.org/ns/1.0', $node/local-name())} {
                $node/@* except ($node/@type, $node/@id, $node/@xml.lang),
                if($node/@type[. = '']) then () else $node/@type, (: empty @type is not allowed :)
                $node/@xml.lang ! attribute xml:lang { string(.) },
                local:transform($node/node())
            }, ($node/@type, $node/@id) ! local:attribute-to-comment(.))
};

(: Construct DraCor TEI from original document :)
declare function local:construct-tei (
  $doc as element(),
  $orig-name as xs:string
) as node() {
  let $id := string($id-map//play[@orig eq $orig-name]/@dracor)

  let $title := element {QName('http://www.tei-c.org/ns/1.0', 'title')} {
    attribute type {'main'},
    local:titlecase(
      if ($doc//*:titlePart/@type="main") then
        $doc//*:titlePart[@type="main"]
      else
        $doc//*:fileDesc[1]/*:titleStmt[1]/*:title[1]
    )
  }

  let $subtitle := if ($doc//*:titlePart/@type="sub") then
    element {QName('http://www.tei-c.org/ns/1.0', "title")} {
      attribute type {"sub"},
      local:titlecase($doc//*:titlePart[@type="sub"])
    }
  else ()

  let $author :=
      for $author in $doc//*:author
      let $content := normalize-space($author)
      let $isni := normalize-space($author/@ISNI)
      let $normalized :=
        $author-map//author[isni eq $isni or name eq $content]/tei:author

      return if (
        (: fix duplicate author in CORNEILLEP_OTHON.xml :)
        $content = "CORNEILLE, Pierre"
          and $author/../author[@ISNI = "0000 0001 2129 6128"]
      ) then (
        comment {"duplicate: " || $content}
      ) else if ($normalized) then (
        $normalized,
        comment {$content}
      ) else (
        let $key := if ($isni) then
          attribute key {"isni:" || replace($isni, "\s", "")} else ()
        return
          element {QName('http://www.tei-c.org/ns/1.0', 'author')} {
              $key,
              $content
          }
      )

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
          <idno type="dracor" xml:base="https://dracor.org/id/">{$id}</idno>
          <availability>
            <licence>
              <ab>CC BY-NC-SA 4.0</ab>
              <ref target="https://creativecommons.org/licenses/by-nc-sa/4.0/">Licence</ref>
            </licence>
          </availability>
        </publicationStmt>
        <sourceDesc>
          <bibl type="digitalSource">
            <name>Théâtre Classique</name>
            <idno type="URL">http://theatre-classique.fr/pages/programmes/edition.php?t=../documents/{$orig-name}</idno>
            <idno type="URL">http://theatre-classique.fr/pages/documents/{$orig-name}</idno>
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
  {
    if(($doc//*:premiere)[2]) then
      comment {'WARNING: multiple premiere elements found in source.'} else ()
  }
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
    let $whos := ($doc//*:text//*:sp/tokenize(./@who || ./@ho || ./@w4ho, $who-tokenize-pattern) => distinct-values())
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
    local:transform($doc/*:text)
  }
  </TEI>

  return $tei
};


(: Get payload from request :)
let $data := if (request:exists()) then request:get-data() else ()
let $name := if (request:exists()) then (
  request:get-header("x-filename")
) else ()

return if (not(request:exists())) then (
  <error>no request</error>
) else if (not(request:get-method() = "POST")) then (
  response:set-status-code(405),
  <message>POST request required</message>
) else if ($data = ()) then (
  response:set-status-code(400),
  <message>no data</message>
) else if (
  not(request:get-header("content-type") = ("application/xml", "text/xml"))
) then (
  response:set-status-code(400),
  <error>unsupported content type: {request:get-header("content-type")}</error>
) else if (not($name)) then (
  response:set-status-code(400),
  <message>missing header 'X-Filename'</message>
) else (
  $data => local:prepare() => local:construct-tei($name)
)
