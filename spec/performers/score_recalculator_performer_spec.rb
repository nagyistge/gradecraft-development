RSpec.describe ScoreRecalculatorPerformer, type: :background_job do
  let(:student) { create(:user) }
  let(:course) { create(:course) }
  let(:attrs) {{ user_id: student[:id], course_id: course[:id] }}
  let(:performer) { ScoreRecalculatorPerformer.new(attrs) }
  subject { ScoreRecalculatorPerformer.new(attrs) }

  describe "public methods" do
    describe "setup" do
      it "should fetch the student and set it to student" do
        expect(subject).to receive(:fetch_student).and_return student
        subject.setup
        expect(subject.instance_variable_get(:@student)).to eq(student)
      end
    end

    describe "do_the_work" do
      subject { performer.do_the_work }
      context "both course and student present" do
        let(:cache_score_result) { double(:cache_score_result) }

        it "should require success" do
          expect(performer).to receive(:require_success)
          subject
        end

        it "should add an outcome to subject.outcomes" do
          expect { performer.do_the_work }.to change { performer.outcomes.size }.by(1)
          subject
        end

        it "should return the result of update_course_score_and_level" do
          allow(student).to receive(:update_course_score_and_level).with(course.id) { cache_score_result }
          expect(performer).to receive(:require_success).and_return(cache_score_result)
          subject
        end

        describe "require success outcome messages" do
          subject { performer.outcome_messages.first }
          let(:student_double) { double(:student) }
          before(:each) do
            @performer = performer
            @student = student
            allow(@performer).to receive_messages(fetch_student: student_double)
            @performer.instance_variable_set(:@student, @student)
          end

          context "block outcome fails" do
            it "should add the :failure outcome message to @outcome_messages" do
              allow(@student).to receive(:update_course_score_and_level) { false }
              @performer.do_the_work
              expect(@performer.outcome_messages.first).to match("Failed to cache student")
            end
          end

          context "block outcome succeeds" do
            it "should add the :succeeds outcome message to @outcome_messages" do
              allow(@student).to receive(:update_course_score_and_level) { true }
              @performer.do_the_work
              expect(@performer.outcome_messages.last).to match("Successfully cached student")
            end
          end
        end
      end
    end
  end

  # private methods

  describe "private methods" do
    describe "fetch_student" do
      subject { performer.instance_eval{fetch_student} }
      it "should fetch the student" do
        expect(subject).to eq(student)
      end

      it "should find the course by id" do
        expect(User).to receive(:find).with(student[:id]) { course }
        performer
      end
    end

    describe "messages" do
      subject { performer.instance_eval{messages} }
      it "should have a success message" do
        expect(subject[:success]).to match("Successfully cached student")
      end

      it "should have a failure message" do
        expect(subject[:failure]).to match("Failed to cache student")
      end
    end
  end
end
