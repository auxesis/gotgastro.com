
Gastro
======
Gastro is a mashup of the NSW Food Authority's name-and-shame lists for
restaurants in NSW and Google maps. Simply put, it lets you see where
restaurants who violate the health codes are on a map.

Gastro is made up of two parts - the scraper, and the website generator.

The scraper (`scraper.rb`) handles crawling the NSW FA site, extracting
meaningful data from the scraped HTML, and geocoding addresses.

Crawled data lives in `cache/`, extracted data lives in `extracted/`, and
geocoded data lives in `geocoded/`.

    $ rake shebang

The website is generated off the geocoded data. The generation is automated,
but there are several steps to publish the new data.

After running the `rake shebang` task above, change into the
`static.gotgastro.com/` directory.

So the geocoded data can be more easily used, it needs to be put into a small
database. To create a database and insert the notices, run:

    $ rake create_database
    $ rake create_penalties
    $ rake create_prosecutions

This will create a small sqlite3 database. Now the data is in a database,
the website can be built:

    $ rake build

`nanoc` will generate a site in `output/`. This can be rsync'd to any web
servable directory. There is a deploy task which can be flavored to taste
by editing the Rakefile, then run with:

    $ rake deploy


Testing
-------

There are some basic unit tests in `spec/`. You can run them with:

    $ rake spec


optimising logo image
---------------------

  convert -colors 7 gastro.png gastro.gif

