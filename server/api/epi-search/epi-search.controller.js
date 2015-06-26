'use strict';

var _ = require('lodash');
var openFDA = require('../../components/services/openFDA');

exports.index = function(req, res) {
  var query = {};
  if (req.query && req.query.search) {
    var payload = new Buffer(req.query.search, 'base64').toString();
    query = JSON.parse(payload);
  }
  var openFDAPath = openFDA.getPath(query);

  //TODO move this to config
  var options = {
    host: 'api.fda.gov',
    port: 443,
    path: openFDAPath,
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  openFDA.getJSON(options,
    function(statusCode, result)
    {
      res.statusCode = statusCode;
      res.json(result); //res.send
    });
};


