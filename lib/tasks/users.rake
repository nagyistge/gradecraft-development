namespace :users do
  desc "Activates all existing users"
  task activate: :environment do
    all = User.all
    all.each(&:activate!)
    puts "\nSuccessfully activated all #{all.count} #{"user".pluralize(all.count)}."
  end

  desc "Make given user an admin on all courses"
  task make_admin_on_all_courses: :environment do
    if ENV['username'].nil?
      fail 'ERROR: missing username. Append the username as a variable to this task, e.g. rake users:make_admin_on_all_courses username=<username>'
    end

    user = User.find_by username: ENV['username']
    if user.nil?
      fail "ERROR: username not found (\"#{ENV['username']}\")"
    end

    Course.find_each(batch_size: 500) do |course|
      membership = CourseMembership.find_or_create_by course: course, user: user
      membership.role = 'admin'
      membership.save
      puts "Made #{user.username} an admin on \"#{course.name}\""
    end
  end

  desc "Add John Doe as default student for impersonating"
  task add_john_doe_impersonation: :environment do
    User.create! first_name: "John",
      last_name: "Doe",
      username: "john_doe_gradecraft",
      email: "john_doe@gradecraft.com"
    puts "Successfully created John Doe"
  end
end
