feature "editing a challenge" , focus: true do
  context "as a professor" do
    let(:course) { build :course, has_team_challenges: true}
    let!(:course_membership) { create :course_membership, :professor, user: professor, course: course }
    let(:professor) { create :user }
    let!(:challenge) { create :challenge, name: "Section Challenge Name", course: course }

    before(:each) do
      login_as professor
      visit edit_challenge_path(challenge)
    end

    scenario "successfully" do
      within(".pageContent") do
        fill_in "Name", with: "Edited Section Challenge Name"
        click_button "Update Section Challenge"
      end

      expect(page).to have_notification_message("notice", "Challenge Edited Section Challenge Name successfully updated")
    end
  end
end
