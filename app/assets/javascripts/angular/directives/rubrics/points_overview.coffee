# Hovering synopsis of the rubric points assigned

@gradecraft.directive 'rubricPointsOverview', ['RubricService', (RubricService) ->

  return {
    templateUrl: 'rubrics/points_overview.html'
    link: (scope, el, attr)->

      scope.fullPoints = ()->
        RubricService.fullPoints()

      scope.pointsAssigned = ()->
        RubricService.pointsAssigned()

      scope.pointsRemaining = ()->
        RubricService.fullPoints() - RubricService.pointsAssigned()

      scope.pointsAreSatisfied = ()->
        RubricService.fullPoints() == RubricService.pointsAssigned()

      scope.pointsAreMissing = ()->
        RubricService.fullPoints() > RubricService.pointsAssigned()

      scope.pointsAreOver = ()->
        RubricService.fullPoints() < RubricService.pointsAssigned()
  }
]

