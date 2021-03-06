module UniMock
  module StubTime
    def stub_now(parseable_date)
      allow(Time).to receive(:now) { Date.parse(parseable_date).to_time }
    end
  end
end
