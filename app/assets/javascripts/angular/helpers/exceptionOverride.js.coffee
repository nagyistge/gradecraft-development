angular.module('helpers')
  .factory('$exceptionHandler', () ->

    (exception, cause) ->
      exception.message += 'Angular Exception: "' + cause + '"'
      throw exception
  )
