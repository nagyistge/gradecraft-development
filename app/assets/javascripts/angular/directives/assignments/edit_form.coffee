# Main Edit form with tabbed sections
@gradecraft.directive 'assignmentEditForm', ['AssignmentTypeService', 'AssignmentService', (AssignmentTypeService, AssignmentService) ->

  return {
    scope: {
      assignment: "="
      rubricId: '='
    }
    templateUrl: 'assignments/edit_form.html',
    link: (scope, el, attr, ngModelCtrl)->

      scope.termFor = AssignmentService.termFor

      scope.updateAssignment = ()->
        AssignmentService.queueUpdateAssignment(@assignment.id)

      scope.submitAssignment = ()->
        AssignmentService.submitAssignment(@assignment.id)

      scope.tabInFocus = "basics"
      scope.focusTab = (focus)->
        scope.tabInFocus = focus
      scope.isFocusTab = (focus)->
        return true if focus == scope.tabInFocus
        return false
  }
]
