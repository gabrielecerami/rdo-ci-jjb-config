IMPORTANT
========

at the time of writing (may 2014), the latest jjb version has a bug that prevents this configuration
to work:

https://bugs.launchpad.net/openstack-ci/+bug/1285515

fix is awaiting approval.


Directory Structure
===================

the most important directory in the tree is
**lib** which contains the library of definitions for the jobs.

Definitions are grouped by module category, so all parameters are in the same file,
builders are in the same file, and so on.

Projects are in the separated directory **projects** and are grouped by destination
server, so every jenkins server can have a different set of jobs.

The contents of the file **template-macros** that does not correspond to any 
jenkins job builder module are discussed after.

::

    └── lib
        ├── builders.yaml
        ├── defaults.yaml
        ├── parameters.yaml
        ├── projects/
        │   └── example.yaml
        ├── properties.yaml
        ├── publishers.yaml
        ├── scms.yaml
        ├── template-macros.yaml
        ├── templates.yaml
        ├── triggers.yaml
        └── wrappers.yaml

the directory **servers-conf** contain the ini file for jenkins server upload location 
and credentials

the directory **out-xml** is used to test configuration syntax and resulting
xml job files.

How to prepare configuration for use.
-----------------------------------

The directory structure cannot be used as is.

The basic idea is that the every different jenkins server should have its own set of jobs
but code to define the jobs must not be replicated.

Job creation in a server is driven by the "project" block. This means that every server
should have his own set of "project" blocks.

The entire library of definition instead should be available for all jobs on all the servers

The preferred method to obtain this scenario in the configuration is:
* create a project file on lib/projects directory
* create a directory in jobs/ with a name that refers to you destination server
* create symbolic links for all the library files in lib
* [ optional ] create symbolic links for all the *private* library files in a private lib directory
* create a symbolic link for the project file in lib/project/destserver


then apply all your command to this newly created directory.


Use the script new-project.sh to generate automatically these directories


Principal Parameters
====================

Rdo ci jjb config uses 9 principal parameters to define every khaleesi jobs.


framework
    the framework used in the jobs. It's khaleesi for all the jobs at the moment.
job options variants
    the name of a set of jenkins configuration variables.

These two parameters are used by jjb to manage all the components used to create a jekins job.

The following are generally no handled directly by jjb , sometimes are used to modify certain build parameters
but mainly are directly passed to the framework so the framework knows what to build.


installer
    the installer to use. [packstack, foreman, tripleo]
product
    the product to install [rdo, rhos]
productrelease
    the release of the product [icehouse, havana, 4.0 (for rhos)]
productreleaserepo
    the repo to get the product from [production, stage, poodle]
distro
    the distribution to install the product to [rhel, centos, fedora]
distrorelease
    the release of the distribution [19,20 (for fedora) 6.5 (for rhel and centos), 7.0 (for rhel)]
topology
    the topology to set for the resources [multinode, aio]
networking
    the networking to setup for building product
variant
    the name of a set of build parameters that don't fit in other principal parameters
testsuite
    the name of a set of configurations for the integration tests


the resulting project complete name for a job (and the name of the only jjb template) is:

::

    {framework}-{joboptionsvariant}_{installer}_{product}_{productrelease}_{productreleaserepo}-repo_{distribution}-{distrorelease}_{topology}_{networking}_{variant}-variant_{testsuite}-tests

principal parameters are separated by underscores, so they can be easily identified in the job name, and they may contain dashes
for further specifications. -repo and -tests are added to ease job name understanding.



Project name vs Display Name
----------------------------

the whole project name is cumbersome to read, and contains some informations that are not useful to have
so often printed. So the name that is usually shown in jenkins (display name) is formed by this subset of
principal parameters:

::

    {installer}_{product}_{productrelease}_{productreleaserepo}-repo_{distribution}-{distrorelease}_{topology}_{networking}_{variant}-variant_{testsuite}-tests



Block Structure and indirections
===============

To understand how the different files and block of definitions work together to form a job definition
let's start from the last piece that jjb evaluates: the projects.

The most difficult interaction to understand lies between projects file, template file, and template macros file.

Project file
------------

Descriptions and combinations are named blocks that contain referrable dictionaries (using pure yaml anchors)

Using this method is the only possible way of including parts of the definitions dinamically for code reusing, without
recurring to external tools that implement inclusion of yaml files (standard yaml does not implement inclusion)

Unfortunately this blocks must reside on the same yaml documents, because standard yaml allows the use of anchors
only within the same document


Descriptions
++++++++++++

This block contains definitions for the principal parameters that define a variant (joboptionsvariant and variant)

.. code:: yaml

 descriptions:
    name: descriptions

    gre_variant_description: &gre_variant_description
        variant-description: |
            This variant uses GRE tunnelling for networking

    myserver_variant1_job_description: &myserver_variant1_jov_description
        jov-description: |
            This parameters variant is used to manage jobs on my Jenkins server
            Ansi color and timestamp are applied
            Post build uses groovy script to alert production server.


variant-description and jov-description are two variables that will be used in the description of the jenkins job, alongside informations
on the build. They must be wrapped into a dictionary that will be subsequently merged into the combination dictionary using the 
yaml merge function "<<"


Important to know is that the name of the dictionary that contains the variable is not used, only the anchor name will be
referred in the merge.


Framework Combinations
++++++++++++++++++++++

This block contains the dictionaries that define the combination of framework and options variant.

.. code:: yaml

 framework-combinations:
    name: framework-combinations
    khaleesi-myserver-variant1: &khaleesi-myserver-variant1
        framework: khaleesi
        joboptionsvariant: myserver-variant1
        <<: *myserver-variant1_jov_description


as in the description block the  name of the dictionary that contains the variables is not used, only the anchor name will be
referred in the merge.


Job Combinations
++++++++++++

this block contains the dictionaries that define the combinations of principal parameters
that form the job, as is usually done in theproject block of every jjb configuration

.. code:: yaml

 job-combinations:
    name: job-combinations
    packstack-rdo-havana-multinode-neutron-gre-f20: &packstack-rdo-havana-multinode-neutron-gre-f20
        installer:
            - packstack
        product:
            - rdo
        productrelease:
            - havana
        topology:
            - multinode
        networking:
            - neutron
        distribution:
            - fedora
        distrorelease:
            - 20
        productreleaserepo:
            - production
            - local
        variant:
            - gre
        <<: *gre_variant_description
        testsuite:
            - server-basic-ops

as in the description block the  name of the dictionary that contains the variables is not used, only the anchor name will be
referred in the merge.

Projects
++++++++

Once defined, descriptions, framework with variant and combinations dictionaries are then merged together into a project
block to form the jobs

.. code:: yaml

 project:
    name khaleesi-packstack-rdo-havana-multinode-neutron-gre-f20
    <<: *khaleesi-myserver-variant1
    <<: *packstack-rdo-havana-multinode-neutron-gre-f20
    jobs:
        - '{framework}-{joboptionsvariant}_{installer}_{product}_{productrelease}_{productreleaserepo}-repo_{distribution}-{distrorelea#
            label: mylabel

All the project in rdo ci jjb configuration will use the same template, passing a parameter to indicate which node to use for the specified job.
The discrimination of module to use for a job will be handled by template file using parametrized macros.

Template File
--------

This is a one fit for all template that define jobs that use the naming convention described above, calling
parametrized macros from the template macros file.

Macros
++++++

This jjb configuration make heavy use of macros.

The idea followed was to use a single template for all the jobs. This allowed to avoid replication of code, using the same name
structure for all the jobs, and concentrating efforts in definitions of new jobs only in the place where
it is really necessary: assembling macro definitions for the job we want to create.

So, as this scheme shows, multiple jobs refer to the same template.

::

    Job creation diagram
                                                                                    /-> parameter P1
    project framework A variant A1 -\                       /-> template macro A-A1 --> parameter P1
    project framework B variant B1 ---> khaleesi template ----> template macro B-B1 -/
    project framework A variant A2 -/                       \-> template macro A-A2 --> parameter P3

The template will call a different macro based on the framework-joboptionsvariant principal parameters combinations
using the possibilty offered by jjb to parametrize the name of the macro.

.. code:: yaml

   properties:
        - "properties-{framework}-{joboptionsvariant}"
   parameters:
        - "parameters-{framework}-{joboptionsvariant}"

The template was created to be more general as possible. There should be no need to touch the template file at all during normal operations


Template macros file
--------------------

This file collates the job definition with the rest of the modules.

The function of macros in the file is to include all the necessary modules into the job.
Macros present in template file will be named after the framwork-jobsoptionvariant combination, with a suffix that specify
the category of macros that these macros will in turn include to form the job definition.

To implement a new variant for a framework, one has to create macros named like
<module>-{framework}-{variant}
and then add to this macro all the macros from other modules of the same type <module>
that constitute the job.

.. code:: yaml

  - parameter:
      name: parameters-khaleesi-myserver-variant1
      parameters:
          - parameter1
          - parameter2

.. code:: yaml

 - builder:
       name: builders-khaleesi-myserver-variant1
       builders:
           - khaleesi


Modules files
-------------

File for all the other modules like parameters, properties, and so on follow this best practice.

* module file should contain **only** macros, no loose direct definitions
* macros should not contain more that one definition
* if you want to add two (or more) than one definition to the same macro, create two (or more) macros
  with only one definition eac, then create a macro that contains these two (or more) macros
* macro use parameters for all the more variable variables
  for example in defining an scm, the variable "branch" should receive a parameter ::

  - scm
    name: some repo
    scm:
        url: http://some/url
        branch: {branch}


Tips for creating jobs
======================

The benefits of using jjb come when you are grouping similar job in a way that a single
modification affects the largest number of jobs possible.

If the jobs are ALL different from each other, then jjb acts as a mere translator from yaml
to jenkins, with the only benefint to use a text editor instead of web forms to 
define your job.

In this perspective to benefints from jjb one must think in job groups.

For every job on must ask to him/her self: what this job has in common with the 
others ?

Every job must have a class, if you need a job that is different from all the others 
youhave to create a class for it
