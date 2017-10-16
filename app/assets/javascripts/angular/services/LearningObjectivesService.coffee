# Service for creating and updating learning objectives for the current course
@gradecraft.factory 'LearningObjectivesService', ['$http', 'GradeCraftAPI', 'DebounceQueue', ($http, GradeCraftAPI, DebounceQueue) ->

  _lastUpdated = undefined

  _levels = []
  _objectives = []
  _categories = []
  levelFlaggedValues = {}

  objective = () ->
    _objectives[0]

  levels = (objective) ->
    _.filter(_levels, { objective_id: objective.id })

  objectives = (category=null) ->
    if category? then _.filter(_objectives, { category_id: category.id }) else _objectives

  categories = (savedOnly=false) ->
    if savedOnly then _.filter(_categories, "id") else _categories

  addObjective = () ->
    _objectives.push(
      name: undefined
      description: undefined
      countToAchieve: undefined
      category_id: null
    )

  addCategory = () ->
    _categories.push(
      name: undefined
      allowable_yellow_warnings: undefined
    )

  addLevel = (objectiveId) ->
    _levels.push(
      objective_id: objectiveId
      name: undefined
      description: undefined
      flagged_value: 1
    )

  getObjective = (id) ->
    $http.get("/api/learning_objectives/objectives/#{id}").then(
      (response) ->
        GradeCraftAPI.addItem(_objectives, "learning_objective", response.data)
        GradeCraftAPI.logResponse(response)
      , (response) ->
        GradeCraftAPI.logResponse(response)
    )

  # GET objectives or categories
  # Objectives are expected to come with associated levels
  getArticles = (type) ->
    $http.get("/api/learning_objectives/#{type}").then(
      (response) ->
        arr = if type == "objectives" then _objectives else _categories
        arr.length = 0
        GradeCraftAPI.loadMany(arr, response.data)
        if type == "objectives"
          GradeCraftAPI.loadFromIncluded(_levels, "levels", response.data)
          angular.copy(response.data.meta.level_flagged_values, levelFlaggedValues)
        GradeCraftAPI.setTermFor("learning_objective", response.data.meta.term_for_learning_objective)
        GradeCraftAPI.setTermFor("learning_objectives", response.data.meta.term_for_learning_objectives)
        GradeCraftAPI.logResponse(response)
      , (response) ->
        GradeCraftAPI.logResponse(response)
    )

  # POST/PUT articles such as learning objectives, categories
  persistArticle = (article, type) ->
    return if !article.name? || article.isCreating

    if !isSaved(article)
      article.isCreating = true
      _createArticle(article, type)
    else
      DebounceQueue.addEvent(
        type, article.id, _updateArticle, [article, type]
      )

  # POST/PUT associated data such as learning objective levels
  # Route: /api/learning_objectives/#{association}/#{associationId}/#{type}
  # e.g. /api/learning_objectives/objectives/1/levels
  persistAssociatedArticle = (association, associationId, article, type) ->
    return if !article.name? || article.isCreating
    routePrefix = "/api/learning_objectives/#{association}/#{associationId}"

    if !isSaved(article)
      article.isCreating = true
      _createArticle(article, type, routePrefix)
    else
      DebounceQueue.addEvent(
        type, article.id, _updateArticle, [article, type, routePrefix]
      )

  # DELETE articles such as learning objectives, categories
  deleteArticle = (article, type, redirectUrl=null) ->
    arr = if type == "objectives" then _objectives else _categories
    return arr.splice(arr.indexOf(article), 1) if !article.id?

    if confirm "Are you sure you want to delete #{article.name}?"
      $http.delete("/api/learning_objectives/#{type}/#{article.id}").then(
        (response) ->
          arr.splice(arr.indexOf(article), 1)
          GradeCraftAPI.logResponse(response)
          window.location.href = redirectUrl if redirectUrl?
        , (response) ->
          GradeCraftAPI.logResponse(response)
      )

  # DELETE associated articles such as learning objective levels
  deleteAssociatedArticle = (association, associationId, article, type) ->
    return _levels.splice(_levels.indexOf(article), 1) if !article.id?

    if confirm "Are you sure you want to delete #{article.name}?"
      $http.delete("/api/learning_objectives/#{association}/#{associationId}/#{type}/#{article.id}").then(
        (response) ->
          _levels.splice(_levels.indexOf(article), 1)
          GradeCraftAPI.logResponse(response)
        , (response) ->
          GradeCraftAPI.logResponse(response)
      )

  lastUpdated = (date) ->
    if angular.isDefined(date) then _lastUpdated = date else _lastUpdated

  termFor = (article) ->
    GradeCraftAPI.termFor(article)

  isSaved = (article) ->
    article.id?

  categoryFor = (objective) ->
    _.find(_categories, { id: objective.category_id })

  _createArticle = (article, type, routePrefix="/api/learning_objectives") ->
    promise = $http.post("#{routePrefix}/#{type}", _params(article, type))
    _resolve(promise, article, type)

  _updateArticle = (article, type, routePrefix="/api/learning_objectives") ->
    promise = $http.put("#{routePrefix}/#{type}/#{article.id}", _params(article, type))
    _resolve(promise, article, type)

   _params = (article, type) ->
    params = {}
    term = switch type
      when "objectives" then "learning_objective"
      when "categories" then "learning_objective_category"
      when "levels" then "learning_objective_level"
    params[term] = article
    params

  _resolve = (promise, article, type) ->
    promise.then(
      (response) ->
        angular.copy(response.data.data.attributes, article)
        lastUpdated(article.updated_at)
        article.isCreating = false
        # article.status = _saveStates.success
        GradeCraftAPI.logResponse(response)
      , (response) ->
        GradeCraftAPI.logResponse(response)
        # article.status = _saveStates.failure
    )

  {
    levels: levels
    objectives: objectives
    categories: categories
    levelFlaggedValues: levelFlaggedValues
    objective: objective
    addObjective: addObjective
    addCategory: addCategory
    addLevel: addLevel
    getObjective: getObjective
    getArticles: getArticles
    persistArticle: persistArticle
    persistAssociatedArticle: persistAssociatedArticle
    deleteArticle: deleteArticle
    deleteAssociatedArticle: deleteAssociatedArticle
    lastUpdated: lastUpdated
    termFor: termFor
    isSaved: isSaved
    categoryFor: categoryFor
  }
]
