feature "deleting a badge" do
  context "as a professor" do
    let(:course) { build :course, has_badges: true}
    let!(:course_membership) { create :course_membership, :professor, user: professor, course: course }
    let(:professor) { create :user }
    let!(:badge) { create :badge, name: "Fancy Badge", course: course}

    before(:each) do
      login_as professor
      visit badges_path
    end

    scenario "successfully" do
      within(".pageContent") do
        click_link "Delete"
      end

      expect(page).to have_notification_message("notice", "Fancy Badge Badge successfully deleted")
    end
  end
end
