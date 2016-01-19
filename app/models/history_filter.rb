class HistoryFilter
  attr_reader :changeset

  def initialize(changeset)
    @changeset = changeset
  end

  def exclude(options)
    exclusions = options.keys

    @changeset = changeset.select do |set|
      exclusions.inject(true) do |select, exclusion|
        set[exclusion] != options[exclusion]
      end
    end.delete_if { |set| set.empty? }
    self
  end

  def include(options)
    inclusions = options.keys
    @changeset = changeset.select do |set|
      inclusions.inject(true) do |select, inclusion|
        set[inclusion] == options[inclusion]
      end
    end.delete_if { |set| set.empty? }
    self
  end

  def remove(options)
    name = options["name"]

    @changeset = changeset.map do |set|
      set.delete_if { |key, value| name == key } if name
    end.delete_if { |set| set.empty? }
    self
  end
end
