ENV["RAILS_ENV"] ||= "test"

RSpec.configure do |config|

  # If feature tests rely on pages with React, be sure to compile
  # all webpack resources.
  #ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
end
