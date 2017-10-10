@gradecraft.directive 'assignmentEditGrading', [() ->
  {
    scope:
      assignment: "="
      rubricId: '='
    templateUrl: 'assignments/edit_grading.html'
  }
]
