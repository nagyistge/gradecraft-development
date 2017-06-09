describe AssignmentAnalytics do
  subject { build(:assignment) }

  describe "#average" do
    before { subject.save }

    it "returns the average raw score for a graded grade" do
      subject.grades.create student_id: create(:user).id, raw_points: 8, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_points: 5, status: "Graded"
      expect(subject.average).to eq 6
    end

    it "returns nil if there are no grades" do
      expect(subject.average).to be_nil
    end
  end

  describe "#earned_average" do
    before { subject.save }

    it "returns the average score for a graded grade" do
      subject.grades.create student_id: create(:user).id, raw_points: 8, score: 8, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_points: 5, score: 8, status: "Graded"
      expect(subject.earned_average).to eq 6
    end

    it "returns 0 if there are no grades" do
      expect(subject.earned_average).to be_zero
    end
  end

  describe "#earned_score_count" do
    before { subject.save }

    it "returns only graded or released grades" do
      subject.grades.create student_id: create(:user).id
      expect(subject.earned_score_count).to be_empty
    end

    it "returns the number of unique scores for each grade" do
      subject.grades.create student_id: create(:user).id, raw_points: 85, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_points: 85, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_points: 105, status: "Graded"
      expect(subject.earned_score_count).to eq({ 85 => 2, 105 => 1 })
    end
  end

  describe "#median" do
    before { subject.save }

    it "returns the median score for a graded grade" do
      subject.grades.create student_id: create(:user).id, raw_points: 8, score: 8, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_points: 5, score: 8, status: "Graded"
      expect(subject.median).to eq 6
    end

    it "returns 0 if there are no grades" do
      expect(subject.median).to be_zero
    end
  end

  describe "#high_score" do
    before { subject.save }

    it "returns the maximum raw score for a graded grade" do
      subject.grades.create student_id: create(:user).id, raw_points: 8, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_points: 5, status: "Graded"
      expect(subject.high_score).to eq 8
    end
  end

  describe "#low_score" do
    before { subject.save }

    it "returns the minimum raw score for a graded grade" do
      subject.grades.create student_id: create(:user).id, raw_points: 8, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_points: 5, status: "Graded"
      expect(subject.low_score).to eq 5
    end
  end

  describe "#predicted_count" do
    it "returns the number of grades that are predicted to have a score greater than zero" do
      predicted_earned_grades = double(:predicted_earned_grades, predicted_to_be_done: 43.times.to_a)
      allow(subject).to receive(:predicted_earned_grades).and_return predicted_earned_grades
      expect(subject.predicted_count).to eq 43
    end
  end

  describe "#grade_count" do
    before { subject.save }

    it "counts the number of grades that were graded or released" do
      subject.grades.create student_id: create(:user).id, raw_points: 85, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_points: 85, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_points: 105
      expect(subject.grade_count).to eq 2
    end
  end

  describe "#graded_or_released_scores" do
    before { subject.save }

    it "returns an array raw graded scores" do
      subject.grades.create student_id: create(:user).id, raw_points: 85, status: "Graded"
      expect(subject.graded_or_released_scores).to eq([85])
    end
  end
end