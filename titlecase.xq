xquery version "3.1";

(:
  This is a port of the titlecase-french javascript library by Benoit Vallon
  https://github.com/benoitvallon/titlecase-french
 :)

module namespace tcf = "http://dracor.org/ns/exist/titlecase-french";

declare variable $tcf:capitalizeAfterQuoteAnd := ('l', 'd');
declare variable $tcf:lowerCaseAfterQuoteAnd := ('c', 'j', 'm', 'n', 's', 't');
declare variable $tcf:lowerCaseWordList := (
  (: definite articles :)
  'le', 'la', 'les',
  (: indefinite articles :)
  'un', 'une', 'des',
  (: partitive articles :)
  'du', 'de', 'des',
  (: contracted articles :)
  'au', 'aux', 'du', 'des',
  (: demonstrative adjectives :)
  'ce', 'cet', 'cette', 'ces',
  (: exclamative adjectives :)
  'quel', 'quels', 'quelle', 'quelles',
  (: possessive adjectives :)
  'mon', 'ton', 'son', 'notre', 'votre', 'leur', 'ma', 'ta', 'sa', 'mes',
  'tes', 'ses', 'nos', 'vos', 'leurs',
  (: coordinating conjunctions :)
  'mais', 'ou', 'et', 'donc', 'or', 'ni', 'car', 'voire',
  (: subordinating conjunctions :)
  'que', 'qu', 'quand', 'comme', 'si', 'lorsque', 'lorsqu', 'puisque',
  'puisqu', 'quoique', 'quoiqu',
  (: prepositions :)
  'à', 'chez', 'dans', 'entre', 'jusque', 'jusqu', 'hors', 'par', 'pour',
  'sans', 'vers', 'sur', 'pas', 'parmi', 'avec', 'sous', 'en',
  (: personal pronouns :)
  'je', 'tu', 'il', 'elle', 'on', 'nous', 'vous', 'ils', 'elles', 'me', 'te',
  'se', 'y',
  (: relative pronouns :)
  'qui', 'que', 'quoi', 'dont', 'où',
  (: others :)
  'ne'
);

declare function local:isLowerCaseWord ($text as xs:string?) as xs:boolean {
  if (lower-case($text) = $tcf:lowerCaseWordList) then true() else false()
};

declare function local:capitalizeFirst ($text as xs:string?) as xs:string? {
  upper-case(substring($text, 1, 1)) || substring($text, 2)
};

declare function local:capitalizeFirstIfNeeded ($text as xs:string?) as xs:string? {
  if (local:isLowerCaseWord($text)) then
    lower-case($text)
  else
    local:capitalizeFirst($text)
};

declare function local:capitalizeWithQuote ($text as xs:string?) as xs:string? {
  let $words := tokenize($text, "'")
  return if(count($words) = 2) then
    (: could be d' or l', if it is the first word (l'Autre) :)
    if (
      string-length($words[1]) = 1 and
      lower-case($words[1]) = $tcf:capitalizeAfterQuoteAnd
    ) then
      lower-case($words[1]) || "'" || local:capitalizeFirstIfNeeded($words[2])
    (: could be c', m', t', j', n', s' if it is the first word (c'est) :)
    else if (
      string-length($words[1]) = 1 and
      lower-case($words[1]) = $tcf:lowerCaseAfterQuoteAnd
    ) then
      lower-case($words[1]) || "'" || lower-case($words[2])
    (: could be 's :)
    else if (string-length($words[2]) = 1) then
      local:capitalizeFirstIfNeeded($words[1]) || "'" || lower-case($words[2])
    (: could be jusqu'au :)
    else if (string-length($words[1]) > 1 and string-length($words[2]) > 1) then
      local:capitalizeFirstIfNeeded($words[1]) || "'"
        || local:capitalizeFirstIfNeeded($words[2])
    else
      $text
  else
    local:capitalizeFirstIfNeeded($text)
};

declare function local:hasQuote ($text as xs:string?) as xs:boolean {
  count(tokenize($text, "'")) = 2
};

declare function local:capitalizeEachWord ($text as xs:string?) as xs:string? {
  let $words := for $word at $pos in tokenize(lower-case($text), ' +')
    let $isComposedWord := local:hasQuote($word)

    let $txt := if ($isComposedWord) then
      local:capitalizeWithQuote($word) else $word

    let $txtWithDash := tokenize($txt, '-')
    let $txtWithDot := tokenize($txt, '\.')

    return
    (: look for - :)
    if (count($txtWithDash) = 2) then
      local:capitalizeFirst($txtWithDash[1]) || "-"
        || local:capitalizeFirstIfNeeded($txtWithDash[2])

    (: look for . :)
    else if (count($txtWithDot) > 1) then
      string-join(for $w in $txtWithDot return local:capitalizeFirst($w), ".")

    (: look for know words to replace if it is not the first word of the sentence :)
    else if ($pos = 1) then
      local:capitalizeFirst($txt)
    else if (local:isLowerCaseWord($txt)) then
      lower-case($txt)
    else if ($isComposedWord) then
      $txt
    else
      local:capitalizeFirst($txt)
    
  return string-join($words, ' ')
};

declare function local:replaceCapitalizedSpecials (
  $text as xs:string?
) as xs:string? {
  translate($text, 'ÀÂÄÉÈÊËÇÎÏÔÖÛÜÙ', 'AAAEEEECIIOOUUU')
};

declare function tcf:convert ($text as xs:string?) as xs:string? {
  $text => local:capitalizeEachWord() => local:replaceCapitalizedSpecials()
};

declare function tcf:convert-ou ($text as xs:string?) as xs:string? {
  $text => local:capitalizeEachWord() => local:replaceCapitalizedSpecials()
};
