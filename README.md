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

TODOs:
- ensure DraCor IDs stay the same. Currently they are generated from a position in an alphabetic list and will change when an item is inserted in the list before.
- as of 2020-12-04 we do not have valid TEI-all
- following error is reported during transformation on 112, 137 and 1112: `04 Dec 2020 13:13:54,509 [qtp281487983-628] INFO  (Predicate.java [selectByPosition]:454) - contextSet and outerNodeSet don't share any document`