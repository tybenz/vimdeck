#Exemplar

This is my jekyll site template. Used for blog and project pages.

#Getting Started

First, make sure you have the `jekyll` and `sass` gems installed. In your terminal run:

    gem install jekyll
    gem install sass

You can optionally install the *bourbon* gem in order to update the Bourbon folder:

    gem install bourbon

Start running Jekyll (defaults to port 4000) and watching Sass:

    rake // 'rake watch' also works

Before deploying your site, stop `rake watch` and run `rake generate` to generate a production-ready site (no Scss comments).

## Updating Bourbon

In order to update the Bourbon folder:

    cd _sass/
    bourbon update
