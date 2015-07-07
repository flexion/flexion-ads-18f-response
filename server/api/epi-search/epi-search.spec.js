'use strict';

var should = require('should');
var app = require('../../app');
var request = require('supertest');

describe('GET /api/epi-search', function() {

  it('should respond with JSON array', function(done) {
    request(app)
      .get('/api/epi-search/?search=eyJzZWFyY2giOnsiZmllbGRzIjpbeyJmaWVsZCI6ImJyYW5kX25hbWUiLCJ0ZXJtcyI6W3sidGVybSI6Imx5cmljYSJ9XX0seyJmaWVsZCI6InNlcmlvdXMiLCJ0ZXJtcyI6W3sidGVybSI6IjEifV0sImlzQW5kIjp0cnVlfSx7ImZpZWxkIjoicmVjZWl2ZWRhdGUiLCJ0ZXJtcyI6W3sidGVybSI6IlsyMDE0MDEwMStUTysyMDE1MDEwMV0ifV0sImlzQW5kIjp0cnVlfV0sImNvdW50Ijp7ImZpZWxkIjoicmVjZWl2ZWRhdGUifX19')
      .expect(200)
      .expect('Content-Type', /json/)
      .end(function(err, res) {
        if (err) return done(err);
        res.body.results.should.be.instanceof(Array);
        done();
      });
  });
});
