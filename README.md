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
- `4+` documents are not available via the website (Not Found):
  - marivaux%20-acteursdebonnefoi.xml
  - pg-fausseinvite.xml
  - bernardt-plaisirsdudimanche.xml
  - bizet-simonot-gillestoutseul.xml
- 35 documents are using the TEI namespace - removed to process them like all
  the others (of course the result is in the namespace)
- removed text in `tei:sp` at audiffret-albertdurer.xml
- move ending dot into `tei:castItem`, when it is right after (and so a child of
  `tei:castList`)
- remove empty `@type`

## TODO

- ensure DraCor IDs stay the same. Currently they are generated from a position
  in an alphabetic list and will change when an item is inserted in the list before.
- as of 2020-12-04 we do not have valid TEI-all
- the following error is reported during transformation on 112, 137 and 1112:
  `04 Dec 2020 13:13:54,509 [qtp281487983-628] INFO  (Predicate.java
  [selectByPosition]:454) - contextSet and outerNodeSet don't share any document`
- rewrite element `tei:ab[@type="stances"]` (and possible typos) to tei:lg

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
scripted workflow has been set up that runs an XQuery script to convert the
original files. To speed up the process multiple instances can be started in
parallel using either [Podman](https://podman.io) or
[Docker](https://www.docker.com). These are the main steps of this workflow:

0. create a temporary directory (e.g. `/tmp/tc2dracor-XXXXXX`)
1. start 2 or more pods (or containers) running eXist-db
3. distribute the source files to the pods in parallel
4. run the main script [`tc2dracor.xq`](tc2dracor.xq) which stores the results
   in the temporary directory
5. copy the resulting documents to the [tei](tei) directory
6. persist the container log files
7. stop and remove all pods (or containers)

### Usage

```bash
./tc2dracor [options] SOURCES_DIR [TEI_DIR]
```

#### `SOURCES_DIR`

The conversion script expects a directory containing the source files as its
main argument. This could be the `xml` directory of the checked out repository
at http://github.com/dracor-org/theatre-classique.

### Options

#### -h, --help

Display usage information and exit.

#### -n, --num N

Number of pods or containers to start. Default: 2

#### -p, --port PORTNUMBER

As an alternative to using containers an eXist database already running on
`localhost` can be used by passing its port number. With this option the sources
will be copied to the `/db/tc2dracor/sources` collection of this database. No
parallel processing will take place.

#### -D, --docker

By default the conversion script uses `podman` but falls back to `docker` if
`podman` is not available. This flag allows you to force the use of `docker`
when `podman` would be available.

#### -T, --test

Activates test mode where only a few and small sized files are selected from the
sources directory. This mode is mostly for debugging convenience, freeing you
from picking a set of test files yourself.

Hint: For debugging across multiple containers you may also watch the combined
log from every pod can be viewed while the conversion is running:

```bash
podman logs -f $(cat $(ls -rtd /tmp/tc2dracor-* | tail -1)/containers)
```

#### -p, --progress

[The internet does not forget.](https://twitter.com/umblaetterer/status/608349018113101824)
That's why the script can be run with an optional progress bar shown in the
terminal.
