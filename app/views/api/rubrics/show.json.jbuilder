json.data do
  json.type "rubrics"
  json.id   @rubric.id.to_s

  json.attributes do
    json.id                         @rubric.id
    json.assignment_id              @rubric.assignment_id
  end

  json.relationships do
    json.criteria do
      json.data @criteria do |criterion|
        json.type "criteria"
        json.id criterion.id.to_s
      end
    end
  end
end

json.included do
  json.array! @criteria do |criterion|
    json.partial! 'api/criteria/criterion', criterion: criterion
  end
  json.array! @levels do |level|
    json.partial! 'api/levels/level', level: level
  end
end

json.meta do
  json.full_points @rubric.assignment.full_points
  json.grade_with_rubric @rubric.assignment.grade_with_rubric?
  json.copy_rubric_path index_for_copy_assignment_rubrics_path @rubric.assignment
end
