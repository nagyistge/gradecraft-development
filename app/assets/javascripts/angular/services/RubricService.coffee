# Currently, RubricService is used for retrieving a rubric for a rubric graded
# assignment, so the rubric id is collected from the assignment, and is read-only
# Ideally this service should be expanded to handle the rubric design process too.


@gradecraft.factory 'RubricService', ['BadgeService', 'GradeCraftAPI', 'DebounceQueue', '$http', (BadgeService, GradeCraftAPI, DebounceQueue, $http) ->

  rubric = {}
  criteria = []
  levels = []
  _gradeWithRubric = undefined
  _copyRubricPath = undefined
  _fullPoints = 0

  _editingBadgesId = null

  getRubric = (rubricId)->
    $http.get("/api/rubrics/" + rubricId).then(
      (response) ->
        if response.data.data?  # if no rubric is found, data is null
          GradeCraftAPI.loadItem(rubric, "rubrics", response.data)
          GradeCraftAPI.loadFromIncluded(criteria, "criteria", response.data)
          GradeCraftAPI.loadFromIncluded(levels, "levels", response.data)
          _fullPoints = response.data.meta.full_points
          GradeCraftAPI.logResponse(response.data)
        gradeWithRubric(response.data.meta.grade_with_rubric)
        copyRubricPath(response.data.meta.copy_rubric_path)
      ,(response) ->
        GradeCraftAPI.logResponse(response.data)
    )

  fullPoints = ()->
    _fullPoints

  gradeWithRubric = (val) ->
    if angular.isDefined(val) then (_gradeWithRubric = val) else _gradeWithRubric

  copyRubricPath = (path) ->
    if angular.isDefined(path) then (_copyRubricPath = path) else _copyRubricPath

  pointsAssigned = ()->
    # use sumBy if lodash version > 4.0
    x = _.map(criteria, (criterion)->
      criterion.max_points
    )
    _.sum(x)

#----------- NEW CRITERIA -----------------------------------------------------#

# New Criteria are not saved until they are valid.
# We allow only one new criteria in process at a time.

  openNewCriterion = ()->
    criteria.push({
      newCriterion: true
      rubric_id: rubric.id
      name: "",
      max_points: null
      description: ""
      order: criteria.length + 1
    })

  criterionIsValid = (criterion)->
    return false if !criterion.name || criterion.name.length < 1
    return false if criterion.max_points == null
    return true

  saveNewCriterion = (newCriterion)->
    return if !criterionIsValid(newCriterion)
    $http.post("/api/criteria", newCriterion).then(
      (response)-> # success
        angular.copy(response.data.data.attributes, newCriterion)
        GradeCraftAPI.loadFromIncluded(levels, "levels", response.data)
        GradeCraftAPI.logResponse(response)
      ,(response)-> # error
        GradeCraftAPI.logResponse(response)
    )

  removeNewCriterion = ()->
    updatedCriteria = _.reject(criteria, { newCriterion: true })
    angular.copy(updatedCriteria, criteria)

#----------- EXISTING CRITERIA ------------------------------------------------#

  deleteCriterion = (criterion)->
    if confirm("Are you sure you want to delete this criterion?")
      $http.delete("/api/criteria/#{criterion.id}").then(
        (response)-> # success
          angular.copy(_.reject(criteria, {id: criterion.id}), criteria)
          GradeCraftAPI.logResponse(response)
        ,(response)-> # error
          GradeCraftAPI.logResponse(response)
      )

  _updateCriterion = (criterion)->
    $http.put("/api/criteria/#{criterion.id}", criterion).then(
      (response)-> # success
        criterion =  response.data.data.attributes
        GradeCraftAPI.logResponse(response)
      ,(response)-> # error
        GradeCraftAPI.logResponse(response)
    )

  queueUpdateCriterion = (criterion)->
    DebounceQueue.addEvent(
      "criteria", criterion.id, _updateCriterion, [criterion]
    )

  updateCriterionOrder = (start, end)->
    criteria.splice( end, 0, criteria.splice(start, 1)[0])
    criteriaIds = _.map(criteria, (criterion)->
      criterion.id
    )
    $http.put("/api/criteria/update_order", criteria_ids: criteriaIds).then(
      (response)-> # success
        GradeCraftAPI.logResponse(response)
      ,(response)-> # error
        GradeCraftAPI.logResponse(response)
    )


#----------- NEW LEVELS -------------------------------------------------------#

# New Levels are not saved until they are valid

# Assumes only one new level per criterion, add new button is hidden in view
# if one new level already in progress and not saved.

  openNewLevel = (criterion)->
    levels.push({
      newLevel: true,
      criterion_id: criterion.id,
      name: "",
      points: null
      description: ""
    })

  levelIsValid = (level)->
    return false if !level.name || level.name.length < 1
    return false if level.points == null
    return true

  saveNewLevel = (newLevel)->
    return if !levelIsValid(newLevel)
    $http.post("/api/levels", newLevel).then(
      (response)-> # success
        angular.copy(response.data.data.attributes, newLevel)
        GradeCraftAPI.logResponse(response)
      ,(response)-> # error
        GradeCraftAPI.logResponse(response)
    )

  removeNewLevel = (newLevel)->
    updatedLevels = _.reject(levels, {newLevel: true, criterion_id: newLevel.criterion_id})
    angular.copy(updatedLevels, levels)

#----------- EXISTING LEVELS --------------------------------------------------#

  criterionLevels = (criterion)->
    _.filter(levels, {criterion_id: criterion.id})

  _updateLevel = (level)->
    $http.put("/api/levels/#{level.id}", level).then(
      (response)-> # success
        angular.copy(response.data.data.attributes, level)
        GradeCraftAPI.logResponse(response)
      ,(response)-> # error
        GradeCraftAPI.logResponse(response)
    )

  queueUpdateLevel = (level)->
    DebounceQueue.addEvent(
      "levels", level.id, _updateLevel, [level]
    )

  deleteLevel = (level)->
    if confirm("Are you sure you want to delete this level?")
      $http.delete("/api/levels/#{level.id}").then(
        (response)-> # success
          angular.copy(_.reject(levels, {id: level.id}), levels)
          GradeCraftAPI.logResponse(response)
        ,(response)-> # error
          GradeCraftAPI.logResponse(response)
      )

#----------- LEVELS BADGES ----------------------------------------------------#

  addLevelBadge = (level, badgeId)->
    $http.post("/api/level_badges", {level_id: level.id, badge_id: badgeId}).then(
      (response)-> # success
        if response.status == 201
          updatedLevels = _.map(levels, (currentLevel)->
            if currentLevel.id == level.id
              currentLevel.level_badges.push(response.data.data.attributes)
              currentLevel.available_badges = _.reject(currentLevel.available_badges,(id: response.data.data.attributes.badge_id))
            return currentLevel
          )
          angular.copy(updatedLevels, levels)
        GradeCraftAPI.logResponse(response)
      ,(response)-> # error
        GradeCraftAPI.logResponse(response)
    )

  deleteLevelBadge = (level, badgeId)->
    levelBadge = _.find(level.level_badges, {badge_id: badgeId})
    if levelBadge
      $http.delete("/api/level_badges/#{levelBadge.id}").then(
        (response)-> # success
          if response.status == 200
            updatedLevels = _.map(levels, (currentLevel)->
              if currentLevel.id == level.id
                currentLevel.level_badges = _.reject(currentLevel.level_badges,(badge_id: badgeId))
                badge = _.find(BadgeService.badges, {id: badgeId})
                currentLevel.available_badges.push({id: badge.id, name: badge.name})
              return currentLevel
            )
            angular.copy(updatedLevels, levels)
          GradeCraftAPI.logResponse(response)
        ,(response)-> # error
          GradeCraftAPI.logResponse(response)
      )
    else
      console.log("error: level badge not found");

  badgesForLevel = (level)->
    return [] unless level.level_badges.length && BadgeService.badges.length
    ids = _.map(level.level_badges, (badge)->badge["badge_id"])
    # change indexBy to keyBy if lowdash is updated to v4
    badges = _(BadgeService.badges).indexBy('id').at(ids).value();

  # We only allow one open modal for editing badges
  editBadgesForLevel = (level)->
     _editingBadgesId = level.id

  editingBadgesForLevel = (level)->
    level.id == _editingBadgesId

  closeBadgesForLevel = ()->
    _editingBadgesId = null

#----------- EXPECTATIONS -----------------------------------------------------#

  _refreshExpectations = (level,data)->
    updatedCriteria = _.map(criteria, (criterion)->
      if(criterion.id == level.criterion_id)
        criterion = data.data.attributes
      return criterion
    )
    angular.copy(updatedCriteria, criteria)
    updatedLevels = _.reject(levels, {criterion_id: level.criterion_id})
    GradeCraftAPI.loadFromIncluded(updatedLevels, "levels", data)
    angular.copy(updatedLevels, levels)


  setMeetsExpectations = (level)->
    $http.put("/api/criteria/#{level.criterion_id}/levels/#{level.id}/set_expectations").then(
      (response)-> # success
        if response.status == 200
          _refreshExpectations(level, response.data)
        GradeCraftAPI.logResponse(response)
      ,(response)-> # error
        GradeCraftAPI.logResponse(response)
    )

  removeMeetsExpectations = (level)->
    $http.put("/api/criteria/#{level.criterion_id}/remove_expectations").then(
      (response)-> # success
        if response.status == 200
          _refreshExpectations(level, response.data)
        GradeCraftAPI.logResponse(response)
      ,(response)-> # error
        GradeCraftAPI.logResponse(response)
    )

  updateMeetsExpectationsLevel = (criterion, level)->
    if isMeetsExpectationsLevel(criterion, level)
      removeMeetsExpectations(level)
    else
      setMeetsExpectations(level)

  # This criterion has a level set as "meets expectations"
  meetsExpectationsSet = (criterion)->
    criterion.meets_expectations_points > 0

  # This is the level that is set for "meets expectations"
  isMeetsExpectationsLevel = (criterion, level)->
    criterion.meets_expectations_level_id == level.id

  # This level is or exceeds the "meets expectations" level
  satifiesExpectations = (criterion, level)->
    meetsExpectationsSet(criterion) && (level.points >= criterion.meets_expectations_points)


  return {
    getRubric: getRubric
    rubric: rubric
    criteria: criteria
    levels: levels
    gradeWithRubric: gradeWithRubric
    copyRubricPath: copyRubricPath
    fullPoints: fullPoints

    pointsAssigned: pointsAssigned
    criterionLevels: criterionLevels

    openNewCriterion: openNewCriterion
    saveNewCriterion: saveNewCriterion
    removeNewCriterion: removeNewCriterion

    queueUpdateCriterion: queueUpdateCriterion
    updateCriterionOrder: updateCriterionOrder
    deleteCriterion: deleteCriterion

    openNewLevel: openNewLevel
    saveNewLevel: saveNewLevel
    removeNewLevel: removeNewLevel

    queueUpdateLevel: queueUpdateLevel
    deleteLevel: deleteLevel

    addLevelBadge: addLevelBadge
    deleteLevelBadge: deleteLevelBadge
    badgesForLevel: badgesForLevel

    editBadgesForLevel: editBadgesForLevel
    editingBadgesForLevel: editingBadgesForLevel
    closeBadgesForLevel: closeBadgesForLevel

    updateMeetsExpectationsLevel: updateMeetsExpectationsLevel
    meetsExpectationsSet: meetsExpectationsSet
    isMeetsExpectationsLevel: isMeetsExpectationsLevel
    satifiesExpectations: satifiesExpectations
  }
]
