'use strict'

angular.module 'gsfFdaApp', [
  'siyfion.sfTypeahead',
  'ngCookies',
  'ngResource',
  'ngSanitize',
  'ui.router',
  'ui.bootstrap'

]
.config ($stateProvider, $urlRouterProvider, $locationProvider) ->
  $urlRouterProvider
  .otherwise '/'

  $locationProvider.html5Mode true
