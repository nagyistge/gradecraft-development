# Manages state of Assignments including API calls.
# Can be used independently, or via another service (see PredictorService)

@gradecraft.factory 'AssignmentService', ['$http', 'GradeCraftAPI', 'GradeCraftPredictionAPI', 'RubricService', 'DebounceQueue', ($http, GradeCraftAPI, GradeCraftPredictionAPI, RubricService, DebounceQueue) ->

  assignments = []
  update = {}
  fileUploads = []

  # managing a single assignment resource,
  # must be a function for Angular two-way binding to work
  assignment = ()->
    assignments[0]

  termFor = (article)->
    GradeCraftAPI.termFor(article)

  # Total points earned and predicted for a collection of assignments
  # Used to total by Assignment Type
  assignmentsSubsetPredictedPoints = (subset)->
    total = 0
    _.each(subset, (assignment)->
      # use raw score to keep weighting calculation on assignment type level
      if assignment.grade.final_points != null
        if ! assignment.grade.is_excluded
          total += assignment.grade.final_points
      else if ! assignment.pass_fail && ! assignment.closed_without_submission
        if !(assignment.is_closed_without_submission || assignment.is_closed_by_condition)
          total += assignment.prediction.predicted_points || 0
    )
    total

  # Total points earned and predicted for all assignments
  assignmentsPredictedPoints = ()->
    assignmentsSubsetPredictedPoints(assignments)

  ValidateDates = (assignment)->
    valid = true
    messages = []

    # verify OpenBeforeCloseValidator will pass
    if (assignment.due_at? && assignment.open_at?) && (assignment.due_at < assignment.open_at)
      messages.push("Due date must be after open date.")
      valid = false
    # verify SubmissionsAcceptedAfterOpenValidator will pass
    if (assignment.accepts_submissions_until? && assignment.open_at?) && (assignment.accepts_submissions_until < assignment.open_at)
      messages.push("Submission accept date must be after open date.")
    # verify SubmissionsAcceptedAfterDueValidator will pass
    if (assignment.due_at? && assignment.accepts_submissions_until?) && (assignment.accepts_submissions_until < assignment.due_at)
      messages.push("Submission accept date must be after due date.")
      valid = false
    return { valid: valid, messages: messages}

  #------ API Calls -----------------------------------------------------------#

  # GET single assignment, will be the only item in the assignments array
  getAssignment = (assignmentId)->
    $http.get('/api/assignments/' + assignmentId).then(
      (response)->
        GradeCraftAPI.addItem(assignments, "assignments", response.data)
        if response.data.data.relationships && response.data.data.relationships.rubric
          RubricService.getRubric(response.data.data.relationships.rubric.data.id)
        GradeCraftAPI.loadFromIncluded(fileUploads,"file_uploads", response.data)
        GradeCraftAPI.setTermFor("assignment", response.data.meta.term_for_assignment)
        GradeCraftAPI.setTermFor("pass", response.data.meta.term_for_pass)
        GradeCraftAPI.setTermFor("fail", response.data.meta.term_for_fail)
        GradeCraftAPI.logResponse(response)
      (response)->
        GradeCraftAPI.logResponse(response)
    )

  # GET index list of assignments including a student's grades and predictions
  getAssignments = ()->
    $http.get('/api/assignments').then(
      (response)->
        GradeCraftAPI.loadMany(assignments, response.data, {"include" : ['prediction','grade']})
        _.each(assignments, (assignment)->
          # add null prediction and grades when JSON contains none
          assignment.prediction = { predicted_points: 0 } if !assignment.prediction
          assignment.grade = { score: null, final_points: null, is_excluded: false } if !assignment.grade

          GradeCraftAPI.formatDates(assignment,["open_at", "due_at", "accepts_submissions_until"])

          # Iterate through all Assignments that are conditions,
          # If they are closed_without_submission,
          # flag this assignment to be closed as well
          if assignment.conditional_assignment_ids
            assignment.is_closed_by_condition = false
            _.each(assignment.conditional_assignment_ids, (id)->
              a = _.find(assignments, {id: id})
              if a && a.is_closed_without_submission == true
                assignment.is_closed_by_condition = true
            )
        )
        GradeCraftAPI.setTermFor("assignment", response.data.meta.term_for_assignment)
        GradeCraftAPI.setTermFor("pass", response.data.meta.term_for_pass)
        GradeCraftAPI.setTermFor("fail", response.data.meta.term_for_fail)
        update.predicted_earned_grades = response.data.meta.allow_updates
        GradeCraftAPI.logResponse(response)
      (response)->
        GradeCraftAPI.logResponse(response)
    )

  # Assignment Attributes are updated individually from directives on the
  # settings page. Note that the updated attribute might be different from
  # the one passed in by json and optimised for the predictor:
  # example: required vs. is_required
  # Therefore we don't rely on the assignment models but pass the attribute
  # state in directly.
  updateAssignmentAttribute = (id, attribute, state) ->
    params = { "#{attribute}" : state }
    assignment = _.find(assignments, {id: id})
    $http.put("/api/assignments/#{id}", assignment: params).then(
      (response) ->
        assignment.attribute = state
        GradeCraftAPI.logResponse(response)
      ,(response) ->
        GradeCraftAPI.logResponse(response)
    )

  # Handles incremental updates from the Assignment form
  _updateAssignment = (id)->
    assignment = _.find(assignments, {id: id})
    if assignment && ValidateDates(assignment).valid
      $http.put("/api/assignments/#{id}", assignment: assignment).then(
        (response) ->
          angular.copy(response.data.data.attributes, assignment)
          GradeCraftAPI.logResponse(response)
        ,(response) ->
          GradeCraftAPI.logResponse(response)
      )


  queueUpdateAssignment = (id, attribute, state) ->
    DebounceQueue.addEvent(
      "assignments", id, _updateAssignment, [id]
    )

  # PUT a predicted earned grade for assignment
  postPredictedAssignment = (assignment)->
    if update.predicted_earned_grades
      requestParams = {
        "predicted_earned_grade": {
          "assignment_id": assignment.id,
          "predicted_points": assignment.prediction.predicted_points
        }}
      if assignment.prediction.id
        GradeCraftPredictionAPI.updatePrediction(assignment, '/api/predicted_earned_grades/' + assignment.prediction.id, requestParams)
      else
        GradeCraftPredictionAPI.createPrediction(assignment, '/api/predicted_earned_grades/', requestParams)

  #------- Media and File Methods ---------------------------------------------#

  removeMedia = (id)->
    assignment = _.find(assignments, {id: id})
    assignment.media = null
    assignment.remove_media = true
    _updateAssignment(id)

  postMediaUpload = (id, files)->
    mediaParams = new FormData()
    mediaParams.append('assignment[media]', files[0])
    $http.put("/api/assignments/#{id}", mediaParams,
      transformRequest: angular.identity,
      headers: { 'Content-Type': undefined }
    ).then(
      (response) ->
        assignment = _.find(assignments, {id: id})
        angular.copy(response.data.data.attributes, assignment)
        GradeCraftAPI.logResponse(response)
      ,(response) ->
        GradeCraftAPI.logResponse(response)
    )

  postFileUploads = (files)->
    console.log("posting files...");

  deleteFileUpload = (file)->
    file.deleting = true
    GradeCraftAPI.deleteItem(fileUploads, file)
    # $http.delete("/api/file_uploads/#{file.id}").then(
    #   (response)-> # success
    #     if response.status == 200
    #       GradeCraftAPI.deleteItem(fileUploads, file)
    #     GradeCraftAPI.logResponse(response)

    #   ,(response)-> # error
    #     file.deleting = false
    #     GradeCraftAPI.logResponse(response)
    # )


#------- Public Methods -------------------------------------------------------#

  return {
      assignment: assignment
      assignments: assignments
      assignmentsPredictedPoints: assignmentsPredictedPoints
      assignmentsSubsetPredictedPoints: assignmentsSubsetPredictedPoints
      getAssignment: getAssignment
      getAssignments: getAssignments
      postPredictedAssignment: postPredictedAssignment
      queueUpdateAssignment: queueUpdateAssignment
      termFor: termFor
      updateAssignmentAttribute: updateAssignmentAttribute
      ValidateDates: ValidateDates
      removeMedia: removeMedia
      postMediaUpload: postMediaUpload
      fileUploads: fileUploads
      postFileUploads: postFileUploads
      deleteFileUpload: deleteFileUpload
  }
]
