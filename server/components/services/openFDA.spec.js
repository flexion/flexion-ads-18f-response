'use strict';

var should = require('should');
var app = require('../../app');
var request = require('supertest');
var openFDA = require('openFDA');

describe('openFDA.getPath', function() {

  it('should respond with a properly formatted query string', function(done) {
    var result = openFDA.getPath();
    result.should.be.instanceof(String);
  });
});
//TODO finish specs
//describe('openFDA.getJSON', function() {
//
//  it('should respond with a JSON payload', function(done) {
//    var result = openFDA.getJSON();
//    result.should.be.instanceof(String);
//  });
//});
