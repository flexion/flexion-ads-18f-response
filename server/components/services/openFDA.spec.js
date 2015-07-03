'use strict';

var should = require('should');
var app = require('../../app');
var request = require('supertest');
var openFDA = require('./openFDA');

describe('openFDA.getPath', function() {
  var search = { search : {
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
    }};


  var request2 = { search: {
      fields: [
        {
          field:"patient.drug.openfda.pharm_class_epc",
          terms:[
            {term:"nonsteroidal anti-inflammatory drug", isExact: "true"}
          ]
        }
      ],
      count: {field:"patient.reaction.reactionmeddrapt", isExact: true}
    }
  };

  //https://api.fda.gov/drug/event.json?search=brand_name:lyrica+AND+receivedate:[20140101+TO+20150101]&count=receivedate

  it('should respond with a properly formatted query string', function(done) {
    var expectedResult = '/drug/event.json?search=patient.drug.medicinalproduct:nonsteroidal+anti-inflammatory+drug';
    var result = openFDA.getPath(search);
    result.should.be.instanceof(String);
    result.should.equal(expectedResult);
    done();
  });

  it('should recognize an exact term and put quotes around it', function(done) {
    var expectedResult = '/drug/event.json?search=patient.drug.openfda.pharm_class_epc:"nonsteroidal+anti-inflammatory+drug"&count=patient.reaction.reactionmeddrapt.exact';
    var result = openFDA.getPath(request2);
    result.should.be.instanceof(String);
    result.should.equal(expectedResult);
    done();
  });

  it('should be able to add an exact count', function(done) {
    var expectedResult = '/drug/event.json?search=patient.drug.openfda.pharm_class_epc:"nonsteroidal+anti-inflammatory+drug"&count=patient.reaction.reactionmeddrapt.exact';
    var result = openFDA.getPath(request2);
    result.should.be.instanceof(String);
    result.should.equal(expectedResult);
    done();
  });

  it('should be able to parse a date', function(done) {
    var request3 =
    {
      search: {
        fields: [
          {
            field:"brand_name",
            terms:[
              {term: "lyrica"},
            ]
          },
          {
            field: "receivedate",
            terms: [
              {term: "[20140101+TO+20150101]"}
            ],
            isAnd: true
          }
        ],
        count: {field:"receivedate"}
      }
    };

    var expectedResult = '/drug/event.json?search=brand_name:lyrica+AND+receivedate:[20140101+TO+20150101]&count=receivedate';
    var result = openFDA.getPath(request3);
    result.should.be.instanceof(String);
    result.should.equal(expectedResult);
    done();
  });

  it('should be able to AND fields together', function(done) {
    var request4 = {
      search: {
        fields: [
          {
            field:"brand_name",
            terms:[
              {term: "lyrica"},
            ]
          },
          {
            field: "serious",
            terms: [
              {term: "1"}
            ],
            isAnd: true
          },
          {
            field: "receivedate",
            terms: [
              {term: "[20140101+TO+20150101]"}
            ],
            isAnd: true
          }
        ],
        count: {field:"receivedate"}
      }
    };
    var expectedResult = '/drug/event.json?search=brand_name:lyrica+AND+serious:1+AND+receivedate:[20140101+TO+20150101]&count=receivedate';
    var result = openFDA.getPath(request4);
    result.should.be.instanceof(String);
    result.should.equal(expectedResult);
    done();

  });
  it('should do a pharma name search', function(done) {
    //drug/event.json?search=patient.drug.openfda.pharm_class_epc:anti-epileptic+agent+AND+receivedate:%5B20140101+TO+20150101%5D&count=patient.drug.medicinalproduct

    var request5 = {
      search: {
        fields: [
          {
            field:"patient.drug.openfda.pharm_class_epc",
            terms:[
              {term: "anti-epileptic"},
              {term: "agent"}
            ]
          },
          {
            field: "receivedate",
            terms: [
              {term: "[20140101+TO+20150101]"}
            ],
            isAnd: true
          }
        ],
        count: {field:"patient.drug.medicinalproduct"}
      }
    };
    var expectedResult = '/drug/event.json?search=patient.drug.openfda.pharm_class_epc:anti-epileptic+agent+AND+receivedate:[20140101+TO+20150101]&count=patient.drug.medicinalproduct';
    var result = openFDA.getPath(request5);
    result.should.be.instanceof(String);
    result.should.equal(expectedResult);
    done();

  });




});
