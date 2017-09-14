feature "awarding many earned badges at once" do
  context "as a professor" do
    let(:professor) { create :user, courses: [course], role: :professor }
    let!(:badge) { create :badge, name: "Fancy Badge", course: course, state: "accepted"}
    let!(:student) { build :user, first_name: "Hermione", last_name: "Granger", courses: [course], role: :student }
    let!(:student_2) { build :user, first_name: "Ron", last_name: "Weasley", courses: [course], role: :student }

    before(:each) do
      login_as professor
      visit badges_path
    end

    context "with an active course" do
      let(:course) { build :course, has_badges: true, status: true }

      scenario "is successful" do
        within(".pageContent") do
          click_link "Quick Award"
        end

        expect(current_path).to eq mass_edit_badge_earned_badges_path(badge)

        within(".pageContent") do
          find(:css, "#student-id-#{student.id}").set(true)
          find(:css, "#student-id-#{student_2.id}").set(true)
          click_button "Award"
        end
        expect(page).to have_notification_message("notice", "The Fancy Badge Badge was successfully awarded 2 times")
      end
    end

    context "with an inactive course" do
      let(:course) { build :course, has_badges: true, status: false }

      scenario "is unsuccessful" do
        expect(page).to_not have_selector(:link_or_button, "Quick Award")
      end
    end
  end
end
