'use strict'

angular.module 'gsfFdaApp'
  .directive 'barChart', ($parse) ->
    directiveDefinitionObject =
      restrict: 'E'
      replace: false
      scope: {data: '=chartData'}
      link: (scope, element, attrs) ->
        data = attrs.chartData
        console.log data #.split(',')

        chart = d3.select(element[0])
        chart.append('div').attr('class', 'chart').selectAll('div').data(data).enter().append('div').transition().ease('elastic').style('width', (d) ->
          d + '%'
        ).text (d) ->
          d + '%'
        return
    directiveDefinitionObject
