# FreDraCor (French Drama Corpus, TEI P5)

## Corpus Description

Based on the extensive work from Paul Fièvre, we are working towards a
DraCor-ready version of the Théâtre Classique. The result should become a valid
TEI P5 resource.

By now, the 1452 files from the source have been structurally cleaned and
converted. We copied some information from the `castList` to the `particDesc`
section and tried to preserve as much as possible.

Besides the fact that all texts are out of copyright, the files (including
intellectual work represented as markup) is – according to the source files –
licensed under a [CC BY NC SA 3.0]() licence.

## Changes made on top of the source

Here is a list of changes we made:

- adding TEI namespace
- adding XML decleration
- replacing the `teiHeader` with a DraCor-specific version
  - preserveing as much as possible
- adding a `particDesc`
- translating the `@who` and `@xml:id`
  - prefix leading numbers to be XML compatible
  - remove diacritics and other special characters (e.g. `*`) from IDs
  - separate multiple speakers by whitespace
  - add a leading `#` to become a data pointer
- moving numeral `@id` to `@n` on `tei:s` and `tei:l`
- refine licence statement
  - use current version 3.0 of the named licence
  - add URL to the complete document
- replace `@id` with `@corresp` at `castItem/role`
- move `tei:l/@syll` in comment
- upper-case `tei:l/@part`
- move unknown attributes from `tei:role` to comment
- renamed unknown `docDate/@value` to `docDate/@when`
- moved `addresse` to `tei:opener/tei:salute`
- moved `sgnature` to `tei:signed`
- removed a text `4+` between speech acts at ABEILLE_CORIOLAN.xml
- 35 documents are using the TEI namespace - removed to process them like all
  the others (of course the result is in the namespace)
- removed text in `tei:sp` at audiffret-albertdurer.xml
- move ending dot into `tei:castItem`, when it is right after (and so a child of
  `tei:castList`)
- remove empty `@type`

## TODO

- as of 2020-12-04 we do not have valid TEI-all
- the following error is reported during transformation on 112, 137 and 1112:
  `04 Dec 2020 13:13:54,509 [qtp281487983-628] INFO  (Predicate.java
  [selectByPosition]:454) - contextSet and outerNodeSet don't share any document`
- rewrite element `tei:ab[@type="stances"]` (and possible typos) to tei:lg

## DraCor IDs

Each FreDraCor play is given a DraCor ID (e.g.
[`fre000784`](tei/jarry-uburoi.xml#L20)). These IDs are mapped to the Théâtre
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
   auxiliary files ([authors.xml](authors.xml), [ids.xml](ids.xml)) to the
   database(s)
3. process each source file by posting it to the transformation XQuery and
   storing the output to the [tei](tei) directory
4. persist the eXist log files for debugging
5. stop and remove all pods (or containers)

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
