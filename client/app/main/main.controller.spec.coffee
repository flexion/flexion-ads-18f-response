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
    $httpBackend.whenGET(/^\/api\/epi-search\/\?search=.*/).respond {
      results:[
        {time: "20040102", count: 1},
        {time: "20040103", count: 2}
      ]
    }
    scope = $rootScope.$new()
    MainCtrl = $controller 'MainCtrl',
      $scope: scope

  describe 'search', ->
    it 'should attach a list of adverseReactions to the scope', ->
      scope.search('lyrica')
      $httpBackend.flush()
      expect(scope.adverseReactions).toBeDefined()
