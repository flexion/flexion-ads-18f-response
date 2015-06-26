'use strict'

angular.module 'gsfFdaApp'
.controller 'MainCtrl', ($scope, $http) ->
  $scope.adverseReactions = []

  $scope.xAxisTickFormatFunction = ->
     (d) ->
        dateString = d.replace(/(\d{4})(\d{2})/g, '$2/01/$1')
        d3.time.format('%Y-%m')(new Date(dateString))

  $scope.xFunction = ->
    (d) ->
      d[0]

  format = d3.format(',.0f')
  $scope.valueFormatFunction = ->
    (d) ->
      format(d)

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
        groupedByDateData = _.groupBy(adverseReactions.results, (result) ->
          result.time.substring(0,6)
        )

        aggregateByDate = _.map(groupedByDateData, (result, time) ->
          {
            time: time
            count: _.reduce(result, ((m, x) ->
              m + x.count
            ), 0)
          }
        )
        console.log aggregateByDate
        data = [{key:"Serious Reactions", values: [] }]
        for result in aggregateByDate
          valuesArray = []
          valuesArray.push result.time
          valuesArray.push result.count
          data[0].values.push valuesArray

        $scope.adverseReactions = data

