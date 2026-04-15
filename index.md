### Introduction

Redsun is a Redmine plugin that replaces the existing search with a fast Apache Solr powered engine.

#### Features

Redsun will respect any viewing restrictions on records to make sure people will only see results they are supposed to see.

#### select2 Support

Install the [Redmica UI Plugin](https://github.com/redmica/redmica_ui_extension) for UI improvements.

#### Models

The following models are being indexed. We plan to add more models with future releases.

* Issues
* Journals (=Comments)
* Projects
* WikiPages
* Attachments
* News

#### Facets

* Project
* Author
* Assigned To
* Status
* Tracker
* Priority
* Created on
* Updated on
* Issue Category
* File Type

### Localization

Currently, only German and English are being supported.

#### Supported Redmine Versions

#### Redmine 6+

Use Redsun >= 2.8.0 and Solr 9.8+

#### Redmine 3.x 

Please use Redsun >= 1.0.4 if you are using Redmine 3.x

#### Redmine 2.x

We have successfully used Redsun 1.0.3 with Redmine 2.3-2.6.


#### Basic Installation

We recommend to test this plugin locally. There is a solrconfig.xml and schema.xml for Solr in the config folder of the plugin. Please use these files for your Solr server to get running.
Also: For the spellchecker feature to work properly the Solr index has to be optimized. You can do this on the Solr admin interface or on the Rails console with ```Sunspot.optimize```.

* cd into your redmine root folder
* cd plugins
* git clone git@github.com:dkd/redsun.git redmine_redsun
* run bundle install
* rails generate sunspot_rails:install
* bundle exec rake sunspot:solr:start
* bundle exec rake sunspot:solr:reindex
* restart Redmine
* enable Redsun within the plugin's settings section

#### Downloads

* [ZIP-Archive]({{ site.zip_url }})
* [TAR-Archive]({{ site.tar_url }})

#### Looking for your Red Sun Redmine Search?

Hosted Solr does not require lengthy and complicated configuration. Simply register for an account and create an Apache Solr index. You can then benefit from the advantages of Apache Solr with a few clicks. It offers support for Red Sun via its sunspot integration.

[Hosted Solr](https://www.hosted-solr.com/?locale=en)

