#!/bin/bash
.path.sh


fsttablecompose G.fst b.fst  | \
  fstdeterminizestar --use-log=true | \
  fstminimizeencoded  > bG.fst
