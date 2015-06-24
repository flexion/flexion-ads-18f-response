(function(doc,win){
"use strict";
console.log('loaded sample.js');
  var data1 = [4, 8 ,15, 16, 23, 42],
  data2 =[1, 4, 9, 12, 8],
  data3 = [9, 8, 2, 3, 7],
  data4 = [7, 8, 3, 5, 4];
  var width = 780,
  barHeight = 40;

  var x = d3.scale.linear()
    .domain([0, d3.max(data1)])
    .range([0, width]);
  var chart = d3.select('.chart')
    .attr('width', width+'%')
    .attr('height', barHeight * data1.length * 2);
  var bar = chart.selectAll('g')
      .data(data1)
      .enter().append('g')
      .attr('transform', function(d, i) {return "translate(0,"+ i * barHeight * 2 + ")"; });
  bar.append("rect")
    .attr('width', x)
    .attr('height', barHeight -1);
  bar.append('text')
    .attr('x', function(d) {return x(d) -3;})
    .attr('y', barHeight /2)
    .attr('dy', '.35em')
    .text(function(d) {return d;});

  var width = 220,
    barHeight = 20;
  var chart = d3.select('.chart2')
    .attr('width', width)
    .attr('height', barHeight * data1.length);
  var bar = chart.selectAll('g')
      .data(data2)
      .enter().append('g')
      .attr('transform', function(d, i) {return "translate(0,"+ i *barHeight + ")"; });
  bar.append("rect")
    .attr('width', x)
    .attr('height', barHeight -1);
  bar.append('text')
    .attr('x', function(d) {return x(d) -3;})
    .attr('y', barHeight /2)
    .attr('dy', '.35em')
    .text(function(d) {return d;});


  var chart = d3.select('.chart3')
    .attr('width', width)
    .attr('height', barHeight * data1.length);
  var bar = chart.selectAll('g')
      .data(data3)
      .enter().append('g')
      .attr('transform', function(d, i) {return "translate(0,"+ i *barHeight + ")"; });
  bar.append("rect")
    .attr('width', x)
    .attr('height', barHeight -1);
  bar.append('text')
    .attr('x', function(d) {return x(d) -3;})
    .attr('y', barHeight /2)
    .attr('dy', '.35em')
    .text(function(d) {return d;});


  var chart = d3.select('.chart4')
    .attr('width', width)
    .attr('height', barHeight * data1.length);
  var bar = chart.selectAll('g')
      .data(data4)
      .enter().append('g')
      .attr('transform', function(d, i) {return "translate(0,"+ i *barHeight + ")"; });
  bar.append("rect")
    .attr('width', x)
    .attr('height', barHeight -1);
  bar.append('text')
    .attr('x', function(d) {return x(d) -3;})
    .attr('y', barHeight /2)
    .attr('dy', '.35em')
    .text(function(d) {return d;});

})(document, window);
