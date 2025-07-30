# app/services/timekeeping_parser.rb

class TimekeepingParser
  include ActiveSupport::Cache

  def initialize(queue_name, raw_json)
    @queue_name = queue_name
    @raw_data = JSON.parse(raw_json)
    @payload = @raw_data["message"] ? JSON.parse(@raw_data["message"]) : {}
    @timestamp = Time.zone.now.strftime("%H:%M:%S")
    @vars = memory[queue_name] ||= default_flags
  end

  def process
    return unless @payload["payload"].present?
    p = @payload["payload"]

    show_id = p["meetingId"]
    class_id = p["competitionId"]
    rider_id = p["id"]
    fault = p["faults"] || 0
    fence_faults = p["fenceFaults"]
    rank = p["rank"]
    running = p["running"]
    waiting = p["waiting"]
    count_down = p["countDown"]
    count_down_value = p["countDownValue"]
    node_activated = p["nodeActivated"]
    phase = p["phase"]
    round = p["round"]
    time = p["time"]

    # Armer la cellule finish si activée
    if node_activated == "finish"
      @vars[:finish_ready] = true
    end

    if node_activated.nil?
      if !running && count_down && @vars[:finish_on] == 1 && @vars[:countdown_on] == 0
        mark(:COUNTDOWN, rider_id, phase, round)
      elsif !running && !count_down && count_down_value != "-45.0" && @vars[:pause_count_on] == 0 && @vars[:countdown_on] == 1
        mark(:COUNTDOWN_PAUSE, rider_id)
      elsif !running && count_down && count_down_value != "-45.0" && @vars[:pause_count_on] == 1 && @vars[:countdown_on] == 1
        mark(:COUNTDOWN_CONTINUE, rider_id)
      elsif !running && !count_down && rank == 999 && count_down_value == "-45.00"
        reset_flags
        return
      elsif running && waiting.nil? && @vars[:countdown_on] == 1 && @vars[:finish_on] == 0 && @vars[:start_on] == 0
        mark(:START, rider_id, phase, round)
      elsif running && fault != @vars[:fault_save] && fence_faults.to_i < 999
        mark(:FAULT, rider_id, phase, round)
        @vars[:fault_save] = fault
      elsif running && @vars[:phase_on] != phase && @vars[:start_on] == 1
        mark(:PHASE, rider_id, phase, round)
      elsif waiting == true && @vars[:pause_course] == 0
        mark(:PAUSE_COURSE, rider_id, phase, round)
        @vars[:pause_course] = 1
      elsif waiting == true && fence_faults.to_i == 666
        mark(:RETIRED, rider_id, phase, round)
        @vars[:is_retired] = 1
      elsif waiting == false && @vars[:pause_course] == 1
        mark(:CONTINUE_COURSE, rider_id, phase, round)
        @vars[:pause_course] = 0
      elsif !running && @vars[:finish_ready] && @vars[:start_on] == 1
        mark(:FINISH, rider_id, phase, round)
        @vars[:finish_ready] = false
        @vars[:finish_on] = 1
        @vars[:start_on] = 0
      elsif !running && rank != 999 && @vars[:finish_on] == 1
        mark(:SAVERESULTS, rider_id, phase, round)
      elsif running && fence_faults.to_i == 999 && @vars[:start_on] == 1 && @vars[:finish_on] == 0 && @vars[:is_elim] == 0
        mark(:ELIMINATED, rider_id, phase, round)
        @vars[:is_elim] = 1
      elsif running && fence_faults.to_i == 666 && @vars[:start_on] == 1 && @vars[:finish_on] == 0 && @vars[:is_retired] == 0
        mark(:RETIRED, rider_id, phase, round)
        @vars[:is_retired] = 1
      end
    end
  end

  private

def mark(type, rider_id, phase = nil, round = nil)
  @vars[:Type_Action] = type.to_s
  @vars[:record] = 1
  @vars[:phase_on] = phase if phase
  @vars[:round_on] = round if round
  @vars[:saveid] = rider_id

  # Recherche du cavalier dans la startlist
  start = StartsCompetition.find_by(
    Equipe_show_ID: @payload.dig("payload", "meetingId"),
    Equipe_class_ID: @payload.dig("payload", "competitionId"),
    Equipe_id: rider_id
  )

  startnb   = start&.StartNb
  ridername = start&.Rider_name
  horsename = start&.Horse_Name

  ::EquipeIncidentWebhook.create!(
    equipe_show_id: @payload.dig("payload", "meetingId"),
    equipe_class_id: @payload.dig("payload", "competitionId"),
    hnr: @payload.dig("payload", "horse_no"),
    startnb: startnb,
    ridername: ridername,
    horsename: horsename,
    phase_course: phase,
    round_course: round,
    type: type.to_s,
    timestamp: @timestamp
  )

  if %i[COUNTDOWN FINISH ELIMINATED RETIRED].include?(type)
    TriggerFfmpegJob.perform_later(
      action: (type == :COUNTDOWN ? "start" : "stop"),
      show_id: @payload.dig("payload", "meetingId"),
      class_id: @payload.dig("payload", "competitionId"),
      rider_id: rider_id,
      round: round,
      stream_key: stream_key_from_arena(@payload.dig("payload", "arena")),
      timestamp: @timestamp
    )
  end
end

  def reset_flags
    @vars.merge!(default_flags)
  end

  def stream_key_from_arena(arena_name)
    AntmediaStream.find_by(piste_name: arena_name)&.stream_key
  end

  def memory
    Rails.cache.fetch(:timekeeping_dynamic_flags) { {} }
  end

  def default_flags
    {
      countdown_on: 0,
      finish_on: 1,
      start_on: 0,
      pause_on: 0,
      pause_count_on: 0,
      fault_save: 0,
      record: 0,
      phase_on: 1,
      round_on: 1,
      Type_Action: "",
      pause_course: 0,
      is_elim: 0,
      is_retired: 0,
      saveid: 0,
      finish_ready: false
    }
  end
end
