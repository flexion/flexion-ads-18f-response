'use strict'

angular.module 'gsfFdaApp'
.controller 'NavbarCtrl', ($scope, $location) ->
  $scope.menu = [{
    title: 'Home'
    link: '/'},
    {
      title: 'About'
      link: '/about/'
    },
    {
      title: 'Contact'
      link: '/contact/'
    }
  ]
  $scope.isCollapsed = true

  $scope.isActive = (route) ->
    route is $location.path()
