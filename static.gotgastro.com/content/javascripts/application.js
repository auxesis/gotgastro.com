window.addEvent('domready', function() {

	if (GBrowserIsCompatible()) {
		map = new GMap2($("map"));
		map.addControl(new GLargeMapControl());
		map.setCenter(new GLatLng(-33.86336, 151.207151), 10);
	}

	/* load up all the notices */
	setupMarkers(notices);
	$('status').fade('out');


});

function setupMarkers() {

	penalty_icon = new GIcon(G_DEFAULT_ICON);
	prosecution_icon = new GIcon(G_DEFAULT_ICON, "http://maps.google.com/mapfiles/ms/micons/purple-dot.png");
	prosecution_icon.iconSize = new GSize(32, 32);

	markers = []

	//console.time('markers')
	notices.each(function(notice) {
		notice = new Hash(notice);
		var lat = notice.get('latitude');
		var lng = notice.get('longitude');
		var type = 'penalty'; //notice.get('type').toLowerCase();

		content = new Element('div', { id: 'info-' + notice.get('id'), 'class': 'notice marker' });
		title	= new Element('h4', { html: notice.get('trade_name') });
		pdate	= new Element('p', { html: notice.get('date_served') });
		address	= new Element('p', { html: notice.get('address') });
		offence	= new Element('p', { html: notice.get('notice') + ' ', 'class': type + '-description' });
		link    = new Element('a', { href: notice.get('details_link'), html: '(link)', target: '_blank' });

		content.grab(title).grab(pdate).grab(address).grab(offence.grab(link));

		notice_icon = type == 'prosecution' ? prosecution_icon : penalty_icon;

		var point = new GLatLng(lat, lng);
		var marker = new GMarker(point, { icon: notice_icon });
		marker.bindInfoWindowHtml(content, { maxWidth: 450 });
		//marker.months_ago = notice.get('months_ago').toInt();

		markers.push(marker);

	});

	mc = new MarkerClusterer(map, markers, {gridSize: 45, maxZoom: 13});

	//console.timeEnd('markers')

}
