@gradecraft.factory 'GradeImporterService', ['$http', 'GradeCraftAPI', 'AssignmentService', ($http, GradeCraftAPI, AssignmentService) ->

  grades = []
  assignment = AssignmentService.assignment

  # Optionally takes a page number in the event that we don't want to automatically
  # fetch additional
  getGrades = (assignmentId, courseId, provider, assignmentIds, page = 1) ->
    $http.get("/api/assignments/#{assignmentId}/grades/importers/#{provider}/course/#{courseId}",
      params: _gradeParams(page, assignmentIds)).then(
        (response) ->
          GradeCraftAPI.addItems(grades, "imported_grade", response.data)
          GradeCraftAPI.setTermFor("assignment", response.data.meta.term_for_assignment)
          GradeCraftAPI.logResponse(response.data)
        , (response) ->
          GradeCraftAPI.logResponse(response.data)
    )

  getAssignment = (id) ->
    AssignmentService.getAssignment(id)

  termFor = (article) ->
    GradeCraftAPI.termFor(article)

  selectAllGrades = () ->
    _setGradesSelected(true)

  deselectAllGrades = () ->
    _setGradesSelected(false)

  _setGradesSelected = (selected) ->
    _.each(grades, (grade) ->
      grade.selected_for_import = selected
      true  # if selected is false, this loop is broken without this line
    )

  _gradeParams = (page, assignmentIds) ->
    {
      page: page
      assignment_ids: assignmentIds
    }

  {
    grades: grades
    assignment: assignment
    termFor: termFor
    getGrades: getGrades
    getAssignment: getAssignment
    selectAllGrades: selectAllGrades
    deselectAllGrades: deselectAllGrades
  }
]
