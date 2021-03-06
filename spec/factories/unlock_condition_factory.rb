FactoryGirl.define do
  factory :unlock_condition do
    association :unlockable, factory: :badge
    unlockable_type "Badge"
    association :condition, factory: :assignment
    condition_type "Assignment"
    condition_state "Earned"

    factory :unlock_condition_for_assignment do
      association :unlockable, factory: :assignment
      unlockable_type "Assignment"
    end

    factory :unlock_condition_for_gse do
      association :unlockable, factory: :grade_scheme_element
      unlockable_type "GradeSchemeElement"
    end
  end
end
