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
        data =  $scope.adverseReactions
        console.log(data[0])
        width = 780
        barHeight = 20
        x = d3.scale.linear().domain([
          0
          d3.max(data, (d) -> d.count)
        ]).range([
          0
          width
        ])
        chart = d3.select('.chart').html('').attr('width', width).attr('height', barHeight * data.length)
        bar =
        chart.selectAll('g').data(data).enter().append('g').attr('transform', (d, i) -> 'translate(0, ' + i * barHeight + ')'
        )
        bar.append('rect').attr('width', (d) -> x(d.count)).attr('x', '50').attr 'height', barHeight - 1
        bar.append('text').attr('x', 45 )
          .attr('class', 'label')
          .attr('y', barHeight / 2)
          .attr('dy', '.35em').text (d) -> d.time
        bar.append('text').attr('x', (d) -> x(d.count) - 3 +  50 )
          .attr('y', barHeight / 2)
          .attr('dy', '.35em').text (d) -> d.count

