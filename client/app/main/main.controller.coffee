'use strict'

angular.module 'gsfFdaApp'
.controller 'MainCtrl', ($scope, $http) ->
  $scope.adverseReactions = []

  $scope.reset = ->
    $scope.adverseReactions = []
    $scope.brandname = ''

  $scope.search = (brandname) ->
    #todo move to a filter service
    if brandname
      query = search:
        fields: [
          {
            field: 'brand_name'
            terms: [ { term: brandname } ]
          },
          {
            field: 'serious'
            terms: [ { term: '1' } ]
            isAnd: true
          },
          {
            field: 'receivedate'
            terms: [ { term: '[20140101+TO+20150101]' } ]
            isAnd: true
          }
        ]
        count: field: 'receivedate'

      $http.get("/api/epi-search/?search=#{JSON.stringify query}").success (adverseReactions) ->
        $scope.adverseReactions = adverseReactions.results

  query = search:
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
    count:
      field:"patient.drug.medicinalproduct"


  $http.get("/api/epi-search/?search=#{JSON.stringify query}").success (result) ->
    engine = new Bloodhound
      datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace(d.term)
      queryTokenizer: (q) -> Bloodhound.tokenizers.whitespace
      #local: result.results
      local: [
        { term: 'one' },
        { term: 'two' },
        { term: 'three' },
        { term: 'four' },
        { term: 'five' },
        { term: 'six' },
        { term: 'seven' },
        { term: 'eight' },
        { term: 'nine' },
        { term: 'ten' }
      ]


    engine.initialize()

    $scope.pharmaNames =
      displayKey: 'term',
      source: engine.ttAdapter()
    $scope.pharmaOptions =
      highlight: true


