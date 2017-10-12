@gradecraft = angular.module('gradecraft', [
  'ngAnimate',
  'ngDragDrop',
  'ngDraggable',
  'uiFx',
  'restangular',
  'ui.sortable',
  'puElasticInput',
  'ui.router',
  'ng-rails-csrf',
  'ngResource',
  'ngAnimate',
  'froala',
  'templates',
  'helpers',
  'ngAria',
  'tandibar/ng-rollbar'
])

@gradecraft.config ($stateProvider, $urlRouterProvider, $locationProvider) ->

@gradecraft.config(['$compileProvider', ($compileProvider)->
  $compileProvider.debugInfoEnabled(false)
])

@gradecraft.config(['$ariaProvider', ($ariaProvider)->
  $ariaProvider.config({
    ariaRequired: false
  })
]);

@gradecraft.config(['RollbarProvider', (RollbarProvider) ->
  RollbarProvider.init({
    accessToken: "9d4d1ff5420b4c9a82eef7d0f9b8f3dd"
    captureUncaught: true
    payload:
      environment: 'staging'
  })
])

@gradecraft.directive "modalDialog", ->
  restrict: "E"
  scope:
    show: "="

  replace: true # Replace with the template below
  transclude: true # we want to insert custom content inside the directive
  link: (scope, element, attrs) ->
    scope.dialogStyle = {}
    scope.dialogStyle.width = attrs.width  if attrs.width
    scope.dialogStyle.height = attrs.height  if attrs.height
    scope.hideModal = ->
      scope.show = false
      return

    return

  template: "..." # See below

INTEGER_REGEXP = /^\-?\d+$/
@gradecraft.directive "integer", ->
  require: "ngModel"
  link: (scope, elm, attrs, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      if INTEGER_REGEXP.test(viewValue)
        # it is valid
        ctrl.$setValidity "integer", true
        viewValue
      else
        # it is invalid, return undefined (no model update)
        ctrl.$setValidity "integer", false
        'undefined'
    return

FLOAT_REGEXP = /^\-?\d+((\.|\,)\d+)?$/
@gradecraft.directive "smartFloat", ->
  require: "ngModel"
  link: (scope, elm, attrs, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      if FLOAT_REGEXP.test(viewValue)
        ctrl.$setValidity "float", true
        parseFloat viewValue.replace(",", ".")
      else
        ctrl.$setValidity "float", false
        `undefined`

    return

@gradecraft.directive "ngMax", ->
  require: "ngModel"
  link: (scope, elm, attr, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      value = viewValue
      #alert("value:" + value)
      max = scope.$eval(attr.ngMax)
      #alert("max:" + max)
      if value and value != "" and value > max
        ctrl.$setValidity "ngMax", false
        'undefined'
      else
        ctrl.$setValidity "ngMax", true
        value

    return

@gradecraft.directive "ngOnscreen", ->
  require: "ngModel"
  link: (scope, elm, attr, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      value = viewValue
      max = scope.$eval(attr.ngMax)
      if value and value != "" and value > max
        ctrl.$setValidity "ngMax", false
        'undefined'
      else
        ctrl.$setValidity "ngMax", true
        value

    return


@gradecraft.filter 'list', ['$sce', ($sce)->
  (input)->
    if typeof(input) == "string"
      return $sce.trustAsHtml(input)
    else if Array.isArray(input)
      return $sce.trustAsHtml("<ul><li>" + input.join('</li><li>') + "</li></ul>")
]

@gradecraft.filter 'html', ['$sce', ($sce)->
  (val) ->
    return $sce.trustAsHtml val
]
