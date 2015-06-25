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
        height = 500
        barWidth = 30
        x = d3.scale.linear().domain([
          0
          d3.max(data, (d) -> d.count)
        ]).range([
          0
          height + 20
        ])
        chart = d3.select('.chart').html('').attr('height', height)
          .attr('width', barWidth * data.length)
        bar = chart.selectAll('g').data(data)
          .enter().append('g').attr('transform', 
          (d, i) -> 
            'translate(' + i * barWidth + ', 0)'
        )
        bar.append('rect').attr('height', (d) -> x(d.count))
          .attr('y', (d) -> (height - x(d.count)))
          .attr('width', barWidth - 1)
        bar.append('text').attr('x', barWidth / 2 )
          .attr('y', (d) -> (height - x(d.count) - 10))
          .attr('dy', '.35em').text (d) -> d.count

