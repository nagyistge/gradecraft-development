describe Analytics::BadgeAnalytics do
  let(:badge) { create :badge, full_points: 100 }
  let(:student) { create :user }
  let!(:earned_badge) { create(:earned_badge, badge: badge, student: student, updated_at: 8.days.ago) }
  let!(:second_earned_badge) { create(:earned_badge, badge: badge, student: student) }
  let!(:third_earned_badge) { create(:earned_badge, badge: badge) }


  describe "#earned_count" do
    it "returns the count of earned badges that have been awarded" do
      expect(badge.earned_count).to eq(3)
    end

    it "does not include earned badges that are not student visible in the count" do
      earned_badge_not_visible = create(:earned_badge, badge: badge, grade: create(:in_progress_grade))
      expect(badge.earned_count).to eq(3)
    end

    describe "#earned_badge_total_points_for_student" do
      it "sums up the total points earned for a specific badge" do
        expect(badge.earned_badge_total_points_for_student(student)).to eq(200)
      end
    end

    describe "#earned_badges_this_week_count" do
      it "returns the count of submissions for this assignment type this week" do
        expect(badge.earned_badges_this_week_count).to eq(2)
      end
    end
  end
end
