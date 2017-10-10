# Entry point for editing an assignment
@gradecraft.directive 'assignmentEdit', ['$q', 'AssignmentTypeService', 'AssignmentService', ($q, AssignmentTypeService, AssignmentService) ->
  AssignmentEditCtrl = [()->
    vmAssignmentEdit = this
    vmAssignmentEdit.loading = true

    vmAssignmentEdit.assignments = AssignmentService.assignments

    services(vmAssignmentEdit.assignmentId).then(()->
      vmAssignmentEdit.loading = false
    )
  ]

  services = (id)->
    promises = [
      AssignmentService.getAssignment(id),
      AssignmentTypeService.getAssignmentTypes(),
    ]
    return $q.all(promises)

  {
    bindToController: true,
    controller: AssignmentEditCtrl,
    controllerAs: 'vmAssignmentEdit',
    templateUrl: 'assignments/assignment_edit.html',
    scope: {
      assignmentId: "="
      rubricId: '='
    }
  }
]
