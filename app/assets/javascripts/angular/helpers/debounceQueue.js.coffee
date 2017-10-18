# Debounce manager used to auto update items
#
# Each item is given a unique timeout stored by type and id.
# It can be cancelled and updated before fire,
# or fired immediately, cancelling the standing delayed event.

angular.module('helpers').factory('DebounceQueue', ['$timeout', '$q', ($timeout, $q)->

  queueStore = {}

  # Standard delay for making model updates via api
  API_REQUEST_DELAY = 2500

  # type and id are used to create a unique timout
  # event will be called with args
  # add custom delay, or 0 to cancel existing timeout and fire immediately
  addEvent = (type, id, event, args=[], delay=API_REQUEST_DELAY)->
    return console.warn("Unable to add event:", type, "for:", id) if not type? || not id?

    if delay == 0
      cancelEvent(type, id)
      event.apply(null, args)
    else
      cancelEvent(type, id)
      queueStore[type + id] = {
        promise: $timeout(() ->
          event.apply(null, args)
        , delay),
        event: event,
        args: args
      }

  cancelEvent = (type, id)->
    storeId = type + id
    return false if !queueStore[storeId]
    $timeout.cancel(queueStore[storeId].promise)

  runAllEvents = (redirectUrl=null)->
    events = []
    _.each(queueStore, (queueItem) ->
      $timeout.cancel(queueItem.promise)
      events.push(queueItem.event.apply(null, queueItem.args))
    )
    $q.all(events).then(() ->
      window.location.href = redirectUrl if redirectUrl?
    )

  return {
    addEvent: addEvent
    cancelEvent: cancelEvent
    runAllEvents: runAllEvents
  }
])
