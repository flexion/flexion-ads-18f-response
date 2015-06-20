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
        console.log(adverseReactions);
        $scope.adverseReactions = adverseReactions.results


