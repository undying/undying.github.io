#! /bin/bash

to_commit=${1:-.}
cd _site || exit

git add "${to_commit}"
git commit -aF - < <(cd .. && git log -1 --pretty=%B)
git push

