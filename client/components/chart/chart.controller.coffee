'use strict'

data = [4, 8 ,15, 16, 23, 42]
width = 780
barHeight = 40
x = d3.scale.linear()
  .domain([0, d3.max(data)])
  .range([0, width])
chart = d3.select('.chart')
  .attr('width', width)
  .attr('height', barHeight * data.length * 2)
bar = chart.selectAll('g')
    .data(data)
    .enter().append('g')
    .attr('transform', (d, i) -> "translate(0,"+ i * barHeight * 2 + ")"; )
bar.append("rect")
  .attr('width', x)
  .attr('height', barHeight - 1)
bar.append('text')
  .attr('x', (d) -> x(d) - 3;)
  .attr('y', barHeight /2)
  .attr('dy', '.35em')
  .text((d) -> d;)


