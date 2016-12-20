class RemovePredictedScoreFromGrades < ActiveRecord::Migration[5.0]
  def change
    remove_column :grades, :predicted_score
  end
end
