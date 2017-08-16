require "./db/samples/courses.rb"
require "./db/samples/badges.rb"
require "./db/samples/assignment_types.rb"
require "./db/samples/assignments.rb"
require "./db/samples/challenges.rb"
require "./db/samples/events.rb"
require "./db/samples/announcements.rb"

# ---------------------------- Shared Methods --------------------------------#

# Output quotes for each successful step passed
# rubocop:disable Eval
def puts_success(type, name, event)
  puts eval("@#{type}s")[name][:quotes][event] ||
    eval("@#{type}_default_config")[:quotes][event] + ": #{name}"
end

def add_unlock_conditions(model, config, course_config)
  # Skip Badge unlock conditions on courses without badges
  unless !course_config[:attributes][:has_badges] &&
    config[:unlock_attributes][:condition_type] == "Badge"

    model.unlock_conditions.create! do |uc|
      if config[:unlock_attributes][:condition_type] == "Assignment"
        uc.condition =
          course_config[:assignments][config[:unlock_attributes][:condition]]
      elsif config[:unlock_attributes][:condition_type] == "Badge"
        uc.condition =
          course_config[:badges][config[:unlock_attributes][:condition]]
      end
      uc.condition_type = config[:unlock_attributes][:condition_type]
      uc.condition_state = config[:unlock_attributes][:condition_state]
      uc.condition_date = config[:unlock_attributes][:condition_date]
    end
  end
end

def create_groups(course_name, assignment)
  group_names = ["The Clique", "The Cabal", "The Household", "The Community",
    "The Posse", "The Squad"].shuffle

  group_members = group_names.each_with_object({}) do |name, memo|
    memo[name] = []
  end
  @students.each_with_index do |student, i|
    group_members[group_names[i%group_names.length]] << student
  end

  groups = group_names.map do |group_name|
    assignment.course.groups.create! do |g|
      g.name = group_name
      g.approved = "Approved"
      g.assignments << assignment
      g.students << group_members[group_name]
    end
  end
  @courses[course_name][:groups] = groups
end

# ---------------------------- Institutions -----------------------------#

puts "Constructing Hogwarts School of Witchcraft and Wizardry..."
hogwarts = Institution.create! do |i|
  i.name = "Hogwarts"
  i.has_site_license = true
end

puts "Constructing Beauxbatons Academy of Magic..."
Institution.create! do |i|
  i.name = "Beauxbatons"
end

# ---------------------------- Users and Courses -----------------------------#

user_names = ["Ron Weasley","Fred Weasley","Harry Potter","Hermione Granger",
  "Colin Creevey","Seamus Finnigan","Hannah Abbott","Pansy Parkinson",
  "Zacharias Smith","Blaise Zabini", "Draco Malfoy", "Dean Thomas",
  "Millicent Bulstrode", "Terry Boot", "Ernie Macmillan","Roland Abberlay",
  "Katie Bell", "Regulus Black", "Euan Abercrombie", "Brandon Angel"]

majors = ["Engineering","American Culture","Anthropology","Asian Studies",
  "Astronomy","Cognitive Science","Creative Writing and Literature",
  "English","German","Informatics","Linguistics","Physics"]

pseuydonyms = ["Bigby Wolf", "Snow White", "Beauty", "the Beast", "Trusty John",
  "Grimble", "Bufkin", "Prince Charming", "Cinderella", "Old King Cole",
  "Hobbes", "Pinocchio", "Briar Rose", "Doctor Swineheart", "Rapunzel", "Kay",
  "Mrs. Sprat", "Frau Totenkinder", "Ozma", "Great Fairy Witch","Maddy",
  "Mr. Grandours", "Mrs. Someone", "Prospero", "Mr. Kadabra","Geppetto",
  "Morgan le Fay","Rose Red","Boy Blue","Weyland Smith","Reynard the Fox",
  "Brock Blueheart","Peter Piper","Bo Peep","The Adversary","Goldilocks",
  "Bluebeard","Ichabod Crane","Baba Yaga","The Snow Queen","Rodney", "June",
  "Hansel", "The Nome King", "Max Piper", "Mister Dark", "Fairy Godmother",
  "Dorothy Gale", "Hadeon the Destroyer", "Prince Brandish"]

# Generate sample admin
User.create! do |u|
  u.username = "albus"
  u.first_name = "Albus"
  u.last_name = "Dumbledore"
  u.email = "dumbledore@hogwarts.edu"
  u.password = "fawkes"
  u.admin = true
  u.save!
end.activate!
puts "Children must be taught how to think, not what to think. ― Margaret Mead"

# Iterate through course names and create courses
@courses.each do |course_name, config|
  course = Course.create! do |c|
    @course_default_config[:attributes].keys.each do |attr|
      c[attr] =
        config[:attributes].key?(attr) ? config[:attributes][attr] :
          @course_default_config[:attributes][attr]
    end

    # Add weight attributes if course has weights
    if config[:attributes][:total_weights] &&
        (config[:attributes][:total_weights] > 1)
      config[:attributes][:weight_attributes].keys.each do |weight_attr|
        c[weight_attr] = config[:attributes][:weight_attributes][weight_attr]
      end
      puts_success :course, course_name, :weights_created
    end

    # Assign courses to Hogwarts institution
    c.institution = hogwarts
  end

  config[:course] = course
  puts_success :course, course_name, :course_created

  # Add the grade scheme elements and level names
  grade_scheme_hash =
    config[:grade_scheme_hash] || @course_default_config[:grade_scheme_hash]
  levels = config[:grade_levels] || @course_default_config[:grade_levels]
  grade_scheme_hash.each_with_index do |(points, letter), i|
    course.grade_scheme_elements.create do |e|
      e.letter = letter
      e.level = levels[i]
      e.lowest_points = points.first
    end
  end
  puts_success :course, course_name, :grade_sceme_elements_created

  # Add the course teams if the course has teams
  if config[:attributes][:has_teams]
    team_names = config[:team_names] || @course_default_config[:team_names]
    teams = team_names.map do |team_name|
      course.teams.create! do |t|
        t.name = team_name
      end
    end
    @courses[course_name][:teams] = teams
    puts_success :course, course_name, :teams_created
  end
end

# create a hash on each course config to store assignment types and assignments
@courses.each do |name,config|
  config[:badges] = {}
  config[:assignment_types] = {}
  config[:assignments] = {}
  config[:challenges] = {}
  config[:events] = {}
  config[:announcements] = {}
end

# ---------------------------- Create Observers! ------------------------------#

puts "Generating observers..."

observer = User.create! do |u|
  u.username = "moaning.myrtle"
  u.first_name = "Myrtle"
  u.last_name = "Warren"
  u.email = "moaning.myrtle@hogwarts.edu"
  u.password = "basilisk"
  u.courses << @courses.map {|course_name,config| config[:course]}
  u.save!
end
observer.activate!
observer.course_memberships.each { |cm| cm.update_attributes(pseudonym: "Moaning Myrtle", role: "observer") }

# ---------------------------- Create Auditors! ------------------------------#
#Delphini Diggory

puts "Generating auditors..."

auditor = User.create! do |u|
  u.username = "delphini.diggory"
  u.first_name = "Delphini"
  u.last_name = "Diggory"
  u.email = "delphini.diggory@hogwarts.edu"
  u.password = "keepthesecrets"
  u.courses << @courses.map {|course_name,config| config[:course]}
  u.save!
end
auditor.activate!
auditor.course_memberships.each { |cm| cm.update_attributes(pseudonym: "Delphini Diggory", role: "student", auditing: true) }

# ---------------------------- Create Students! ------------------------------#
puts "Generating students..."

@students = user_names.map do |name|
  courses = @courses.map {|course_name,config| config[:course]}
  teams = @courses.map {|course_name,config| config[:teams].sample}

  first_name, last_name = name.split(" ")
  username = name.parameterize.sub("-",".")
  user = User.create! do |u|
    u.username = username
    u.first_name = first_name
    u.last_name = last_name
    u.email = "#{username}@hogwarts.edu"
    u.password = "uptonogood"
    u.courses << courses
  end
  user.course_memberships.each { |cm| cm.update_attributes(role: "student", pseudonym: pseuydonyms.sample) }
  user.teams << teams
  user.activate!
  print "."
  user
end
puts "Everything starts from a dot. - Kandinsky"

# ---------------------------- Create Professors! ----------------------------#

User.create! do |u|
  u.username = "mcgonagall"
  u.first_name = "Minerva"
  u.last_name = "McGonagall"
  u.email = "mcgonagall@hogwarts.edu"
  u.password = "pineanddragonheart"
  u.save!
  u.course_memberships.create! do |cm|
    cm.course = @courses[:teams_badges_points][:course]
    cm.role = "professor"
    FlaggedUser.toggle! cm.course, u, @students.sample.id
    FlaggedUser.toggle! cm.course, u, @students.sample.id
    FlaggedUser.toggle! cm.course, u, @students.sample.id
  end
end.activate!

# Generate sample professor
User.create! do |u|
  u.username = "headless_nick"
  u.first_name = "Nicholas"
  u.last_name = "de Mimsy-Porpington"
  u.email = "headless_nick@hogwarts.edu"
  u.password = "october31"
  u.save!
  u.course_memberships.create! do |cm|
    cm.course = @courses[:power_ups_locks_weighting_config][:course]
    cm.role = "professor"
    FlaggedUser.toggle! cm.course, u, @students.sample.id
    FlaggedUser.toggle! cm.course, u, @students.sample.id
    FlaggedUser.toggle! cm.course, u, @students.sample.id
  end
end.activate!

# Generate sample professor
User.create! do |u|
  u.username = "severus"
  u.first_name = "Severus"
  u.last_name = "Snape"
  u.email = "snape@hogwarts.edu"
  u.password = "lily"
  u.save!
  u.course_memberships.create! do |cm|
    cm.course = @courses[:leaderboards_team_challenges][:course]
    cm.role = "professor"
    FlaggedUser.toggle! cm.course, u, @students.sample.id
    FlaggedUser.toggle! cm.course, u, @students.sample.id
    FlaggedUser.toggle! cm.course, u, @students.sample.id
  end
end.activate!

# Generate sample GSI
User.create! do |u|
  u.username = "percy.weasley"
  u.first_name = "Percy"
  u.last_name = "Weasley"
  u.email = "percy.weasley@hogwarts.edu"
  u.password = "bestprefect"
  u.save!
  @courses.each do |name,config|
    u.course_memberships.create! do |cm|
      cm.course = config[:course]
      cm.role = "gsi"
    end
    u.team_leaderships.create! do |tm|
      tm.team_id = config[:course].teams.sample.id
    end
    FlaggedUser.toggle! config[:course], u, @students.sample.id
    FlaggedUser.toggle! config[:course], u, @students.sample.id
    FlaggedUser.toggle! config[:course], u, @students.sample.id
  end
end.activate!
puts "In learning you will teach, and in teaching you will learn. ―Phil Collins"

# Generate sample GSI
User.create! do |u|
  u.username = "cedric.diggory"
  u.first_name = "Cedric"
  u.last_name = "Diggory"
  u.email = "cedric.diggory@hogwarts.edu"
  u.password = "pleasantlyspringy"
  u.save!
  @courses.each do |name,config|
    u.course_memberships.create! do |cm|
      cm.course = config[:course]
      cm.role = "gsi"
    end
    u.team_leaderships.create! do |tm|
      tm.team_id = config[:course].teams.sample.id
    end
    FlaggedUser.toggle! config[:course], u, @students.sample.id
    FlaggedUser.toggle! config[:course], u, @students.sample.id
    FlaggedUser.toggle! config[:course], u, @students.sample.id
  end
end.activate!
puts "Hey, listen... About the badges. I've asked them not to wear them. ―Cedric Diggory"

# Create demo academic history content
@students.each do |s|

end
puts "I go to school, but I never learn what I want to know. ― Calvin & Hobbes"

# Add array of faculty ids into each course config hash
# :staff_ids => [25,27]
@courses.each do |name,config|
  config[:staff_ids] = config[:course].staff.map { |staff| staff.id }
end

# ---------------------------- Create Badges! --------------------------------#

@badges.each do |badge_name, config|
  @courses.each do |course_name, course_config|
    next unless course_config[:attributes][:has_badges] == true
    course_config[:course].tap do |course|
      badge = Badge.create! do |b|
        @badge_default_config[:attributes].keys.each do |attr|
          b[attr] = config[:attributes].key?(attr) ? config[:attributes][attr] :
            @badge_default_config[:attributes][attr]
        end
        b.course = course
      end

      # Store models on each course in the @courses hash
      @courses[course_name][:badges][badge_name] = badge
      puts_success :course, course_name, :badges_created

      if config[:unlock_condition]
        add_unlock_conditions(badge, config, course_config)
      end

      # ------------------- Create Earned Badges! ----------------------------#
      if config[:assign_samples]
        @students.each do |student|
          times_earned = config[:attributes][:can_earn_multiple_times] ? 2 : 1
          times_earned.times do
            student.earned_badges.create! do |eb|
              eb.badge = badge
              eb.course = course
              eb.student_visible = true
              eb.feedback = 'Sample Earned Badge Feedback and a quote from
              Kunal Nayyar: "No one ever sees the sleepless nights, the years
              of studying and 14-hour days earning your dues. I spent three
              years isolated in an academic environment to be the best actor
              I could."'
              eb.awarded_by_id = course_config[:staff_ids].sample
            end
          end
        end
      end
    end
  end
  puts_success :badge, badge_name, :badge_created
end

# ---------------------------- Create Assignment Types! ----------------------#

@assignment_types.each do |assignment_type_name, config|
  @courses.each do |course_name, course_config|
    next if (config[:attributes][:student_weightable] == true) &&
      (!course_config[:attributes].key?(:total_weights))
    course_config[:course].tap do |course|
      assignment_type = AssignmentType.create! do |at|
        @assignment_type_default_config[:attributes].keys.each do |attr|
          at[attr] = config[:attributes].key?(attr) ? config[:attributes][attr] :
            @assignment_type_default_config[:attributes][attr]
        end
        at.course = course
      end
      # Store models on each course in the @courses hash
      @courses[course_name][:assignment_types][assignment_type_name] =
        assignment_type
    end
  end
  puts_success :assignment_type, assignment_type_name, :assignment_type_created
end

PaperTrail.whodunnit = nil

# ---------------------------- Create Assignments!----------------------------#

@assignments.each do |assignment_name,config|
  @courses.each do |course_name,course_config|
    assignment_type_name =
      config[:assignment_type] || @assignment_default_config[:assignment_type]
    next if !course_config[:assignment_types].key? assignment_type_name

    course_config[:course].tap do |course|

      # used to generate grades and score levels
      assignment_full_points = config[:attributes][:full_points] ||
        @assignment_default_config[:attributes][:full_points]

      assignment = Assignment.create! do |a|
        @assignment_default_config[:attributes].keys.each do |attr|
          # ternary allows override for visible ('true' by default)
          # rubocop:disable MultilineTernaryOperator
          a[attr] =
            config[:attributes].key?(attr) ? config[:attributes][attr] :
              @assignment_default_config[:attributes][attr]
        end
        # remove dates for competency course
        if course_config[:no_due_dates]
          a.open_at = nil
          a.due_at = nil
        end
        a.assignment_type =
          course_config[:assignment_types][assignment_type_name]
        a.course = course
      end
      course_config[:assignments][assignment_name] = assignment

      if config[:rubric]
        Rubric.create! do |rubric|
          rubric.assignment = assignment
          rubric.course = assignment.course
          rubric.save

          full_points = 0
          1.upto(5).each do |n|
            rubric.criteria.create! do |criterion|
              criterion.name = "Criteria ##{n}"
              criterion.description = "Thestral dirigible plums, Viktor Krum hexed memory charm Animagus Invisibility Cloak three-headed Dog. Half-Blood Prince Invisibility Cloak cauldron cakes, hiya Harry!"
              criterion.max_points =
                10.times.collect {|i| (i + 1) * 10000}.sample

              full_points += criterion.max_points
              criterion.order = n
              criterion.save
              LevelBadge.create!(
                level_id: criterion.levels.first.id,
                badge_id: course_config[:badges][:visible_level_badge].id
              ) if course.has_badges

              1.upto(5).each do |m|
                level = criterion.levels.create! do |criterion_level|
                  criterion_level.name = "Level ##{m}"
                  criterion_level.points = criterion.max_points - (m * 1000)
                  criterion_level.description = "Red hair crookshanks bludger Marauder’s Map Prongs sunshine daisies butter mellow Ludo Bagman. Beaters gobbledegook N.E.W.T., Honeydukes eriseD inferi Wormtail. Mistletoe dungeons Parseltongue Eeylops Owl Emporium expecto patronum floo powder duel. Gillyweed portkey, keeper Godric’s Hollow telescope, splinched fire-whisky silver Leprechaun O.W.L. stroke the spine."
                end
                if m == 1 && course.has_badges
                  LevelBadge.create!(level_id: level.id,
                    badge_id: course_config[:badges][:invisible_level_badge].id)
                end
                if m == 2
                  criterion.update_meets_expectations!(level, true)
                end
              end
            end
          end
          assignment.update_attributes(full_points: full_points)
        end
        print "." if !course_name == @courses.keys[-1]
        puts_success :assignment, assignment_name,
          :rubric_created if course_name == @courses.keys[-1]
      end

      if config[:assignment_score_levels]
        1.upto(5).each do |n|
          assignment.assignment_score_levels.create! do |asl|
            asl.name = "Assignment Score Level ##{n}"
            asl.points = assignment_full_points/(6-n)
          end
        end
        puts_success :assignment, assignment_name,
          :score_levels_created if course_name == @courses.keys[-1]
      end

      if assignment.grade_scope == "Group" && config[:assign_groups]
        if course_config[:groups]
          assignment.groups << course_config[:groups]
        else
          create_groups(course_name, assignment)
        end
      end

# -------------------------- Create Submissions! --------------------------#

      if config[:student_submissions]
        @students.each do |student|
          PaperTrail.whodunnit = student.id
          submission = student.submissions.create! do |s|
            s.assignment = assignment
            s.text_comment = "Wingardium Leviosa"
            s.link = "http://www.twitter.com"
            s.submitted_at = DateTime.now
          end
          print "."
        end
        print "\n"
        puts_success :assignment, assignment_name,
          :submissions_created if course_name == @courses.keys[-1]
      end

  # -------------------------- Create Grades! --------------------------#

      if config[:grades]
        @students.each do |student|

          # skip grades for some students, based on participation rate
          next if config[:participation] && rand(100) > config[:participation]

          grade_attributes = config[:grade_attributes] || {}
          grade = student.grades.create! do |g|
            @assignment_default_config[:grade_attributes].keys.each do |attr|

              # You can set a custom raw score in :grade_attributes like this:
              #   :raw_points => Proc.new { rand(20000) }
              # Defaults to a random number between 0 and assignment point total

              if attr == :raw_points && grade_attributes[attr]
                g[attr] = grade_attributes[attr].call
              elsif attr == :raw_points
                g[attr] = @assignment_default_config[:grade_attributes][attr].call
              else
                g[attr] = grade_attributes[attr] ||
                  @assignment_default_config[:grade_attributes][attr]
              end
              if assignment.pass_fail
                g.pass_fail_status = ["Pass", "Pass", "Pass", "Fail"].sample
              end
              g.graded_at = DateTime.now
              g.graded_by_id = course_config[:staff_ids].sample
              PaperTrail.whodunnit = g.graded_by_id
            end
            g.assignment = assignment
          end

          if config[:rubric]
            raw_points = 0
            assignment.rubric.criteria.each do |criterion|
              raw_points += criterion.levels.first.points
              criterion.criterion_grades.create! do |cg|
                cg.assignment_id = assignment.id
                cg.comments = "good work #{student.first_name}!"
                cg.criterion_id = criterion.id
                cg.level_id = criterion.levels.first.id
                cg.points = criterion.levels.first.points
                cg.student_id = student.id
                cg.grade_id = grade.id
              end
            end
            grade.update_attributes(raw_points: raw_points)
          end
          print "."
        end

        print "\n"
        puts_success :assignment, assignment_name,
          :grades_created if course_name == @courses.keys[-1]
      end

      if config[:prediction]
        attributes = config[:prediction_attributes] || {}

        @students.each do |student|
          student.predicted_earned_grades.create! do |peg|
            if attributes[:predicted_points]
              peg.predicted_points = attributes[:predicted_points].call
            else
              peg.predicted_points = 0
            end
            peg.assignment = assignment
          end
        end
        puts_success :assignment, assignment_name, :prediction_created
      end

      if config[:unlock_condition]
        add_unlock_conditions(assignment, config, course_config)
      end

# --------------------------- Create Resubmissions! --------------------------#

      if config[:attributes][:resubmissions_allowed]
        puts "Generating Resubmissions"
        @students.each do |student|
          if assignment.resubmissions_allowed? && Grade.where(assignment_id: assignment.id, student_id: student.id, course_id: course.id).present?
            PaperTrail.whodunnit = student.id
            submission = student.submissions.create! do |s|
              s.assignment = assignment
              s.text_comment = "Wingardium Leviosa"
              s.link = "http://www.facebook.com"
              s.submitted_at = DateTime.now
            end
            submission.update_attributes(link: "http://twitch.tv")
            grade = Grade.where(assignment_id: assignment.id, student_id: student.id, course_id: course.id).first
            # Grade must associate with submission to be read as a resubmission
            grade.update_attributes(submission_id: submission.id)
          end
          print "."
        end
        print "\n"
        puts_success :assignment, assignment_name,
          :submissions_created if course_name == @courses.keys[-1]
      end
    end # tap course
  end #@courses
  puts_success :assignment, assignment_name, :assignment_created
end

# ---------------------------- Create Challenges! ----------------------------#

@challenges.each do |challenge_name,config|
  @courses.each do |course_name,course_config|
    next unless course_config[:attributes][:has_team_challenges]
    course_config[:course].tap do |course|
      challenge = Challenge.create! do |c|
        @challenge_default_config[:attributes].keys.each do |attr|
          c[attr] =
            config[:attributes].key?(attr) ? config[:attributes][attr] :
              @challenge_default_config[:attributes][attr]
        end
        c.course = course
      end
      # Store models on each course in the @courses hash
      @courses[course_name][:challenges][challenge_name] = challenge

      if config[:grades]
        # Used to set point total
        # You can also set a custom point total in the grade attributes:
        # full_points: Proc.new { rand(20000) }
        grade_attributes = config[:grade_attributes] || {}
        assignment_full_points = config[:attributes][:full_points] ||
          @challenge_default_config[:attributes][:full_points]

        course_config[:teams].each do |team|
          challenge.challenge_grades.create! do |cg|
            @challenge_default_config[:grade_attributes].keys.each do |attr|
              if attr == :score && grade_attributes[attr]
                cg[attr] = grade_attributes[attr].call
              elsif attr == :score
                cg[attr] = rand(assignment_full_points)
              else
                cg[attr] = grade_attributes.key?(attr) ? grade_attributes[attr] :
                  @challenge_default_config[:grade_attributes][attr]
              end
            end
            cg.team = team
          end
        end
      end
      puts_success :challenge, challenge_name, :grades_created
    end
  end
  puts_success :challenge, challenge_name, :challenge_created
end

# ---------------------------- Create Events! ----------------------------#

@events.each do |event_name,config|
  @courses.each do |course_name,course_config|
    course_config[:course].tap do |course|
      event = Event.create! do |e|
        @event_default_config[:attributes].keys.each do |attr|
          e[attr] =
            config[:attributes].key?(attr) ? config[:attributes][attr] :
              @event_default_config[:attributes][attr]
        end
        e.course = course
      end
      # Store models on each course in the @courses hash
      @courses[course_name][:events][event_name] = event
      puts_success :event, event_name, :event_created
    end
  end
  puts_success :event, event_name, :event_created
end

# ---------------------------- Create Announcements! --------------------------#

@announcements.each do |announcement_title,config|
  @courses.each do |course_name,course_config|
    course_config[:course].tap do |course|
      announcement = Announcement.create! do |a|
        @announcement_default_config[:attributes].keys.each do |attr|
          a[attr] =
            config[:attributes].key?(attr) ? config[:attributes][attr] :
              @announcement_default_config[:attributes][attr]
        end
        a.course = course
        a.author = course.staff.first
      end
      # Store models on each course in the @courses hash
      @courses[course_name][:announcements][announcement_title] = announcement
      puts_success :announcement, announcement_title, :announcement_created
    end
  end
  puts_success :announcement, announcement_title, :announcement_created
end

@students.each do |s|
  s.courses.each do |c|
    s.update_course_score_and_level(c.id)
  end
end
