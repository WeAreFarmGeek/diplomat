# Contributing to Diplomat

## Submit a Pull Request

Diplomat uses Github's Pull request system to accept contributions. Please
[make yourself familiar
with github's pull request system](https://help.github.com/articles/using-pull-requests/) before continuing with this guide.

## Acceptance requirements

### Write Unit Tests

Only unit tested code will be accepted into the codebase. Consul in some cases
is used as the basis for very complex interconnected systems, and so it is
important that new code is verifiably safe.

### Write documentation for new functionality

It's important for the new functionality to be discoverable for Consul's users,
therefore it is important for new functionality in pull requests to be properly
documented. Add an entry to the README.md document!

### When in doubt, don't change the API - try to keep things as backwards compatible as possible

The API for consul should be changed very conservatively - we want it to be
easy for users to continue to upgrade the gem without having to worry about
modifying their implementation of consul. That said, if there is a
compelling reason to make the change, then make the case!

### Feel free to suggest whether the change should result in a major or minor change, but don't change it in the source.

Often multiple PRs will be merged at a time, so it's annoying if the version
has been changed in each PR.

### Add your changes to the Changelog

Add a line or two describing a summary of what you've done in the "unreleased"
section at the top of the changelog, with the date in YYYY-MM-DD format. [Read
more here.](http://keepachangelog.com/)
