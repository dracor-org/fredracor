# FreDraCor (French Drama Corpus, TEI P5)
## Corpus Description
Based on the extensive work from Paul Fièvre, we are working towards a DraCor-ready
version of the Théâtre Classique. The result should become a valid TEI P5 resource. 

By now, the 1452 files from the source have been structurally cleaned and converted. We copied some information from the `castList` to the 
`particDesc` section and tried to preserve as much as possible.

Besides the fact that all texts are out of copyright, the files (including intellectual work represented as markup) is – regards to the source files – licensed under a 
[CC BY NC SA 3.0]() licence. 

## Changes made on top of the source
Here is a list of changes we made:
- adding TEI namespace
- adding XML decleration
- replacing the teiHeader with a DraCor-specific version
    - preserveing as much as possible
- adding a `particDesc`
- translating the `@who` and `@xml:id`
    - prefix leading numbers to be XML compatible
    - remove diacritics and other special characters (e.g. `*`) from the IDs
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
- 35 documents are using the TEI namespace - removed to process them like all the others (of course the result is in the namespace)
- removed text in `tei:sp` at audiffret-albertdurer.xml
- move ending dot into `tei:castItem`, when it is right after (and so a child of `tei:castList`)
- remove empty `@type`

## TODOs:
- ensure DraCor IDs stay the same. Currently they are generated from a position in an alphabetic list and will change when an item is inserted in the list before.
- as of 2020-12-04 we do not have valid TEI-all
- following error is reported during transformation on 112, 137 and 1112: `04 Dec 2020 13:13:54,509 [qtp281487983-628] INFO  (Predicate.java [selectByPosition]:454) - contextSet and outerNodeSet don't share any document`
- rewrite element tei:ab[type="stances"] (and possible typos) to tei:lg

## How to rebuild from source

To rebuild from the source a script is present that uses podman (docker) container to execute XQuery scripts.
It is organized in the following way:
0. prepare a work directrory at `/tmp/fredracor`
1. start a bunch of pods (container) in parallel running eXist-db
2. Load the source corpus on pod #1
3. distribute the files to the pods (container) in parallel
4. run the main script [`transform.xq`](transform.xq) that will also prepare a validation for every file
5. wait for the results and copy them to THIS repo dir
6. collect the log files (with validation output)
7. stop all pods

### Dependencies
- bash
- curl
- podman
  - MAY BE this will work with `docker` as well. simply search'n'replace the term `podman` with `docker` in the script.

You should not have any problems with a recent Fedora Linux! :-)

### Usage
Run `./parallelize.sh` with or without the following options.

#### debug mode
`./parallelize.sh --debug`

For developing purposes the debug mode will create only 2 instances (pods or container) and will work on just a few (and only small) files. But if not present, it
will load the complete source to a temporary directory. You can use the loaded files in later runs as long as your local `/tmp` folder is not removed.
If you want more or less threads and number of files, alter the variable `THREADS=` and `num=` in the script.

For further debugging the combined log from every pod can be viewed with `podman logs -f $(cat /tmp/fredracor/container)` during runtime.

#### Progress Bar
`./parallelize.sh --progress`

[The internet does not forget.](https://twitter.com/umblaetterer/status/608349018113101824) That's why the script can be run with an optional progress bar shown in the terminal.