# FreDraCor (French Drama Corpus, TEI P5)

## Corpus description

Based on the extensive work of Paul Fièvre, we have been working on a
[**DraCor**](https://dracor.org/)-ready
version of [Théâtre Classique](https://www.theatre-classique.fr/index.html).
FreDraCor is intended to be a valid TEI P5 resource.

By now, the 1560 files from the source have been structurally cleaned and
converted. We copied some information from the `castList` to the `particDesc`
section and tried to preserve as much as possible.

Besides the fact that all texts are out of copyright, the files (including
intellectual work represented as markup) is – according to the source files –
licensed under a [CC BY NC SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
licence.

The corpus can be explored at [**dracor.org/fre**](https://dracor.org/fre).

## To cite FreDraCor …

… we suggest the following:

* French Drama Corpus (FreDraCor): A TEI P5 Version of Paul Fièvre's "Théâtre Classique" Corpus. Edited by Carsten Milling, Frank Fischer and Mathias Göbel. Hosted on GitHub, 2021–. https://github.com/dracor-org/fredracor

## Changes, corrections and additions we have made

Here are, among others, the most significant modifications performed on the
original documents:

- add TEI namespace
- add XML declaration
- replace the `teiHeader` with a DraCor-specific version while preserving as
  much as possible of original content
- refine licence statement using current version 3.0 of the given licence and
  adding URL
- add a `particDesc`
- transform the `@xml:id` and `@who` attributes into proper IDs and ID
  references
- transform numeral `@id` into `@n` on `tei:s` and `tei:l`
- replace `@id` with `@corresp` at `castItem/role`
- upper-case `tei:l/@part`
- remove instances of `tei:l/@syll` (commented)
- remove unknown attributes from `tei:role` (commented)
- rename `docDate/@value` to `docDate/@when`
- transform `addresse` element to `tei:opener/tei:salute`
- transform `signature` element to `tei:signed`
- remove empty `@type`
- add written and print dates where available
- adjust case of character names
  (https://github.com/dracor-org/fredracor/pull/14)
- normalize author names
- add Wikidata IDs for authors and plays (work in progress)

For comprehensive insight into our changes see both the
[adjustments](https://github.com/dracor-org/theatre-classique/compare/dracor)
made on the
[`dracor` branch of the theatre-classique](https://github.com/dracor-org/theatre-classique/tree/dracor)
repository and the [tc2dracor.xq](tc2dracor.xq) transformation script.

## DraCor IDs

Each FreDraCor play is given a DraCor ID (e.g.
[`fre000784`](tei/jarry-ubu-roi.xml#L21)). These IDs are mapped to the Théâtre
Classique documents in [ids.xml](ids.xml). When a new play from Théâtre
Classique is added to the corpus a new ID needs to be assigned and added to
`ids.xml`.

## Validation

To check the current validation status of the corpus against the
[tei_all](https://tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng)
schema run `./validate` from the root of the repo. (You will need to have
[Jing](https://relaxng.org/jclark/jing.html) installed for this to work.)

In fact, this script can be used to validate any directory of TEI documents.
Just pass the directory as the first argument. For instance, if you have
[gerdracor](https://github.com/dracor-org/gerdracor) checked out next to
*fredracor*, try:

```bash
./validate ../gerdracor/tei
```

## How to rebuild from source

For building the FreDraCor documents from the Théâtre Classique sources a
scripted workflow has been set up that processes the original files with an
[XQuery transformation](tc2dracor.xq). To speed up the process multiple eXist DB
instances can be started in parallel using either [Podman](https://podman.io) or
[Docker](https://www.docker.com). These are the main steps of this workflow:

1. start one or more pods (or containers) running eXist-db
2. loading the transformation XQuery [`tc2dracor.xq`](tc2dracor.xq) and
   auxiliary files ([authors.xml](#authorsxml), [ids.xml](ids.xml)) to the
   database(s)
3. process each source file by posting it to the transformation XQuery and
   storing the output to the [tei](tei) directory
4. stop and remove all pods (or containers)

### Usage

```bash
./tc2dracor [options] SOURCE_FILE [SOURCE_FILE...]
```

#### `SOURCE_FILE`

The conversion script expects one or more source files as its arguments. These
would typically be files from the `xml` directory of the checked out
[`dracor`](https://github.com/dracor-org/theatre-classique/tree/dracor) branch
of the [theatre-classique](http://github.com/dracor-org/theatre-classique)
repository:

```bash
./tc2dracor ../theatre-classique/xml/*.{xml,XML}
```

__NOTE:__ The `dracor` branch of the `theatre-classique` repo contains
corrections and amendments to the original source files which the conversion
script relies on but have not (yet) been adopted upstream.

NOTE: For the attribution of DraCor IDs to work, the file names of the source
files need to match the ones of the original documents used in
[ids.xml](ids.xml) (see [DraCor IDs](#dracor-ids)).

### Options

#### -h, --help

Display usage information and exit.

#### -n, --num N

Number of pods or containers to start. Default: 1

#### -p, --port PORTNUMBER

As an alternative to using containers an eXist database already running on
`localhost` can be used by passing its port number. With this option the sources
will be copied to the `/db/tc2dracor/sources` collection of this database. No
parallel processing will take place.

#### -o, --output DIRECTORY

Directory to write the created TEI files to. Default: `./tei`

#### -D, --docker

By default the conversion script uses `podman` but falls back to `docker` if
`podman` is not available. This flag allows you to force the use of `docker`
when `podman` would be available.

#### -P, --progress

[The internet does not forget.](https://twitter.com/umblaetterer/status/608349018113101824)
That's why the script can be run with an optional progress bar shown in the
terminal.

Hint: For debugging across multiple containers you may also watch the combined
log from every pod can be viewed while the conversion is running:

```bash
podman logs -f $(cat $(ls -rtd /tmp/tc2dracor-* | tail -1)/containers)
```

For debugging purposes the logs of all containers are also stored in a temporary
working directory after the transformation has finished. Use the `-v` option to
see the exact location of these files at the end of the script run.

### authors.xml

The transformation process uses the file [authors.xml](authors.xml) to unify
and enrich author information within FreDraCor. The entries in this file provide
a canonical `tei:author` element for each author together with the matching
author string in the source documents (in the  `name` elements), e.g.:

```xml
<author>
  <author xmlns="http://www.tei-c.org/ns/1.0">
    <persName>
      <forename>Charles</forename>
      <surname>Collé</surname>
    </persName>
    <idno type="isni">0000000121258527</idno>
    <idno type="wikidata">Q2404425</idno>
  </author>
  <name>Charles COLLÉ (1709-1783)</name>
  <name>COLLE, Charles</name>
  <isni>0000 0001 2125 8527</isni>
</author>
```

When the transformation script discovers an author that does not yet have an
entry in authors.xml, trying to properly identify the name parts and also
looking up the Wikidata ID if the source TEI provides an ISNI. The new entries
are written to the file `authors.update.xxxx.xml` (where 'xxxx' is the eXist DB
port number used to run the transformation). This file should be merged manually
into `authors.xml`.

## TODO

As of now, 122 documents do not comply to the TEI-All schema yet. See the
[list of open issues](https://github.com/dracor-org/fredracor/issues) for
details on this and possible other enhancements.
