# Data tests for mortality census

## Table of tests 

test name/location |level | category | applied to | test  | warning (W) or error (E) | coded | requires field fix? | auto fix (when applicable) | core or SCBI add-on?
----  |----  | ---- | ----  | ----  | ---- | ---- | ---- | ----  | ---- 
Repo README |plot | census progress | all stems in census | percent trees censused | NA |  2021 | NA | NA | core
Repo README |plot | census progress | all stems in census | list or map of quadrats completed, with additional category for censused with fixes pending | NA |  2021 | NA | NA | core 
`quadrat_censused_missing_stems.csv`|quadrat | completion check | newly censused quadrats | all trees censused |  E | 2021 | Y | NA | core
`duplicated_stem`|quadrat  | consistency check | newly censused quadrats | no trees are duplicated |   E | 2021 | N | use latest record | core
`personnel_missing`|tree | completion check | newly censused trees (A, AU, DS) | `SurveyorID` is recorded | E | 2021 | N | NA | core
`missing_crown_position`|tree | completion check | newly censused trees (A, AU, DS) | `crown position` is recorded | E | 2021 | Y | NA | core
`missing_percent_crown_intact`|tree | completion check | newly censused trees (A, AU, DS) |`percentage of crown intact` is recorded | E | 2021 | Y | NA | core
`missing_percent_crown_living`|tree | completion check | newly censused trees (A, AU, DS) |`percentage of crown living` is recorded | E | 2021 | Y | NA | core
`crown_living_greater_than_crown_intact`|tree | consistency check | newly censused trees (A, AU, DS) | `percentage of crown living` ≤ `percentage of crown intact` | E | 2021 | initially | [issue 13](https://github.com/SCBI-ForestGEO/SCBImortality/issues/13)| core
??? |tree | consistency check | newly censused trees (DS or DC) | `percentage of crown living` = 0 | E | 2021 | Y | NA| core
`status_A_but_unhealthy` & `unhealthy_but_wrong_status`|tree | consistency check | newly censused trees (alive) | no FAD is selected; no record of wounded main stem, canker, or rotting trunk; DWR (dead with resprouts) not selected | E | 2021 | sometimes | if `percentage of crown living`>0, change status to AU; otherwise requires field check (to determine DS vs DC) | core
`status_AU_but_DWR_selected`|tree | consistency check | newly censused trees (AU) | DWR (dead with resprouts) not selected |E |  2021 | initially | ---| core
`status_AU_DS_or_DC_but_no_FAD`|tree | completion check | newly censused trees (AU, DS or DC) **that were live in previous census** | at least one FAD is selected (OR level selected for `wounded main stem`,`canker,swelling,deformity`, `rotting main stem`)* | E |2021 | Y | NA | core
??? |tree | completion check | newly censused trees (AU, DS or DC) | at least one photo was taken | W | not yet | Y | NA | core
`wounded_but_no_level` |tree | completion check | newly censused trees (AU or dead, with "wound" selected as FAD) | level selected for `wounded main stem` | E |2021 | Y | NA | core
`canker_but_no_level` |tree | completion check | newly censused trees (AU or dead, with "canker" selected as FAD) | level selected for `canker,swelling,deformity` |E | 2021 | Y | NA | core
`rot_but_no_level` |tree | completion check | newly censused trees (AU or dead, with "rotting stem" or "hollow stem" selected as FAD) | level selected for `rotting main stem` | E |2021 | Y | NA | core
`wounded_level_but_wrong_status_or_FAD` |tree | consistency check | newly censused trees (AU or dead, with level selected for `wounded main stem`)| "wound" selected as FAD, AU or dead selected as status | W| 2021 | N | add wound to FAD list* | core
`canker_level_but_wrong_status_or_FAD` |tree | consistency check | newly censused trees (AU or dead, with level selected for `canker,swelling,deformity`)| "canker" selected as FAD | W| 2021 | N | add canker to FAD list* | core
`rot_level_but_wrong_status_or_FAD` |tree | consistency check | newly censused trees (AU or dead, with level selected for `rotting main stem`)| "rotting stem" or "hollow stem" selected as FAD| W| 2021 | N | add `rotting main stem` to FAD list* | core
??? |tree | consistency check | newly censused trees (any FAD selected, or level selected for `canker,swelling,deformity`, `wounded main stem` , or `rotting main stem`)| status selected as AU or dead | W| 2021 | N | change live to AU | core
`Dead_but_now_alive_no_note` |tree | consistency check - with previous | newly censused trees (A or AU) | tree was A or AU in previous year with no note | E| 2021 | Y | NA| core
`Dead_but_now_alive_with_note` |tree | consistency check - with previous | newly censused trees (A or AU) | tree was A or AU in previous year with note (indicating previous misclassification) | W| 2021 | Y | NA| core
`DC_but_now_A_AU_or_DS` |tree | consistency check - with previous | newly censused trees (A or AU or DS) | tree was not DC in previous year | W| 2021 | Y | NA| core or SCBI?



