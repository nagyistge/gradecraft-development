feature "editing an awarded a badge" do
  context "as a professor" do
    let(:professor) { create :user, courses: [course], role: :professor }
    let!(:badge) { create :badge, name: "Fancy Badge", course: course, state: "accepted"}
    let(:student) { build :user, first_name: "Hermione", last_name: "Granger", courses: [course], role: :student }
    let(:student_2) { build :user, first_name: "Ron", last_name: "Weasley", courses: [course], role: :student }
    let!(:earned_badge) { create :earned_badge, badge: badge, student: student}

    before(:each) do
      login_as professor
    end

    context "with an active course" do
      let(:course) { build :course, has_badges: true, status: true }

      scenario "is successful" do
        visit edit_badge_earned_badge_path(badge, earned_badge)

        within(".pageContent") do
          click_button "Update Badge"
        end

        expect(current_path).to eq badge_path(badge.id)

        expect(page).to have_notification_message(
          "notice",
          "Hermione Granger's Fancy Badge Badge was successfully updated"
        )
      end
    end

    context "with an inactive course" do
      let(:course) { build :course, has_badges: true, status: false }

      scenario "is unsuccessful" do
        visit badge_path(badge)

        within(".pageContent") do
          expect(page).to_not have_selector(:link_or_button, "Edit")
        end
      end
    end
  end
end
