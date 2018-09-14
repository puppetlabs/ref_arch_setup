# How To Contribute To RefArchSetup

## Getting Started

* Make sure you have a [GitHub](https://github.com) account.
* Clone the [ref_arch_setup](https://github.com/puppetlabs/ref_arch_setup) repository on GitHub.
* RefArchSetup uses [gem_of](https://github.com/puppetlabs/gem_of) for some development gem dependencies and rake tasks.
   Initialize and update the `gem_of` submodule:
  ```
  git submodule init
  git submodule update
  ```
* Install the required gems:
  ```
  bundle install 
  ```

## Filing Tickets With Jira

* Create a [Jira](http://tickets.puppetlabs.com) account if you don't already have one.
* Submit a ticket for your issue, assuming one does not already exist:
  * File a ticket in the [SLV project](https://tickets.puppetlabs.com/projects/SLV/).
  * Clearly describe the issue including steps to reproduce when it is a bug.
  
## Making Changes

### GitHub
* Create a topic branch from your local copy of the repository. 
  * Please title the branch after the ticket you intend to address, ie `SLV-111`.
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

* Make sure that you have added documentation using [Yard](http://yardoc.org/) as necessary for any new code introduced.
* More user friendly documentation will be required for PRs unless exempted. Documentation lives in the [docs/ folder](docs).

## Making Trivial Changes

### Maintenance

For changes of a trivial nature, it is not always necessary to create a new ticket in Jira. In this case, it is appropriate to start the first line of a commit with `(MAINT)` instead of a ticket/issue number. 

````
    (MAINT) Fix whitespace 

    - remove additional spaces that appear at EOL
````

## Submitting Changes

* Push your changes to a topic branch of the repository.
* Submit a pull request to [ref_arch_setup](https://github.com/puppetlabs/ref_arch_setup)
* Update your [Jira](https://tickets.puppetlabs.com) ticket
  * Update the status to "Ready for Merge".
  * Include a link to the pull request in the ticket.

## Building And Publishing The Gem

### RubyGems.org
* Create a [rubygems.org](rubygems.org) account if you don't already have one.
* Use your email and password when pushing the gem. The credentials will be stored in ~/.gem/credentials.

### Bundler Release Tasks

RefArchSetup includes the [Bundler release rake tasks](https://bundler.io/v1.12/guides/creating_gem.html#releasing-the-gem) via [gem_of](https://github.com/puppetlabs/gem_of) which simplifies the build and release process.
The following tasks are included:
````
rake gem:build                  # Build ref_arch_setup-0.0.1.gem into the pkg directory
rake gem:clean                  # Remove any temporary products
rake gem:clobber                # Remove any generated files
rake gem:install                # Build and install ref_arch_setup-0.0.1.gem into system gems
rake gem:install:local          # Build and install ref_arch_setup-0.0.1.gem into system gems without network access
rake gem:release[remote]        # Create tag v0.0.1 and build and push ref_arch_setup-0.0.1.gem to rubygems.org
````

To publish the gem to RubyGems.org, use the `release` task:

````
    $ rake gem:release
````

This will create a new tag for the release, push it to GitHub, build the gem, and push it to RubyGems.org.

### Version Bump For Gem Release

* Update the `version.rb` file with the upcoming gem version number to prepare for the next gem release.  
* Commit the update with `(GEM)` instead of a ticket/issue number.

````
     (GEM) Update version for ref_arch_setup 1.11.1
````
* Submit a pull request for the version update to [ref_arch_setup](https://github.com/puppetlabs/ref_arch_setup)

# Additional Resources

* [Puppet community guidelines](https://docs.puppet.com/community/community_guidelines.html)
* [Bug tracker (Jira)](http://tickets.puppetlabs.com)
* [SLV Jira Project](https://tickets.puppetlabs.com/projects/SLV/)
* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](http://help.github.com/send-pull-requests/)

