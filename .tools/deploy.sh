#!/usr/bin/env bash

nvm install lts/*
npm install --save-dev semantic-release
npm install --save-dev conventional-changelog-eslint
npm install --save-dev conventional-changelog-conventionalcommits
npm install --save-dev @semantic-release/release-notes-generator
npm install --save-dev @semantic-release/changelog
npm install --save-dev @semantic-release/github
npm install --save-dev @semantic-release/exec
npx -y semantic-release --dry-run --debug