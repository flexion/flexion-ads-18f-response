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
    controller: 'AboutCtrl'
  .state 'contact',
    url: '/contact/'
    templateUrl: 'app/main/contact.html'
    controller: 'ContactCtrl'
  .state 'terms',
    url: '/terms/'
    templateUrl: 'app/main/terms.html'
    controller: 'TermsCtrl'
  .state 'privacy',
    url: '/privacy/'
    templateUrl: 'app/main/privacy.html'
    controller: 'PrivacyCtrl'

