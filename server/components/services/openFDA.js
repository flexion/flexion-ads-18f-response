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
  var prot = options.port == 443 ? https : http;
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
    res.send('error: ' + err.message);
  });

  req.end();
};

exports.getPath = function(req)
{
  //see https://open.fda.gov/api/reference/#query-syntax

  var query =
    {
      search: {
        fields: [
          {
            field:"patient.drug.openfda.pharm_class_epc",
            terms:[
              {term:"nonsteroidal anti-inflammatory drug", isExact: "true"}
            ]
          }
        ]
      },
      count: {field:"patient.reaction.reactionmeddrapt", isExact: true}

    };
  var query2 =
    {
      search: {
        fields: [
          {
            field:"patient.drug.medicinalproduct",
            terms:[
              {term:"nonsteroidal"},
              {term:"anti-inflammatory"},
              {term: "drug"}
            ]
          }
        ]
      }
    };

  var field, i, j, len, len1, query, queryString, ref, ref1, term;
  queryString = '/drug/event.json?search=';

  ref = query.search.fields;
  for (i = 0, len = ref.length; i < len; i++) {
    field = ref[i];
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
    }
  }

  if (query.count) {
    queryString += "&count=";
    queryString += query.count.field;
    if (query.count.isExact) {
      queryString += ".exact"
    }
  }
  return queryString;
  //return '/drug/event.json?search=patient.drug.openfda.pharm_class_epc:"nonsteroidal+anti-inflammatory+drug"&count=patient.reaction.reactionmeddrapt.exact';
};
