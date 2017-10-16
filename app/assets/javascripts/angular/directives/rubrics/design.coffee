# Main entry point for editing rubrics

@gradecraft.directive 'rubricDesign', ['$q', 'RubricService', 'BadgeService', "$timeout", ($q, RubricService, BadgeService, $timeout) ->
  RubricDesignCtrl = [()->
    vm = this

    vm.loading = true
    vm.RubricService = RubricService

    vm.termFor = BadgeService.termFor
    vm.rubric = RubricService.rubric
    vm.criteria = RubricService.criteria
    vm.full_points = RubricService.full_points
    vm.gradeWithRubric = RubricService.gradeWithRubric
    vm.copyRubricPath = RubricService.copyRubricPath

    vm.badges = BadgeService.badges

    vm.openNewCriterion = ()->
      RubricService.openNewCriterion()

    vm.hasNewCriterion = ()->
      _.filter(vm.criteria, { newCriterion: true }).length > 0

    services(vm.rubricId).then(()->
      vm.loading = false
    )
  ]

  services = (rubricId)->
    promises = [
      RubricService.getRubric(rubricId)
      BadgeService.getBadges()
    ]
    return $q.all(promises)

  {
    bindToController: true,
    controller: RubricDesignCtrl,
    controllerAs: 'vm',
    scope: {
       rubricId: "="
    },
    templateUrl: 'rubrics/design.html'
    link: (scope, el, attr)->
      $timeout( ()->
        scope.dragStart = (e, ui)->
          ui.item.data "start", ui.item.index()

        scope.dragEnd = (e, ui)->
          start = ui.item.data("start")
          end = ui.item.index()
          RubricService.updateCriterionOrder(start, end)

        $("#criterion-box").sortable(
          start: scope.dragStart
          update: scope.dragEnd
          handle: ".criterion-drag-handle"
        )
      )

      scope.reordering = false

      scope.toggleReordering = ()->
        scope.reordering = !scope.reordering

      scope.orderButtonText = ()->
        if scope.reordering
          "End Reordering Criteria"
        else
          "Reorder Criteria"
  }
]
