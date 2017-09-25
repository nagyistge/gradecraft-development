@gradecraft.directive 'studentBadgeIndex', ['$q', 'BadgeService', 'StudentPanelService', ($q, BadgeService, StudentPanelService) ->
  BadgeCtrlr = [()->
    vm = this

    vm.loading = true
    vm.badges = BadgeService.badges

    vm.termFor = (term)->
      BadgeService.termFor(term)

    vm.changeFocusArticle = (article)->
      StudentPanelService.changeFocusArticle(article)

    vm.isFocusArticle = (article)->
      StudentPanelService.isFocusArticle(article)

    services().then(()->
      vm.loading = false
      StudentPanelService.changeFocusArticle(vm.badges[0])
    )
  ]

  services = ()->
    promises = [BadgeService.getBadges(null, "accepted")]
    return $q.all(promises)

  {
    bindToController: true,
    controller: BadgeCtrlr,
    controllerAs: 'vm',
    restrict: 'EA',
    scope: {
      studentId: "="
    },
    templateUrl: 'badges/student_index.html'
  }
]
