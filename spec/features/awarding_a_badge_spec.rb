feature "awarding a badge" do
  context "as a professor" do
    let(:professor) { create :user, courses: [course], role: :professor }
    let!(:badge) { create :badge, name: "Fancy Badge", course: course, state: "accepted"}
    let!(:student) { build :user, first_name: "Hermione", last_name: "Granger", courses: [course], role: :student }

    before(:each) do
      login_as professor
    end

    context "with an active course" do
      let(:course) { build :course, has_badges: true, status: true }

      scenario "is successful" do
        visit badges_path

        within(".pageContent") do
          click_link "Award"
        end

        expect(current_path).to eq new_badge_earned_badge_path(badge)

        within(".pageContent") do
          select "Hermione Granger", from: "earned_badge_student_id"
          click_button "Award Badge"
        end
        expect(page).to have_notification_message("notice", "The Fancy Badge Badge was successfully awarded to Hermione Granger")
      end
    end

    context "with an inactive course" do
      let(:course) { build :course, has_badges: true, status: false }

      scenario "is unsuccessful" do
        visit badges_path

        expect(page).to_not have_selector(:link_or_button, "/^Award$/")
      end
    end
  end
end
