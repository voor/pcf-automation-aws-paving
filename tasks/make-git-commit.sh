#!/usr/bin/env bash

cat /var/version && echo ""
set -eux
git config --global user.email "$GIT_AUTHOR_EMAIL"
git config --global user.name "$GIT_AUTHOR_NAME"

git clone repository repository-commit

for fsp in ${FILE_SOURCE_PATHS}
do
cp file-source/"${fsp}" repository-commit/"$FILE_DESTINATION_DIRECTORY"
done

cd repository-commit
git add -A
git commit -m "$COMMIT_MESSAGE" --allow-empty
