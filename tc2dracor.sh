#!/bin/sh

# page to scrape the TEI URLs from
INDEX_URL="http://theatre-classique.fr/pages/programmes/PageEdition.php"

SRC_DIR=./SOURCES
# directory with original downloads
ORIG_DIR=$SRC_DIR/orig
# directory with fixed TEI files
TEI_DIR=$SRC_DIR/tei

LYNX="lynx -listonly -nonumbers -dump $INDEX_URL"
GREP="grep /pages/documents/"

N=0
IDS_FILE=ids.xml
TMP_IDS=$(mktemp ids.XXXXX)

if ! [ -d $ORIG_DIR ]; then
  mkdir -p $ORIG_DIR
else
  echo "Using files in $ORIG_DIR."
  echo "For a fresh download remove files in that directory."
  echo
fi

mkdir -p $TEI_DIR

# retrieve TEI files from Theatre Classique
for url in $($LYNX | $GREP); do
  name=$(basename $url | sed 's/\.[Xx][Mm][Ll]$//')
  orig="$ORIG_DIR/$name.xml"
  tei="$TEI_DIR/$name.xml"

  if ! [ -f $orig ]; then
    wget -O $orig $url
    # add newline to end of originals for cleaner diffs
    echo >> $orig
  fi

  # Here we create a copy of the original files fixing the document elements in
  # the following ways:
  # - replace TEI.2 with TEI elements
  # - add xmlns and xml:lang where missing
  # - add an id attribute using the filename as ID
  sed "s/<TEI[^>]*>/<TEI xmlns=\"http:\/\/www.tei-c.org\/ns\/1.0\" xml:id=\"$name\" xml:lang=\"fr\">/" \
    $orig | sed 's/<\/TEI\.2>/<\/TEI>/' > $tei

  N=$(($N+1))
  id=$(printf "fre%06d" $N)
  echo "  <play dracor=\"$id\" orig=\"$name\" url=\"$url\"/>" >> $TMP_IDS
done

if ! [ -f $IDS_FILE ]; then
  echo "Creating $IDS_FILE..."
  echo '<ids>' > $IDS_FILE
  cat $TMP_IDS >> $IDS_FILE
  echo '</ids>' >> $IDS_FILE
fi

rm $TMP_IDS

for f in $TEI_DIR/*.xml; do
  # adjust file name
  n=$(basename $f .xml \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/_/-/')
  echo $n
  # add particDesc and Wikidata IDs
  saxon $f tc2dracor.xsl | xmllint --format - > tei/$n.xml
done
