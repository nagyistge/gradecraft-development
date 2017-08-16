# Collective Service for managing state in the predictor page.  Acts as a single
# points of control for AssignmentTypes, Assignments, Badges, and Challenges
# Includes calculations for summing points that involve cross-model interaction

@gradecraft.service 'PredictorService', ['GradeCraftAPI', 'GradeSchemeElementsService', 'AssignmentTypeService', 'AssignmentService', 'BadgeService', 'ChallengeService', (GradeCraftAPI, GradeSchemeElementsService, AssignmentTypeService, AssignmentService, BadgeService, ChallengeService) ->

  update = {}

  termFor = (article)->
    GradeCraftAPI.termFor(article)


  #------ GRADE SCHEME ELEMENTS -----------------------------------------------#

  gradeSchemeElements = GradeSchemeElementsService.gradeSchemeElements

  totalPoints = ()->
    GradeSchemeElementsService.totalPoints()

  getGradeSchemeElements = ()->
    GradeSchemeElementsService.getGradeSchemeElements()

  #------ ASSIGNMENT TYPES ----------------------------------------------------#

  assignmentTypes = AssignmentTypeService.assignmentTypes
  weights = AssignmentTypeService.weights

  getAssignmentTypes= ()->
    AssignmentTypeService.getAssignmentTypes()

  unusedWeightsRange = ()->
    AssignmentTypeService.unusedWeightsRange()

  weightsAvailable = ()->
    AssignmentTypeService.weightsAvailable()

  weightedEarnedPoints = (assignmentType)->
    AssignmentTypeService.weightedEarnedPoints(assignmentType)

  weightedPoints = (assignmentType, total)->
    AssignmentTypeService.weightedPoints(assignmentType, total)

  #------ ASSIGNMENT TYPE CALCULATIONS USING ASSIGNMENTS ----------------------#

  # Filter the assignments, return just the assignments for the assignment type
  assignmentsForAssignmentType = (assignments,id)->
    _.where(assignments, {assignment_type_id: id})

  # Used to avoid rendering an assignment type if it contains no assignments
  assignmentTypeHasAssignments = (assignmentType)->
    assignmentsForAssignmentType(assignments,assignmentType.id).length > 0

  # Total points predicted for all assignments by assignments type
  # Additional boolean params to include Weights, Caps and Predicted Points
  assignmentTypePointTotal = (assignmentType, includeWeights, includeCaps, includePredicted)->
    if includePredicted
      subset = assignmentsForAssignmentType(assignments,assignmentType.id)
      total = AssignmentService.assignmentsSubsetPredictedPoints(subset)
    else
      total = assignmentType.final_points_for_student

    if includeWeights
      total = weightedPoints(assignmentType, total)
    if assignmentType.is_capped and includeCaps
      total = if total > assignmentType.total_points then assignmentType.total_points else total
    total

  assignmentsWeightedPredictedPoints = ()->
    total = 0
    _.each(assignmentTypes, (assignmentType)->
      total += assignmentTypePointTotal(assignmentType, true, false, true)
    )
    total

  # Total predicted points above and beyond the assignment type max points
  assignmentTypePointExcess = (assignmentType)->
    if assignmentType.is_capped
      assignmentTypePointTotal(assignmentType, true, false, true) - assignmentType.total_points
    else
      0

  assignmentTypeAtMaxPoints = (assignmentType)->
    if assignmentTypePointExcess(assignmentType) > 0
      return true
    else
      return false

  #------ ASSIGNMENTS ---------------------------------------------------------#

  assignments = AssignmentService.assignments

  getAssignments= ()->
    AssignmentService.getAssignments()

  #------ BADGES --------------------------------------------------------------#

  badges = BadgeService.badges

  getBadges = (studentId)->
    BadgeService.getBadges(studentId)

  badgesPredictedPoints = ()->
    BadgeService.badgesPredictedPoints()

  #------ CHALLENGES ----------------------------------------------------------#

  challenges = ChallengeService.challenges

  getChallenges= ()->
    ChallengeService.getChallenges()

  challengesFullPoints = ()->
    ChallengeService.challengesFullPoints()

  challengesPredictedPoints = ()->
    ChallengeService.challengesPredictedPoints()

  #------ ALL ARTICLE TYPES (ASSIGNMENT, CHALLENGE, BADGE) --------------------#

  # return true if there is nothing left to do for this article
  articleCompleted = (article)->
    if article.type == "badges"
      return ! article.can_earn_multiple_times && article.earned_badge_count > 0
    if article.is_closed_without_submission == true
      return true
    if article.is_closed_by_condition == true
      return true
    if article.grade.score == null
      return false
    else
      return true

  # return true if complete and doesn't count towards final score
  articleNoPoints = (article)->
    # Always treats badges as if they "count"
    return false if article.type == "badges"
    return true if article.grade.is_excluded
    return true if article.grade.pass_fail_status == "Fail"
    return false if article.grade.pass_fail_status == "Pass"
    return false if article.grade.score > 0
    return true if article.grade.score == 0 ||
      article.is_closed_without_submission == true ||
      article.is_closed_by_condition == true
    return false

  # Total points predicted for all assignments, badges, and challenges
  allPointsPredicted = ()->
    total = 0
    _.each(assignmentTypes, (assignmentType)->
        total += assignmentTypePointTotal(assignmentType,true,true,true)
      )
    total += badgesPredictedPoints()
    total += challengesPredictedPoints()
    total

  lockedPointsPredicted = ()->
    subset = _.where(assignments, {is_locked: true})
    total = AssignmentService.assignmentsSubsetPredictedPoints(subset)

  # Total points actually earned to date
  allPointsEarned = ()->
    total = 0
    _.each(assignmentTypes, (assignmentType)->
        total += assignmentTypePointTotal(assignmentType,true,true,false)
      )
    _.each(badges,(badge)->
        # disregard for generic predictor
        if badge.total_earned_points
          total += badge.total_earned_points
      )
    _.each(challenges,(challenge)->
        total += challenge.grade.score
      )
    total

  # Returns human readable Predicted Grade Scheme Element
  predictedGradeLevel = ()->
    allPoints = allPointsPredicted()
    predictedGrade = null
    _.each(gradeSchemeElements,(gse)->
      if allPoints >= gse.lowest_points
        if ! predictedGrade || predictedGrade.lowest_points < gse.lowest_points
          predictedGrade = gse
    )
    if predictedGrade
      letterGrade = if predictedGrade.letter then " (" + predictedGrade.letter + ")" else ""
      return predictedGrade.level + letterGrade
    else
      return ""


  #------ API CALLS -----------------------------------------------------------#

  # Agnostic call to update any article that has a nested prediction.
  postPredictedArticle = (article)->
    switch article.type
      when "assignments" then AssignmentService.postPredictedAssignment(article)
      when "badges"      then BadgeService.postPredictedBadge(article)
      when "challenges"  then ChallengeService.postPredictedChallenge(article)

  return {
      termFor: termFor
      totalPoints: totalPoints
      articleCompleted: articleCompleted
      articleNoPoints: articleNoPoints
      postPredictedArticle: postPredictedArticle
      allPointsPredicted: allPointsPredicted
      lockedPointsPredicted: lockedPointsPredicted
      allPointsEarned: allPointsEarned
      predictedGradeLevel: predictedGradeLevel

      getGradeSchemeElements: getGradeSchemeElements
      gradeSchemeElements: gradeSchemeElements

      assignmentTypes: assignmentTypes
      getAssignmentTypes: getAssignmentTypes
      assignmentTypeHasAssignments : assignmentTypeHasAssignments
      assignmentTypePointTotal : assignmentTypePointTotal
      assignmentTypePointExcess : assignmentTypePointExcess
      assignmentTypeAtMaxPoints : assignmentTypeAtMaxPoints

      weights: weights
      weightsAvailable: weightsAvailable
      unusedWeightsRange: unusedWeightsRange
      weightedEarnedPoints: weightedEarnedPoints
      weightedPoints: weightedPoints

      assignments: assignments
      getAssignments: getAssignments

      badges: badges
      getBadges: getBadges
      badgesPredictedPoints: badgesPredictedPoints

      challenges: challenges
      getChallenges: getChallenges
      challengesFullPoints: challengesFullPoints
      challengesPredictedPoints: challengesPredictedPoints
  }
]
