'use strict'

angular.module 'gsfFdaApp'
.controller 'MainCtrl', ($scope, $http) ->
  $scope.adverseReactions = []

  $http.get('/api/epi-search').success (adverseReactions) ->
    $scope.adverseReactions = adverseReactions.results


