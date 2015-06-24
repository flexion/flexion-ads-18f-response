'use strict'

describe 'Controller: MainCtrl', ->

  # load the controller's module
  beforeEach module 'gsfFdaApp'

  MainCtrl = undefined
  scope = undefined
  $httpBackend = undefined

  # Initialize the controller and a mock scope
  beforeEach inject (_$httpBackend_, $controller, $rootScope) ->
    $httpBackend = _$httpBackend_
    $httpBackend.expectGET('/api/epi-search/?search={"search":{"fields":[{"field":"brand_name","terms":[{"term":"lyrica"}]},{"field":"serious","terms":[{"term":"1"}],"isAnd":true},{"field":"receivedate","terms":[{"term":"[20140101+TO+20150101]"}],"isAnd":true}],"count":{"field":"receivedate"}}}').respond {
      results:[
        {term: "term1", count: 1},
        {term: "term2", count: 2}
      ]
    }
    scope = $rootScope.$new()
    MainCtrl = $controller 'MainCtrl',
      $scope: scope

  describe 'search', ->
    it 'should attach a list of adverseReactions to the scope', ->
      scope.search('lyrica')
      $httpBackend.flush()
      expect(scope.adverseReactions.length).toBe 2
