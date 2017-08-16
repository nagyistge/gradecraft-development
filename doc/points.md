# Points, Scores, Values

*note many of these changes are in progress, I will update this file once they have been merged into Production -jg*

Points, Score, and Value nomenclature in Gradecraft has been standardized around the following rules:

## Points

Throughout GradeCraft, in most cases integer values stored on models are referred to as `points`.

### `points`

`AssignmentScoreLevels`, `ChallengeScoreLevels`, `CriterionGrades`, `EarnedBadges`, and `Levels` all have a single stored integer value called `points`.

### `full_points`

The `full_points` column exists on  `Courses`, `Assignments`, `Badges`, `Challenges`, and `Grades`. It represents a perfect grade for that model. This is different from `max_points` in that it is possible to exceed the full points.

### `max_points`

The `max_points` column exists on `AssignmentTypes` and `Criteria`, and indicates that the points for this model is capped to not exceed this amount.

### points on [[Assignment Types]]

  * `max_points` - the maximum points obtainable for that assignment type

### points on [[Assignments]]

  * `full_points` - numeric representation of a perfect grade for the assignment
  * `threshold_points` - A grade with fewer points than the threshold for the assignment will have a final score of `0`

### points on [[Challenges]]

  * `full_points` - numeric representation of a perfect grade for the challenge

### points on [[Grades]]

`full_points` is also stored on a grade. Without [[weighting | Weights]], it is the same as the `assignment.full_points`. In courses with [[weights | Weights]], it is the `assignment.full_points` multiplied by the student's weight for the assignment.

Grades also have the following columns:

  * `raw_points` - the initial points awarded to a student for completing an assignment
  * `adjustment_points` - points added or subtracted from the `raw_points`, an explanation for the adjustment is stored in `adjustment_points_feedback`
  * `final_points` - points after calculating adjustment and threshold

## points on [[Criteria | Criterion Grades]]

  * `max_points` - the maximum points assignable for the criteria, the `full_credit_level.points`
  * `meets_expectations_points`, the points needed to achieve `meets_expectations`, the `meets_expectations_level.points`

## Scores

The term `score` in Gradecraft is used sparingly, to describe an calculated accumulation of points. It only exists on three models:

  * `Grade.score` - the final calculation of points on a Grade
  * `Challenge.score` - the final calculation of points on a Challenge
  * `CourseMembership.score` - the final calculation of points on a Course for a student

Grades also have a boolean `included_in_course_score`, which when set to false will ignore that Grade when summing the Course score.

### calculating a `Grade` score

A student's score for a completed `Assignment` is stored on a `Grade`, and it is calculated as follows:

If there is no `raw_points`, the score will always be nil.

The `final_points` is the `raw_points` + `adjustment_points`

Without a threshold or weights, the `score` will be the same as the `final_points`:

```
score = raw_points + adjustment_points
```

If the assignment has `threshold_points`, and the `final_points` are less than the threshold, the `score` will be `0`

If there is a [[weight | Weights]] on the assignment, the `score` will be the `final_points` multiplied by the student's weight for the assignment:

```
score = (raw_points + adjustment_points) * weight
```

### calculating a `ChallengeGrade` score

A team's score for a completed `Challenge` is stored on a `ChallengeGrade`. Currently a `ChallengeGrade` is not as full-featured as a Grade. There are no weights or thresholds, for instance.

The `final_points` is the `raw_points` + `adjustment_points`

The `score` will always be the same as the `final_points`

### calculating a `Course` score

A student's score for the entire course is stored on the `CourseMembership`, and is calculated as follows:

(1)Student visible `Grade` scores are summed for each `AssignmentType`, capped at the `AssignmentType.max_points`

(2)Student `EarnedBadges` points are summed

(3)Student's team's Challenge grades are summed

-----

(1) + (2) + (3) = student's score for course

The callback stack (which should be re-factored ) that recalculates the course score, looks like this (as of 8/16/17):

    action : grade.destroy || enqueue GradeUpdaterJob > GradeUpdatePerformer
    ------------------------------------------------------------------------
    Grade.update_student_and_team_scores
      V
    User#update_course_score_and_level
      V
    CourseMembership#recalculate_and_update_student_score
      v
      #recalculated_student_score
        v
      #assignment_type_totals_for_student ( + #student_earned_badge_score + #conditional_student_team_score )
        V
    AssignmentType#visible_score_for_student
      v
      #summed_highest_scores_for || #max_points_for_student || #score_for_student
      v
      (some variation of: visible Grades pluck "score" and sum)

### predicted scores

Students make predictions for their final scores for each `Assignment` and `Challenge`. These are stored on prediction models as `predicted_score`

### score-levels

Challenges and Assignments have associated models `challenge_score_levels` and `grade_score_levels` which represent set levels for final `Grade` and `ChallengeGrade` points. When `is_custom_value` is true on a `Grade`, a custom `raw_points` is used instead.

These models don't conform to the standardized use of `score` and `value`, but have been left as-is for now, pending a possible change in the workflow.

One possibility would be to remove this feature and replace it with a rubric with a single criterion, and override with `points_adjustment` as we do with a standard rubric.

## Value

The term `value` has been removed from use in Gradecraft, except where is represents a generic value, for instance, key/value stores.

There are two places in the schema were `value` is still used:

### `condition_value`

`UnlockConditions.condition_value` represents `points` for assignment, and `times_earned` for a badge.

### `is_custom_value`

`Grades.is_custom_value` is a situation where a level selection is in place for a grade that has been overridden. It is a strange enough outlier that we have left the name alone for now. Hopefully this will be [handled in a different way in the future](#score-levels)

## All Related Columns:

```
assignment_types
  * max_points

assignments
  * points_predictor_display => remove
  * threshold_points
  * full_points

assignment_score_levels
 * points

badges
  * points

challenges
  * points_predictor_display => remove
  * full_points

challenge_score_levels
 * points

courses
 * full_points

criteria
  * max_points
  * meets_expectations_points

criterion_grades
  * points

earned_badges
  points

grade_scheme_elements
  * low_points
  * high_points

grades
  * raw_points
  * final_points
  * score
  * full_points
  * predicted_score => remove (after running rake task for transfer)
  * adjustment_points
  * excluded_from_course_score

levels
  * points

predicted_earned_challenges
  * predicted_points

predicted_earned_grades
  * predicted_points

users
  final_grade => remove (along with other fields on user)

assignment_score_levels
  * points
