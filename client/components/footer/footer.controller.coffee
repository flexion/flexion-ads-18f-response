'use strict'

angular.module 'gsfFdaApp'
.controller 'FooterCtrl', ($scope, $location) ->
  $scope.menu = [{
    title: 'Terms and Privacy'
    link: '/terms-and-privacy/'
    }
  ]
  $scope.isCollapsed = true

  $scope.isActive = (route) ->
    rout is $location.path()

