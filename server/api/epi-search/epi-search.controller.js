'use strict';

var _ = require('lodash');
var openFDA = require('../../components/services/openFDA');

exports.index = function(req, res) {
  var query = {};
  if (req.query.search) {
    query = JSON.parse(req.query.search);
    console.log(query);
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


