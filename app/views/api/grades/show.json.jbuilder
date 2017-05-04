json.data do
  json.partial! 'api/grades/grade', grade: @grade
end

json.included do
  if @grade.file_uploads.present?
    json.array! @grade.file_uploads do |file_upload|
      json.type "file_uploads"
      json.id file_upload.id.to_s
      json.attributes do
        json.id file_upload.id
        json.grade_id file_upload.grade_id
        json.filename file_upload.filename
        json.filepath file_upload.filepath
        json.file_processing file_upload.file_processing
      end
    end
  end

  if @grade.criterion_grades.present?
    json.array! @grade.criterion_grades do |criterion_grade|
      json.type "criterion_grades"
      json.id criterion_grade.id.to_s
      json.attributes do
        json.id             criterion_grade.id
        json.grade_id       criterion_grade.grade_id
        json.assignment_id  criterion_grade.assignment_id
        json.points         criterion_grade.points
        json.criterion_id   criterion_grade.criterion_id
        json.level_id       criterion_grade.level_id
        json.student_id     criterion_grade.student_id
        json.comments       criterion_grade.comments
      end
    end
  end
end

json.meta do
  json.grade_status_options @grade_status_options if @grade_status_options
  json.threshold_points     @grade.assignment.threshold_points
  json.is_rubric_graded     @grade.assignment.grade_with_rubric?
  json.has_awardable_badges @grade.course.has_badges?
end
