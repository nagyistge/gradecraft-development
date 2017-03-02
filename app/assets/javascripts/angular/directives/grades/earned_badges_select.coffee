@gradecraft.directive 'gradeEarnedBadgesSelect', ['GradeService', 'BadgeService', (GradeService, BadgeService) ->
  AwardedBadgesCtrl = [()->
    vm = this
    vm.BadgeService = BadgeService
    BadgeService.getBadges(vm.studentId)

    # Has the student currently earned this badge on this grade?
    vm.badgeIsEarnedForGrade = (badge)->
      BadgeService.studentEarnedBadgeForGrade(vm.studentId, badge.id, GradeService.grade.id)

    # Can the badge be awarded or unawarded for this grade?
    vm.badgeIsActionable = (badge)->
      badge.available_for_student || vm.badgeIsEarnedForGrade(badge)

    # Can the badge be awarded for this grade?
    vm.badgeIsAwardable = (badge)->
      badge.available_for_student && !vm.badgeIsEarnedForGrade(badge)

    vm.awardBadge = (badge)->
      return if !vm.badgeIsActionable(badge)
      if earnedBadge = vm.badgeIsEarnedForGrade(badge)
        BadgeService.deleteEarnedBadge(earnedBadge)
        badge.available_for_student = true
      else
        BadgeService.createEarnedBadge(badge.id, vm.studentId, GradeService.grade.id)
  ]

  {
    bindToController: true,
    controller: AwardedBadgesCtrl,
    controllerAs: 'vm',
    scope: {
      studentId: '@'
    },
    templateUrl: 'grades/earned_badges_select.html'
  }
]

