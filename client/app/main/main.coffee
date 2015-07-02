'use strict'

angular.module 'gsfFdaApp'
.config ($stateProvider) ->
  $stateProvider
  .state 'main',
    url: '/'
    templateUrl: 'app/main/main.html'
    controller: 'MainCtrl'
  .state 'about',
    url: '/about/'
    templateUrl: 'app/main/about.html'
  .state 'contact',
    url: '/contact/'
    templateUrl: 'app/main/contact.html'
  .state 'terms',
    url: '/terms-and-privacy/'
    templateUrl: 'app/main/terms-and-privacy.html'
 
