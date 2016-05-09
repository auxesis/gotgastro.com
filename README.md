**DEPRECATED: Check out [the reboot](https://github.com/auxesis/gastro).**


Gastro
======

Gastro is a mashup of the NSW Food Authority's name-and-shame lists for
restaurants in NSW and Google maps. Simply put, it lets you see where
restaurants who violate the health codes are on a map.

Gastro is made up of two parts - the geocoder, and the website generator.

Data lives in `data/nswfa-penalty_notices.sqlite`.

To build the site:

    # Fetch the latest penalty notices from ScraperWiki
    rake fetch
    # Geocode the penalty notices
    rake geocode
    # Build the website
    rake build

The website is generated off the geocoded data. The generation is automated,
but there are several steps to publish the new data.

The `build` task uses `nanoc` to generate a site in `output/`. This can be
rsync'd to any web servable directory. There is a deploy task which can be
flavored to taste by editing the Rakefile, then run with:

    rake deploy

Testing
-------

Run the tests with:

    cucumber features/


optimising logo image
---------------------

  convert -colors 7 gastro.png gastro.gif

