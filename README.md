# Git Branch Deploy

A [wercker](http://wercker.com/) step to deploy to a certain git branch in a repo. Supports also [Github Pages](http://pages.github.com/).

# IMPORTANT SECURITY NOTICE:

If your wercker app is public and you use the setting `gh_token`, it could be that your Auth token has been compromised.

Please change your token as quick as possible [here](https://github.com/settings/applications#personal-access-tokens)
and use the `gh_oauth` option instead of `gh_token`.

Sorry for the inconvience. I reworked the complete wercker step, added unit and integration tests and more importantly there is now a function, which replaces oauth tokens in logs with `oauth-token`.

Builds containing `gh_token` will fail.

## Options

You either have to define a `gh_oauth` token if you deploy to github or a `host` if you want to deploy via SSH.
(Please use wercker steps `leipert/add-ssh-key-gh-bb` and `add-to-known_hosts` to setup your SSH token for github and bitbucket)

- `gh_oauth` *optional* Github API access token, if you want to deploy to github. ([documentation](https://github.com/blog/1509-personal-api-tokens)). **don't share this on a public repo, use an environment variable!**
- `host` *optional* Set this to a host like "example.org". Defaults to your build host or github if `gh_oauth` is used.
- `user` *optional* Set this to the ssh user of your git instance. Defaults to git.
- `repo` *optional* Set this to a repo like "username/repo". Defaults to your build repo.
- `branch` *optional* If set this branch will be used as deploy goal. Defaults to build master
- `basedir` *optional* Set this if your build step outputs to a folder
- `destdir` *optional* Specifies the directory in the remote repo to copy the files to
- `clean_removed_files` *optional* Cleans removed files if set. Default will keep old files if they are not overwritten.
- `discard_history` **DANGER** *optional* Discards history of that branch. Use with care as it could destroy your whole programming history.
- `gh_pages` *optional* Set this to true if you want to deploy to [Github Pages](http://pages.github.com/). The Branch will be set accordingly.
- `gh_pages_domain` *optional* Custom domain ([documentation](https://help.github.com/articles/setting-up-a-custom-domain-with-pages))
- `tag` *optional* Adds a tag to the pushed commit. Valid options are bower, node or any string.
- `tag_overwrite` *optional* If set, tags will be overwritten
- `ci_trigger` *optional* If set to `true`, commit message won't start with `[ci skip]`. Default is `false`. See [Skipping builds](http://blog.wercker.com/2014/05/01/Skipping-builds-on-wercker.html)

## Example

For Github Pages:
```
deploy:
  steps:
    - git-push:
         gh_oauth: $GH_TOKEN
         gh_pages: true
         gh_pages_domain: example.org
         basedir: build
```
Deploy with SSH
```
deploy:
  steps:
    # Add SSH-Key to
    - leipert/add-ssh-key-gh-bb:
        keyname: DEPLOY_SSH
    # Add bitbucket to known hosts, so they won't ask us whether we trust bitbucket
    - add-to-known_hosts:
        hostname: bitbucket.org
        fingerprint: 97:8c:1b:f2:6f:14:6b:5c:3b:ec:aa:46:46:74:7c:40
    - git-push:
         host: bitbucket.org
         repo: example/exampleRepo
         branch: example
         basedir: build
```
