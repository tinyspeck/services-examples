'use strict';

/*
 Call this script from a post-commit.[bat|sh]
 
 Unix:
 node /path/topost-commit.js $1 $2 $3 $4
 
 Windows:
 node C:\path\to\post-commit.js %1 %2 %3 %4
 
 Need node 0.12+ or iojs 1.0+
*/

try {
	var token = 'xxxxx';  // replace with yours
	var domain = 'xxxxx.slack.com'; // replace with yours
	var rev = parseInt(process.argv[3], 10);
	var path = process.argv[2];

	var child = require('child_process');

	var log = child.execSync('svnlook log -r ' + rev + ' ' + path, {encoding: 'utf8'}).replace(/[\r\n]/gm, '');
	var author = child.execSync('svnlook author -r ' + rev + ' ' + path, {encoding: 'utf8'}).replace(/[\r\n]/gm, '');

	var payload = JSON.stringify({
		revision: rev,
		url: 'https://server/!/#repo/commit/r' + rev, // change for yours
		author: author,
		log: log,
		color: 'good'
	});

	console.log(payload);

	var http = require('https');

	var req = http.request({
		hostname: domain,
		path: '/services/hooks/subversion?token=' + token,
		method: 'POST',
		headers: {
			'Content-Type': 'application/x-www-form-urlencoded',
			accept: 'application/json'
		}
	}, function (res, data) {
		res.setEncoding('utf8');
		console.log(res.statusCode);
		console.log(res.headers);
		res.on('data', function (chunk) {
			console.log(chunk);
		});
		res.on('end', function () {
			//console.log('end');
		});
	});

	req.write('payload=' + payload);
	req.end();
} catch (ex) {
	console.log(ex.message);
}