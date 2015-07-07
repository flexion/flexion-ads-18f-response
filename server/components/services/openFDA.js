'use strict';

var http = require("http");
var https = require("https");

/**
 * getJSON:  REST get request returning JSON object(s)
 * @param options: http options object
 * @param callback: callback to pass the results JSON object(s) back
 */
exports.getJSON = function(options, onResult)
{
  var prot = options.port === 443 ? https : http;
  var req = prot.request(options, function(res)
  {
    var output = '';
    //console.log(options.host + ':' + res.statusCode);
    res.setEncoding('utf8');

    res.on('data', function (chunk) {
      output += chunk;
    });

    res.on('end', function() {
      var obj = JSON.parse(output);

      onResult(res.statusCode, obj);
    });
  });

  req.on('error', function(err) {
    //res.send('error: ' + err.message);
    console.error('error: ' + err.message);
  });

  req.end();
};

exports.getPath = function(query)
{
  //see https://open.fda.gov/api/reference/#query-syntax
 var field, j, len1, queryString, ref, ref1, term;
  //TODO production app will read this from environment variable
  queryString = '/drug/event.json?api_key=1tng2lKHWL3Upt0LfvdyEsl82L5ROFYBgbfUAJHL&search=';
  ref = query.search.fields;
  for (var i = 0, len = ref.length; i < len; i++) {
    field = ref[i];
    if (field.isAnd) {
      queryString += '+AND+';
    }
    queryString += field.field;
    queryString += ':';
    ref1 = field.terms;
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      term = ref1[j];
      term.term = term.term.replace(/\s+/g, '+');
      if (term.isExact) {
        queryString += '"';
        queryString += term.term;
        queryString += '"';
      } else {
        queryString += term.term;
      }
      if (j+1 !== len1) {
        queryString += "+"
      }
    }

    //if (field.date) {//TODO make dates enterable by client at some point in future
    //  queryString += '+AND+receivedate:[';
    //  queryString += field.date.from;
    //  queryString += '+TO+';
    //  queryString += field.date.to;
    //  queryString += ']'
    //}

  }

  if (query.search.count) {
    queryString += "&count=";
    queryString += query.search.count.field;
    if (query.search.count.isExact) {
      queryString += ".exact"
    }
  }
  return queryString;
};
