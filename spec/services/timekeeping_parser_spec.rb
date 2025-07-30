# spec/services/timekeeping_parser_spec.rb

require 'rails_helper'

RSpec.describe TimekeepingParser, type: :service do
  let(:queue_name) { "competition_queue_80093_47" }
  let(:raw_event) do
    {
      "message" => {
        "event_name" => "timekeeping",
        "api_key" => "FILTERED",
        "payload" => {
          "id" => 2657,
          "rank" => 999,
          "time" => 49.75,
          "arena" => "Courrière",
          "phase" => 2,
          "round" => 2,
          "faults" => 8,
          "running" => false,
          "baseTime" => "49.75",
          "countDown" => false,
          "meetingId" => 80093,
          "timeFaults" => 0,
          "fenceFaults" => 8,
          "totalFaults" => nil,
          "previousTime" => nil,
          "competitionId" => 47,
          "countDownDiff" => nil,
          "nodeActivated" => nil,
          "timekeepingOutputId" => 54
        }
      }.to_json,
      "timestamp" => "12:34:56"
    }.to_json
  end

  it "parses and records an event" do
    parser = TimekeepingParser.new(queue_name, raw_event)
    expect { parser.process }.to change(EquipeIncidentWebhook, :count).by(1)

    incident = EquipeIncidentWebhook.last
    expect(incident.equipe_show_id).to eq(80093)
    expect(incident.equipe_class_id).to eq(47)
    expect(incident.type).to be_present
    expect(incident.timestamp).to eq("12:34:56")
  end
end
