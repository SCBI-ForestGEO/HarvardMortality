# Data tests for mortality census

## Table of tests 

name|level | category | applied to | test  | warning (W) or error (E) | coded | requires field fix? | auto fix (when applicable) | core or SCBI add-on?
----  |----  | ---- | ----  | ----  | ---- | ---- | ---- | ----  | ---- 
``|plot | census progress | all stems in census | percent trees censused | NA |  2021 | NA | NA | core
``|plot | census progress | all stems in census | list or map of quadrats completed, with additional category for censused with fixes pending | NA |  2021 | NA | NA | core 
``|quadrat | completion check | newly censused quadrats | all trees censused |  E | 2021 | Y | NA | core
``|quadrat  | consistency check | newly censused quadrats | no trees are duplicated |   E | 2021 | N | use latest record | core
``|tree | completion check | newly censused trees (A, AU, DS) | `SurveyorID` is recorded | E | 2021 | N | NA | core
``|tree | completion check | newly censused trees (A, AU, DS) | `crown position` is recorded | E | 2021 | Y | NA | core
``|tree | completion check | newly censused trees (A, AU, DS) |`percentage of crown intact` is recorded | E | 2021 | Y | NA | core
``|tree | completion check | newly censused trees (A, AU, DS) |`percentage of crown living` is recorded | E | 2021 | Y | NA | core
``|tree | consistency check | newly censused trees (A, AU, DS) | `percentage of crown living` ≤ `percentage of crown intact` | E | 2021 | initially | [issue 13](https://github.com/SCBI-ForestGEO/SCBImortality/issues/13)| core
``|tree | consistency check | newly censused trees (DS or DC) | `percentage of crown living` = 0 | E | 2021 | Y | NA| core
``|tree | consistency check | newly censused trees (alive) | no FAD is selected; no record of wounded main stem, canker, or rotting trunk; DWR (dead with resprouts) not selected | E | 2021 | sometimes | if `percentage of crown living`>0, change status to AU; otherwise requires field check (to determine DS vs DC) | core
``|tree | consistency check | newly censused trees (AU) | DWR (dead with resprouts) not selected |E |  2021 | initially | ---| core
``|tree | completion check | newly censused trees (AU, DS or DC) **that were live in previous census** | at least one FAD is selected (OR level selected for `wounded main stem`,`canker,swelling,deformity`, `rotting main stem`)* | E |2021 | Y | NA | core
``|tree | completion check | newly censused trees (AU or dead, with "wound" selected as FAD) | level selected for `wounded main stem` | E |2021 | Y | NA | core
``|tree | completion check | newly censused trees (AU or dead, with "canker" selected as FAD) | level selected for `canker,swelling,deformity` |E | 2021 | Y | NA | core
``|tree | completion check | newly censused trees (AU or dead, with "rotting stem" or "hollow stem" selected as FAD) | level selected for `rotting main stem` | E |2021 | Y | NA | core
``|tree | completion check | newly censused trees (AU, DS or DC) | at least one photo was taken | W | not yet | Y | NA | core
``|tree | consistency check | newly censused trees (AU or dead, with level selected for `wounded main stem`)| "wound" selected as FAD, AU or dead selected as status | W| 2021 | N | add wound to FAD list* | core
``|tree | consistency check | newly censused trees (AU or dead, with level selected for `canker,swelling,deformity`)| "canker" selected as FAD | W| 2021 | N | add canker to FAD list* | core
``|tree | consistency check | newly censused trees (AU or dead, with level selected for `rotting main stem`)| "rotting stem" or "hollow stem" selected as FAD| W| 2021 | N | add `rotting main stem` to FAD list* | core
``|tree | consistency check | newly censused trees (any FAD selected, or level selected for `canker,swelling,deformity`, `wounded main stem` , or `rotting main stem`)| status selected as AU or dead | W| 2021 | N | change live to AU | core
``|tree | consistency check - with previous | newly censused trees (A or AU) | tree was A or AU in previous year with note (indicating previous misclassification) | W| 2021 | Y | NA| core
``|tree | consistency check - with previous | newly censused trees (A or AU) | tree was A or AU in previous year with no note | E| 2021 | Y | NA| core
``|tree | consistency check - with previous | newly censused trees (A or AU or DS) | tree was not DC in previous year | W| 2021 | Y | NA| core or SCBI?



