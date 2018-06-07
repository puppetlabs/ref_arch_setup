# How To Contribute To ref_arch_setup

## Getting Started

* Create a [Jira](http://tickets.puppetlabs.com) account.
* Make sure you have a [GitHub](https://github.com) account.
* Submit a ticket for your issue, assuming one does not already exist.
  * Clearly describe the issue including steps to reproduce when it is a bug.
  * File a ticket in the [SLV project](https://tickets.puppetlabs.com/projects/SLV/)
* Clone the [ref_arch_setup](https://github.com/puppetlabs/ref_arch_setup) repository on GitHub.

## Making Changes

* Create a topic branch from your local copy of the repository. 
  * Please title the branch after the beaker ticket you intend to address, ie `SLV-111`.
* Make commits of logical units.
* Check for unnecessary whitespace with `git diff --check` before committing.
* Make sure your commit messages are in the proper format.

````
    (SLV-111) Make the example in CONTRIBUTING imperative and concrete

    Without this patch applied the example commit message in the CONTRIBUTING
    document is not a concrete example.  This is a problem because the
    contributor is left to imagine what the commit message should look like
    based on a description rather than an example.  This patch fixes the
    problem by making the example concrete and imperative.

    The first line is a real life imperative statement with a ticket number
    from our issue tracker.  The body describes the behavior without the patch,
    why this is a problem, and how the patch fixes the problem when applied.
````

* During the time that you are working on your patch the master branch may have changed - you'll want to [rebase](http://git-scm.com/book/en/Git-Branching-Rebasing) on top of the master branch before you submit your PR.  
A successful rebase ensures that your PR will cleanly merge.

### Testing

* Submitted PR's will be tested in a series of spec and acceptance level tests - the results of these tests will be evaluated by an SLV team member, as test results are currently not accessible by the public. Testing failures that require code changes will be communicated in the PR discussion.
* Make sure you have added [RSpec](http://rspec.info/) tests that exercise your new code.

### Documentation

* Add an entry in the [CHANGELOG.md](CHANGELOG.md). Refer to the CHANGELOG itself for message style/form details.
* Make sure that you have added documentation using [Yard](http://yardoc.org/) as necessary for any new code introduced.
* More user friendly documentation will be required for PRs unless exempted. Documentation lives in the [docs/ folder](docs).

## Making Trivial Changes

### Maintenance

For changes of a trivial nature, it is not always necessary to create a new ticket in Jira. In this case, it is appropriate to start the first line of a commit with `(MAINT)` instead of a ticket/issue number. 

````
    (MAINT) Fix whitespace 

    - remove additional spaces that appear at EOL
````
### Version Bump For Gem Release

To prepare for a new gem release of the `version.rb` file is updated with the upcoming gem version number.  This is submitted with `(GEM)` instead of a ticket/issue number.

````
     (GEM) Update version for ref_arch_setup 1.11.1
````
### History File Update

To prepare for a new gem release (after the version has been bumped) the `HISTORY.md` file is updated with the latest GitHub log.  This is submitted with `(HISTORY)` instead of a ticket/issue number.

````
    (HISTORY) Update history for ref_arch_setup 1.11.1
````
## Submitting Changes

* Push your changes to a topic branch of the repository.
* Submit a pull request to [ref_arch_setup](https://github.com/puppetlabs/ref_arch_setup)
* Update your ticket
  * Update your [Jira](https://tickets.puppetlabs.com) ticket to mark that you have submitted code and are ready for it to be considered for merge (Status: Ready for Merge).
    * Include a link to the pull request in the ticket.
* PRs are reviewed as time permits.  

# Additional Resources

* [Puppet community guidelines](https://docs.puppet.com/community/community_guidelines.html)
* [Bug tracker (Jira)](http://tickets.puppetlabs.com)
* [SLV Jira Project](https://tickets.puppetlabs.com/projects/SLV/)
* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](http://help.github.com/send-pull-requests/)

