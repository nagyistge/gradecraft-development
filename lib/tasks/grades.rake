namespace :grades do

  desc "Set all grades that have a status as being instructor_modified"

  task update_instructor_modified: :environment do
    puts "Setting grades as 'instructor_modified where a status exists..."
    total_updated = Grade.where("status is not null").update_all(instructor_modified: true)
    puts "Updated #{total_updated} grades with instructor_modified: true"
    puts "DONE"
  end

  desc "Update all of the graded_at dates to the updated_at for the grades"
  task update_graded_at: :environment do
    Grade.where("(predicted_score > 0 OR predicted_score IS NULL) AND graded_at IS NULL").update_all("graded_at=updated_at")
  end

  desc "Update grades without a final score to use raw score"
  task update_final_score: :environment do
    Grade.where("final_score is NULL and raw_score is not NULL").update_all("final_score=raw_score")
  end

  desc "Transfer the predictions off existing grades"
  task transfer_predictions: :environment do
    Grade.where("predicted_score > 0").find_each(batch_size: 500) do |grade|
      prediction = PredictedEarnedGrade.find_or_create_by(
        assignment_id: grade.assignment.id,
        student_id: grade.student.id
      )
      prediction.predicted_points = grade.predicted_score
      prediction.save
    end
  end

  namespace :remove_empty_grades do
    desc "Deletes any grade that has a predicted score greater than 0"
    task delete_predicted_grades: :environment do
      grades = Grade.where("predicted_score > 0")
      puts "Deleting #{pluralize grades.count, "predicted grade"}..."
      grades.destroy_all
    end

    desc "Deletes any grade without raw points or feedback"
    task delete_empty_grades: :environment do
      grades = Grade.where(raw_points: nil, feedback: nil)
      puts "Deleting #{pluralize grades.count, "empty grade"}..."
      grades.destroy_all
    end
  end
end
