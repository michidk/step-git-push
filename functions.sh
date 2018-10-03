#!/bin/bash

function getAllStepVars {
  ( set -o posix ; set ) | grep WERCKER_GIT_PUSH | sed -E 's/=.+//g' | xargs
}

function sanitizeOutput {
  echo "$@" | sed -E 's_(.+://).+@_\1oauth-token@_g'
}

function s_info {
  info "$(sanitizeOutput $@)"
}

function s_success {
  success "$(sanitizeOutput $@)"
}

function s_debug {
  if [ "$WERCKER_GIT_PUSH_DEBUG" == "true" ]; then
    info "DEBUG: $(sanitizeOutput $@)"
  fi
}

function s_warning {
  info "WARNING: $(sanitizeOutput $@)"
}

function s_fail {
  fail "$(sanitizeOutput $@)"
}

function s_setMessage {
  setMessage "$(sanitizeOutput $@)"
}

# RETURNS REPO_PATH SET in GIT_PUSH or current WERCKER
function getRepoPath {
  if [ -n "$WERCKER_GIT_PUSH_REPO" ]; then
    echo "$WERCKER_GIT_PUSH_REPO"
  else
    echo "$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY"
  fi
}

#RETURNS FULL REMOTE PATH OF THE REPO
function getRemoteURL {
  repo=$(getRepoPath)
  if [ -n "$WERCKER_GIT_PUSH_GH_OAUTH" ]; then
    echo "https://$WERCKER_GIT_PUSH_GH_OAUTH@github.com/$repo"
  elif [ -n "$WERCKER_GIT_PUSH_HOST" ]; then
    git_user=$(getGitSSHUser)
    echo "$git_user@$WERCKER_GIT_PUSH_HOST:$repo"
  else
    echo ""
  fi
}

#RETURNS GIT SSH USER
function getGitSSHUser {
  if [ -n "$WERCKER_GIT_PUSH_USER" ]; then
    echo "$WERCKER_GIT_PUSH_USER"
  else
    echo "git"
  fi
}

#RETURNS BRANCH WE WANT TO PUSH TO
function getBranch {
  if [ -n "$WERCKER_GIT_PUSH_GH_PAGES" ]; then
    if [[ $(getRepoPath) =~ $WERCKER_GIT_OWNER\/$WERCKER_GIT_OWNER\.github\.(io|com)$ ]]; then
      echo "master"
    else
      echo "gh-pages"
    fi
  elif [ -n "$WERCKER_GIT_PUSH_BRANCH" ]; then
     echo "$WERCKER_GIT_PUSH_BRANCH"
  else
     echo "$WERCKER_GIT_BRANCH"
  fi
}

#RETURNS BASE DIR WE WANT TO PUSH FROM
function getBaseDir {

  # if directory provided, cd to it
  if [ -n "$WERCKER_GIT_PUSH_BASEDIR" ]; then
    echo $(pwd)/$WERCKER_GIT_PUSH_BASEDIR/
  else
    echo $(pwd)/
  fi

}

function initEmptyRepoAt {

  s_debug "Initializing empty repo at: " $1
  cd
  rm -rf $1
  git init -q $1
  cd $1
  s_debug "Done initializing empty repo at: " $1

}

function cloneRepo {
  s_debug "Cloning repo from: " $1 " to: " $2
  result=$(git clone $1 $2 -q 2>&1)
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "failed to clone repo"
  fi
}

function checkBranchExistence {
  cd $1
  git ls-remote -q --exit-code . origin/$2 > /dev/null
}

function checkoutBranch {
  cd $1
  result=$(git checkout $2 -q 2>&1)
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "failed to checkout existing branch $2"
  fi
}

function getTagWithPython {
  result=$(cat $1 | python -c 'import sys, json; print json.load(sys.stdin)["version"]' 2>&1);
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "Could not load version from $1"
  else
    echo "$result"
  fi
}

function getTagWithNode {
  result=$(node -p "require(\"$1\").version" 2>&1)
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "Could not load version from $1"
  else
    echo "$result"
  fi
}

function getTagFromJSON {
  if [ -f $1$2 ]; then
    if [ -n "`which node`" ]; then
      getTagWithNode $1$2
    else
      if [ -n "`which python`" ]; then
        getTagWithPython $1$2
      else
        echo "$3"
      fi
    fi
  else
    echo "$3"
  fi
}

function getTag {
  if [ -n "$1" ]; then
    case $1 in
      "bower") getTagFromJSON $2 "bower.json" $1 ;;
      "node") getTagFromJSON $2 "package.json" $1 ;;
      *) echo $1;;
    esac
  fi
}

function createCNAME {
  if [ -n "$WERCKER_GIT_PUSH_GH_PAGES_DOMAIN" ]; then
    echo $WERCKER_GIT_PUSH_GH_PAGES_DOMAIN > "$1/CNAME"
    s_info "Will create CNAME file: $1/CNAME"
  fi
}

function pushBranch {
  result="$(git push -q -f $1 $2:$3 2>&1)"
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "failed pushing to $3 on $1"
  else
    s_success "pushed to $3 on $1"
  fi
}

function pushTag {
  git tag -a $2 -m "Tagged by $WERCKER_STARTED_BY" -f > /dev/null
  result="$(git push --tags $1 2>&1)"
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "failed pushing to tag $1 with $2"
  else
    s_success "tagged $1 with $2"
  fi
}

function deleteTag {
  git tag -d $2 > /dev/null
  result="$(git push $1 --delete refs/tags/$2 2>&1)"
  if [[ $? -ne 0 ]]; then
    s_warning "$result"
    s_fail "failed delete $2 from $1"
  fi
}
