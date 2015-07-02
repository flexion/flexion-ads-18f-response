'use strict'

describe 'Controller: MainCtrl', ->

  payload = '{"meta":{"disclaimer":"openFDA is a beta research project and not for clinical use. While we make every effort to ensure that data is accurate, you should assume all results are unvalidated.","license":"http://open.fda.gov/license","last_updated":"2015-01-21"},"results":[{"time":"20140101","count":1},{"time":"20140102","count":39},{"time":"20140103","count":23},{"time":"20140106","count":30},{"time":"20140107","count":19},{"time":"20140108","count":25},{"time":"20140109","count":21},{"time":"20140110","count":46},{"time":"20140113","count":39},{"time":"20140114","count":14},{"time":"20140115","count":40},{"time":"20140116","count":63},{"time":"20140117","count":38},{"time":"20140118","count":36},{"time":"20140120","count":45},{"time":"20140121","count":49},{"time":"20140122","count":23},{"time":"20140123","count":45},{"time":"20140124","count":56},{"time":"20140125","count":3},{"time":"20140126","count":1},{"time":"20140127","count":64},{"time":"20140128","count":56},{"time":"20140129","count":29},{"time":"20140130","count":55},{"time":"20140131","count":60},{"time":"20140201","count":1},{"time":"20140203","count":53},{"time":"20140204","count":50},{"time":"20140205","count":23},{"time":"20140206","count":44},{"time":"20140207","count":69},{"time":"20140208","count":1},{"time":"20140210","count":58},{"time":"20140211","count":39},{"time":"20140212","count":35},{"time":"20140213","count":55},{"time":"20140214","count":60},{"time":"20140217","count":60},{"time":"20140218","count":66},{"time":"20140219","count":51},{"time":"20140220","count":50},{"time":"20140221","count":64},{"time":"20140224","count":54},{"time":"20140225","count":39},{"time":"20140226","count":57},{"time":"20140227","count":34},{"time":"20140228","count":51},{"time":"20140301","count":1},{"time":"20140302","count":1},{"time":"20140303","count":434},{"time":"20140304","count":369},{"time":"20140305","count":479},{"time":"20140306","count":553},{"time":"20140307","count":310},{"time":"20140308","count":1},{"time":"20140310","count":143},{"time":"20140311","count":25},{"time":"20140312","count":39},{"time":"20140313","count":26},{"time":"20140314","count":60},{"time":"20140316","count":1},{"time":"20140317","count":43},{"time":"20140318","count":45},{"time":"20140319","count":37},{"time":"20140320","count":36},{"time":"20140321","count":57},{"time":"20140324","count":37},{"time":"20140325","count":24},{"time":"20140326","count":38},{"time":"20140327","count":28},{"time":"20140328","count":72},{"time":"20140331","count":39},{"time":"20140401","count":39},{"time":"20140402","count":33},{"time":"20140403","count":50},{"time":"20140404","count":68},{"time":"20140405","count":6},{"time":"20140407","count":42},{"time":"20140408","count":26},{"time":"20140409","count":35},{"time":"20140410","count":31},{"time":"20140411","count":51},{"time":"20140413","count":1},{"time":"20140414","count":43},{"time":"20140415","count":26},{"time":"20140416","count":35},{"time":"20140417","count":29},{"time":"20140418","count":29},{"time":"20140421","count":30},{"time":"20140422","count":24},{"time":"20140423","count":22},{"time":"20140424","count":25},{"time":"20140425","count":44},{"time":"20140428","count":49},{"time":"20140429","count":44},{"time":"20140430","count":41},{"time":"20140501","count":34},{"time":"20140502","count":50},{"time":"20140505","count":36},{"time":"20140506","count":47},{"time":"20140507","count":50},{"time":"20140508","count":39},{"time":"20140509","count":72},{"time":"20140512","count":39},{"time":"20140513","count":39},{"time":"20140514","count":15},{"time":"20140515","count":44},{"time":"20140516","count":91},{"time":"20140517","count":2},{"time":"20140518","count":1},{"time":"20140519","count":40},{"time":"20140520","count":35},{"time":"20140521","count":34},{"time":"20140522","count":22},{"time":"20140523","count":62},{"time":"20140524","count":4},{"time":"20140526","count":5},{"time":"20140527","count":36},{"time":"20140528","count":34},{"time":"20140529","count":31},{"time":"20140530","count":58},{"time":"20140601","count":2},{"time":"20140602","count":30},{"time":"20140603","count":25},{"time":"20140604","count":24},{"time":"20140605","count":23},{"time":"20140606","count":37},{"time":"20140607","count":4},{"time":"20140609","count":26},{"time":"20140610","count":37},{"time":"20140611","count":16},{"time":"20140612","count":25},{"time":"20140613","count":44},{"time":"20140615","count":6},{"time":"20140616","count":43},{"time":"20140617","count":46},{"time":"20140618","count":29},{"time":"20140619","count":32},{"time":"20140620","count":57},{"time":"20140622","count":1},{"time":"20140623","count":39},{"time":"20140624","count":22},{"time":"20140625","count":30},{"time":"20140626","count":31},{"time":"20140627","count":42},{"time":"20140628","count":3},{"time":"20140629","count":2},{"time":"20140630","count":38}]}'

  # load the controller's module
  beforeEach module 'gsfFdaApp'

  MainCtrl = undefined
  scope = undefined
  $httpBackend = undefined

  # Initialize the controller and a mock scope
  beforeEach inject (_$httpBackend_, $controller, $rootScope) ->
    $httpBackend = _$httpBackend_
    $httpBackend.expectGET(/^\/api\/epi-search\/\?search=.*/).respond JSON.parse payload
    scope = $rootScope.$new()
    MainCtrl = $controller 'MainCtrl',
      $scope: scope

  describe 'search', ->
    it 'should attach a list of adverseReactions to the scope', ->
      scope.search 'lyrica'
      $httpBackend.flush()
      expect(scope.adverseReactions).toBeDefined()

    it 'should set a searchname', ->
      scope.search 'lyrica'
      $httpBackend.flush()
      expect(scope.searchname).toBe 'lyrica'

    it 'should aggregate events and parse into months', ->
      scope.search 'humira'
      $httpBackend.flush()
      expect(scope.adverseReactions[0].values.length).toBe 6
      expect(scope.adverseReactions[0].values[0][0]).toBe '201401'
      expect(scope.adverseReactions[0].values[0][1]).toBe 920

  describe 'scope.xAxisTickFormatFunction', ->
    it 'should format a date into monthnameshort space YYYY', ->
      formatted = scope.xAxisTickFormatFunction('201401')
      result = formatted('201401')
      expect(result).toBe 'Jan 2014'

  describe 'scope.valueFormatFunction', ->
    it 'should remove decimals from integer', ->
      func = scope.valueFormatFunction(1.1111)
      result = func(1.1111)
      expect(result).toBe '1'

  describe 'reset', ->
    it 'should reset adverseReactions', ->
      scope.search 'humira'
      $httpBackend.flush()
      scope.reset()
      expect(scope.adverseReactions.length).toBe 0

    it 'should reset brandname and searchname', ->
      scope.search 'humira'
      $httpBackend.flush()
      scope.reset()
      expect(scope.brandname).toBe ''
      expect(scope.searchname).toBe ''

