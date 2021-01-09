xquery version "3.1";

import module namespace tcf = "http://dracor.org/ns/exist/titlecase-french"
  at "../titlecase.xq";

let $tests := (
  (: wordReplacementsDefiniteArticles :)
  (: le :)
  ["le triangle rouge",
   "Le Triangle Rouge"],
  ["loki, le détective mythique",
   "Loki, le Détective Mythique"],
  (: la :)
  ["la secte",
   "La Secte"],
  ["leon la came",
   "Leon la Came"],
  (: les :)
  ["littlest petshop les aventures",
   "Littlest Petshop les Aventures"],
  ["les banquiers",
   "Les Banquiers"],
  (: l' :)
  ["junior l'aventurier",
   "Junior l'Aventurier"],
  ["l'accordeur",
   "L'Accordeur"],

  (: un, une, des :)
  (: wordReplacementsIndefiniteArticles :)
  (: un :)
  ["je suis un vampire",
   "Je Suis un Vampire"],
  ["un messager",
   "Un Messager"],
  (: une :)
  ["il était une fois...",
   "Il Etait une Fois..."],
  ["une histoire de france",
   "Une Histoire de France"],
  (: des :)
  ["Le haut des arbres",
   "Le Haut des Arbres"],
  ["des mohicans",
   "Des Mohicans"],

  (: du, de la, de l', des :)
  (: wordReplacementsPartitiveArticles :)
  (: du :)
  ["danse du temps",
   "Danse du Temps"],
  ["du côté de chez poje",
   "Du Côté de chez Poje"],
  (: de :)
  ["le masque de fer",
   "Le Masque de Fer"],
  ["de beaux moments",
   "De Beaux Moments"],
  (: des :)
  ["Le marteau des sorcières",
   "Le Marteau des Sorcières"],
  ["des bêtes",
   "Des Bêtes"],

  (: au, aux, du, des :)
  (: wordReplacementsContractedArticles :)
  (: au :)
  ["rentre au pays",
   "Rentre au Pays"],
  ["au pays des monstres",
   "Au Pays des Monstres"],
  (: aux :)
  ["rentrez aux pays",
   "Rentrez aux Pays"],
  ["aux pays des monstres",
   "Aux Pays des Monstres"],
  (: du :)
  ["histoires du passé",
   "Histoires du Passé"],
  ["du vent dans les branches",
   "Du Vent dans les Branches"],
  (: des :)
  ["avant des lustres",
   "Avant des Lustres"],
  ["des répétitions",
   "Des Répétitions"],

  (: ce, cet, cette, ces :)
  (: wordReplacementsDemonstrativeAdjectives :)
  (: ce :)
  ["regarde ce chemin",
   "Regarde ce Chemin"],
  ["ce chemin est long",
   "Ce Chemin Est Long"],
  (: cet :)
  ["A la plage cet été",
   "A la Plage cet Eté"],
  ["Cet été à la plage",
   "Cet Eté à la Plage"],
  (: cette :)
  ["ils font cette liste",
   "Ils Font cette Liste"],
  ["cette liste",
   "Cette Liste"],
  (: ces :)
  ["regarde-moi ces hommes",
   "Regarde-Moi ces Hommes"],
  ["ces longs trajets",
   "Ces Longs Trajets"],

  (: quel, quels, quelle, quelles :)
  (: wordReplacementsExclamativeAdjectives :)
  (: quel :)
  ["dis moi quel nom",
   "Dis Moi quel Nom"],
  ["quel beau paysage",
   "Quel Beau Paysage"],
  (: quels :)
  ["en quel pays",
   "En quel Pays"],
  ["quels sapins pour noël",
   "Quels Sapins pour Noël"],
  (: quelle :)
  ["en quelle saison",
   "En quelle Saison"],
  ["quelle ville",
   "Quelle Ville"],
  (: quelles :)
  ["elles font quelles recettes",
   "Elles Font quelles Recettes"],
  ["quelles couleurs",
   "Quelles Couleurs"],

  (: mon, ton, son, notre, votre, leur :)
  (: ma, ta, sa :)
  (: mes, tes, ses, nos, vos, leurs :)
  (: wordReplacementsPossessiveAdjectives :)
  (: mon :)
  ["sauf mon père",
   "Sauf mon Père"],
  ["mon ancètre",
   "Mon Ancètre"],
  (: ton :)
  ["vis ton rêve",
   "Vis ton Rêve"],
  ["ton espoir ne meurt pas",
   "Ton Espoir ne Meurt pas"],
  (: son :)
  ["louna et son fils",
   "Louna et son Fils"],
  ["son coeur résistera",
   "Son Coeur Résistera"],
  (: notre :)
  ["a notre bourse",
   "A notre Bourse"],
  ["notre vie",
   "Notre Vie"],
  (: votre :)
  ["avec votre accord",
   "Avec votre Accord"],
  ["votre avis",
   "Votre Avis"],
  (: leur :)
  ["c'est leur choix",
   "C'est leur Choix"],
  ["leur style",
   "Leur Style"],
  (: ma :)
  ["tout est de ma faute",
   "Tout Est de ma Faute"],
  ["ma mère",
   "Ma Mère"],
  (: ta :)
  ["range ta chambre",
   "Range ta Chambre"],
  ["ta lumière",
   "Ta Lumière"],
  (: sa :)
  ["un père et sa fille",
   "Un Père et sa Fille"],
  ["sa dulciné",
   "Sa Dulciné"],
  (: mes :)
  ["pourtant mes choix étaient bons",
   "Pourtant mes Choix Etaient Bons"],
  ["mes devoirs",
   "Mes Devoirs"],
  (: tes :)
  ["prends tes responsabilités",
   "Prends tes Responsabilités"],
  ["tes dessins sont brillants",
   "Tes Dessins Sont Brillants"],
  (: ses :)
  ["lui et ses frères",
   "Lui et ses Frères"],
  ["ses cousins et cousines",
   "Ses Cousins et Cousines"],
  (: nos :)
  ["ce sont nos femmes",
   "Ce Sont nos Femmes"],
  ["nos clients",
   "Nos Clients"],
  (: vos :)
  ["à vos marques",
   "A vos Marques"],
  ["vos idées",
   "Vos Idées"],
  (: leurs :)
  ["jamais sans leurs bicyclettes",
   "Jamais sans leurs Bicyclettes"],
  ["leurs régions ont du talents",
   "Leurs Régions Ont du Talents"],

  (: mais, ou, et, donc, or, ni, car :)
  (: wordReplacementsCoordinatingConjunctions :)
  (: mais :)
  ["il est studieux mais turbulent",
   "Il Est Studieux mais Turbulent"],
  ["mais comment font-ils?",
   "Mais Comment Font-Ils?"],
  (: ou :)
  ["ici ou là",
   "Ici ou Là"],
  ["ou bien",
   "Ou Bien"],
  (: et :)
  ["entre ciel et terre",
   "Entre Ciel et Terre"],
  ["boule et bill",
   "Boule et Bill"],
  (: donc :)
  ["je pense donc je suis",
   "Je Pense donc je Suis"],
  ["donc nous partons",
   "Donc nous Partons"],
  (: or :)
  ["le temps est chaud or il a froid",
   "Le Temps Est Chaud or il A Froid"],
  ["or il tomba",
   "Or il Tomba"],
  (: ni :)
  ["je ne bois, ni ne fume",
   "Je ne Bois, ni ne Fume"],
  ["ni eux ni moi",
   "Ni Eux ni Moi"],
  (: car :)
  ["part car il est temps",
   "Part car il Est Temps"],
  ["car il partait",
   "Car il Partait"],
  (: voire :)
  ["deux voire trois",
   "Deux voire Trois"],
  ["voire même trois",
   "Voire Même Trois"],

  (: que, qu, quand, comme, si, lorsque, lorsqu, puisque, puisqu, quoique, quoiqu :)
  (: wordReplacementsSubordinatingConjunctions :)
  (: que :)
  ["il faut que je parte",
   "Il Faut que je Parte"],
  ["que faire",
   "Que Faire"],
  (: qu :)
  ["à moins qu'elle parte",
   "A Moins qu'elle Parte"],
  ["qu'en dise les gens",
   "Qu'en Dise les Gens"],
  (: quand :)
  ["elle rêve quand elle dors",
   "Elle Rêve quand elle Dors"],
  ["quand viendra le temps",
   "Quand Viendra le Temps"],
  (: comme :)
  ["elle est belle comme le jour",
   "Elle Est Belle comme le Jour"],
  ["comme si nous pouvions",
   "Comme si nous Pouvions"],
  (: si :)
  ["nous sommes allé si loin",
   "Nous Sommes Allé si Loin"],
  ["si loin",
   "Si Loin"],
  (: lorsque :)
  ["elle partit lorsque tu arrivas",
   "Elle Partit lorsque tu Arrivas"],
  ["lorsque tu pars",
   "Lorsque tu Pars"],
  (: lorsqu :)
  ["il partit lorsqu'elle arriva",
   "Il Partit lorsqu'elle Arriva"],
  ["lorsqu'elle arriva",
   "Lorsqu'elle Arriva"],
  (: puisque :)
  ["il est là puisque je l'ai vu",
   "Il Est Là puisque je l'Ai Vu"],
  ["puisque tu pars",
   "Puisque tu Pars"],
  (: puisqu :)
  ["ils viennent puisqu'elle part",
   "Ils Viennent puisqu'elle Part"],
  ["puisqu'elle part",
   "Puisqu'elle Part"],
  (: quoique :)
  ["il ira quoique tu fasses",
   "Il Ira quoique tu Fasses"],
  ["quoique nous fassions",
   "Quoique nous Fassions"],
  (: quoiqu :)
  ["il l'aime quoiqu'elle fasse",
   "Il l'Aime quoiqu'elle Fasse"],
  ["quoiqu'elle fasse",
   "Quoiqu'elle Fasse"],

  (: à, chez, dans, entre, jusque, jusqu, hors, par, pour, sans, vers, sur, pas, parmi, :)
  (: avec, sous, en (and others) :)
  (: wordReplacementsPrepositions :)
  (: à :)
  ["motards à jamais",
   "Motards à Jamais"],
  ["à toute allure",
   "A Toute Allure"],
  (: chez :)
  ["viens chez nous",
   "Viens chez nous"],
  ["chez nous",
   "Chez nous"],
  (: dans :)
  ["le pont dans la vase",
   "Le Pont dans la Vase"],
  ["dans mes veines",
   "Dans mes Veines"],
  (: entre :)
  ["le jour entre les lattes",
   "Le Jour entre les Lattes"],
  ["entre lui et elle",
   "Entre Lui et elle"],
  (: jusque :)
  ["depuis là jusque dans la maison",
   "Depuis Là jusque dans la Maison"],
  ["jusque par-dessus la tête",
   "Jusque Par-Dessus la Tête"],
  (: jusqu :)
  ["révêr jusqu'au jour",
   "Révêr jusqu'au Jour"],
  ["jusqu'au lendemain",
   "Jusqu'au Lendemain"],
  (: hors :)
  ["sortez hors de chez moi",
   "Sortez hors de chez Moi"],
  ["hors la loi",
   "Hors la Loi"],
  (: par :)
  ["deçue par la vie",
   "Deçue par la Vie"],
  ["par dessus les nuages",
   "Par Dessus les Nuages"],
  (: pour :)
  ["tout pour le tout",
   "Tout pour le Tout"],
  ["pour la vie",
   "Pour la Vie"],
  (: sans :)
  ["vivre sans limite",
   "Vivre sans Limite"],
  ["sans foi ni loi",
   "Sans Foi ni Loi"],
  (: vers :)
  ["le regard vers le large",
   "Le Regard vers le Large"],
  ["vers l'infini et au-delà",
   "Vers l'Infini et Au-Delà"],
  (: sur :)
  ["argent sur providence",
   "Argent sur Providence"],
  ["sur lui",
   "Sur Lui"],
  (: pas :)
  ["il ne faut pas",
   "Il ne Faut pas"],
  ["pas toi",
   "Pas Toi"],
  (: parmi :)
  ["l'intru parmi eux",
   "L'Intru parmi Eux"],
  ["parmi nous",
   "Parmi nous"],
  (: avec :)
  ["lui avec ses amis",
   "Lui avec ses Amis"],
  ["avec eux",
   "Avec Eux"],
  (: sous :)
  ["l'eau sous la glace",
   "L'Eau sous la Glace"],
  ["sous la neige",
   "Sous la Neige"],
  (: en :)
  ["en route",
   "En Route"],
  ["escales en terres inconnues",
   "Escales en Terres Inconnues"],

  (: je, tu, il, elle, on, nous, vous, ils, elles, me, te, se, y :)
  (: wordReplacementsPersonalPronouns :)
  (: je :)
  ["pourquoi je pleure",
   "Pourquoi je Pleure"],
  ["je suis moi",
   "Je Suis Moi"],
  (: tu :)
  ["toi au moins, tu es mort avant",
   "Toi au Moins, tu Es Mort Avant"],
  ["tu mourras moins bête",
   "Tu Mourras Moins Bête"],
  (: il :)
  ["après il est parti",
   "Après il Est Parti"],
  ["il était seul",
   "Il Etait Seul"],
  (: elle :)
  ["en chemin elle rencontre...",
   "En Chemin elle Rencontre..."],
  ["elle et lui",
   "Elle et Lui"],
  (: on :)
  ["Après on ira au bois",
   "Après on Ira au Bois"],
  ["on nous dit rien",
   "On nous Dit Rien"],
  (: nous :)
  ["le monde est à nous",
   "Le Monde Est à nous"],
  ["nous rentrons",
   "Nous Rentrons"],
  (: vous :)
  ["si vous acceptez",
   "Si vous Acceptez"],
  ["vous et eux",
   "Vous et Eux"],
  (: ils :)
  ["après ils sont partis",
   "Après ils Sont Partis"],
  ["ils étaient dix",
   "Ils Etaient Dix"],
  (: elles :)
  ["comme elles",
   "Comme elles"],
  ["elles étaient dix",
   "Elles Etaient Dix"],
  (: me :)
  ["laisse moi me prendre en charge",
   "Laisse Moi me Prendre en Charge"],
  ["me perdre",
   "Me Perdre"],
  (: te :)
  ["je te rejoindrai",
   "Je te Rejoindrai"],
  ["te dira pas",
   "Te Dira pas"],
  (: se :)
  ["il faut se connaître soi-même",
   "Il Faut se Connaître Soi-Même"],
  ["se perdre",
   "Se Perdre"],
  (: y :)
  ["il y avait",
   "Il y Avait"],
  ["y a pas",
   "Y A pas"],


  (: qui, que, quoi, dont, où :)
  (: wordReplacementsRelativePronouns :)
  (: qui :)
  ["ceux qui ont des ailes",
   "Ceux qui Ont des Ailes"],
  ["qui est la?",
   "Qui Est La?"],
  (: que :)
  ["pendant que le roi de prusse...",
   "Pendant que le Roi de Prusse..."],
  ["que sa volonté soit faite",
   "Que sa Volonté Soit Faite"],
  (: quoi :)
  ["A quoi bon",
   "A quoi Bon"],
  ["quoi faire",
   "Quoi Faire"],
  (: dont :)
  ["celui dont on parle",
   "Celui dont on Parle"],
  ["dont nous aimons la compagnie",
   "Dont nous Aimons la Compagnie"],
  (: où :)
  ["le pays où il est né",
   "Le Pays où il Est Né"],
  ["où aller?",
   "Où Aller?"],

  (: ne :)
  (: wordReplacementsOthers :)
  (: ne :)
  ["il ne viendra pas",
   "Il ne Viendra pas"],
  ["ne fais pas ca",
   "Ne Fais pas Ca"],

  (: wordReplacementswithQuotes :)
  (: c' :)
  ["ça, c'est paris",
   "Ca, c'est Paris"],
  ["c'est triste",
   "C'est Triste"],
  (: d' :)
  ["le marquis d'anaon",
   "Le Marquis d'Anaon"],
  ["d'artagnan",
   "D'Artagnan"],
  (: j' :)
  ["dites-moi que j'existe",
   "Dites-Moi que j'existe"],
  ["j'ai tué françois",
   "J'ai Tué François"],
  (: l' :)
  ["moi l'homme",
   "Moi l'Homme"],
  ["l'emmerdeur",
   "L'Emmerdeur"],
  (: m' :)
  ["ça m'intéresse",
   "Ca m'intéresse"],
  ["avoue tu m'aimes",
   "Avoue tu m'aimes"],
  (: n' :)
  ["je n'ai pas raison",
   "Je n'ai pas Raison"],
  ["n'ai pas peur",
   "N'ai pas Peur"],
  (: s' :)
  ["elle s'est fait mal",
   "Elle s'est Fait Mal"],
  ["s'affoler pour rien",
   "S'affoler pour Rien"],
  (: 's :)
  ["simon's cat",
   "Simon's Cat"],
  (: t' :)
  ["si tu freines t'es un lâche",
   "Si tu Freines t'es un Lâche"],
  ["t'abuses ikko",
   "T'abuses Ikko"],

  (: wordReplacementsSpecialChars :)
  (: - :)
  ["en extrême-orient",
   "En Extrême-Orient"],
  ["extrême-orient",
   "Extrême-Orient"],
  (: -t- :)
  ["comment s'appelle-t-il?",
   "Comment s'appelle-t-il?"],
  ["ce mot existe-t-il?",
   "Ce Mot Existe-t-il?"],
  (: A.C.R.O.N.Y.M.S :)
  ["avec s.a.m.",
   "Avec S.A.M."],
  ["s.a.m.",
   "S.A.M."],

  (: upperCaseReplacements :)
  (: à :)
  ["motards à jamais",
   "Motards à Jamais"],
  ["à toute allure",
   "A Toute Allure"],
  (: é :)
  ["le bruit de l'écho",
   "Le Bruit de l'Echo"],
  ["écho des savanes",
   "Echo des Savanes"],
  (: è :)
  ["post ère moderne",
   "Post Ere Moderne"],
  ["ère moderne",
   "Ere Moderne"],
  (: ç :)
  ["ça m'intéresse",
   "Ca m'intéresse"],
  ["tu aimes ça",
   "Tu Aimes Ca"],

  (: withNewWords :)
  (: tutu :)
  ["mon nouvau texte avec tutu",
   "Mon Nouvau Texte avec tutu"],
  ["tutu est arrivé",
   "Tutu Est Arrivé"],
  (: toto :)
  ["mon nouvau texte avec tutu et tata",
   "Mon Nouvau Texte avec tutu et tata"],
  ["tata et tutu sont là",
   "Tata et tutu Sont Là"],
  (: tata :)
  ["mon nouvau texte avec tata sans tutu",
   "Mon Nouvau Texte avec tata sans tutu"],
  ["Toto se rajoute à tutu et tata",
   "Toto se Rajoute à tutu et tata"],

  (: withoutNewWords :)
  (: tutu :)
  ["mon nouvau texte avec tutu",
   "Mon Nouvau Texte avec Tutu"],
  ["tutu est arrivé",
   "Tutu Est Arrivé"],
  (: toto :)
  ["mon nouvau texte avec tutu et tata",
   "Mon Nouvau Texte avec Tutu et Tata"],
  ["tata et tutu sont là",
   "Tata et Tutu Sont Là"],
  (: tata :)
  ["mon nouvau texte avec tata sans tutu",
   "Mon Nouvau Texte avec Tata sans Tutu"],
  ["Toto se rajoute à tutu et tata",
   "Toto se Rajoute à Tutu et Tata"],

  (: keepCapitalizedSpecials :)
  (: Ç :)
  ["tu aimes ça",
   "Tu Aimes Ça"],
  ["ça va ou bien",
   "Ça Va ou Bien"],
  (: À :)
  ["à l'eau",
   "À l'Eau"],
  ["lampe à pétrole",
   "Lampe à Pétrole"],
  (: À :)
  ["l'été indien",
   "L'Été Indien"],
  ["en avant vers les étoiles",
   "En Avant vers les Étoiles"]
)


return
<tests>
{
  for $test in $tests
  let $result := tcf:convert($test?1)
  let $ok := $result = $test?2
  return <result ok="{$ok}" expected="{$test?2}">{$result}</result>
}
</tests>
