#!/usr/bin/env ruby
require 'date'
require 'active_support/core_ext/date_and_time/calculations'
require 'icalendar'

day0 = Date.parse(ARGV[0]) # YYYY-MM-DD or other Date.parse()-able format

start = day0.beginning_of_week.prev_day(9 * 7)

events = Array.new((start..day0).to_a.size) { [] }

MON, TUE, WED, THU, FRI, SAT, SUN = (0...7).to_a

class Array
    def to_bools
        self.flat_map do |row|
            (MON..SUN).map { |day| row.include? day }
        end
    end
    def to_ints
        self.flat_map do |row|
            empty_week = (MON..SUN).map {}
            row.each_with_object(empty_week) { |(day, dist), a| a[eval(day.to_s)] = dist }
        end
    end
end

mobility_days = [
    [MON, WED, SUN],
    [TUE, SAT],
    [MON, WED, SUN],
    [TUE, SAT],
    [TUE, SAT],
    [WED, FRI, SUN],
    [TUE, THU, SAT],
    [MON, FRI, SUN],
    [TUE, THU, SAT],
].to_bools
strength_days = [
    [WED],
    [TUE, SAT],
    [],
    [TUE, SAT],
    [TUE, SAT],
    [WED, FRI],
    [TUE, THU],
    [],
    [TUE, THU],
].to_bools
run_days = [
    {TUE: 5, THU: 4, SAT: 12, SUN: 3},
    {MON: 4, WED: 5, FRI: 3, SAT: 12},
    {TUE: 5, THU: 3, SAT: 12, SUN: 4},
    {TUE: 2, THU: 2, SAT: 2},
    {TUE: 4, THU: 5, SAT: 14, SUN: 5},
    {MON: 4, WED: 5, SAT: 14, SUN: 5},
    {TUE: 5, THU: 3, SAT: 12, SUN: 4},
    {TUE: 2, THU: 2, SAT: 4},
    {TUE: 5, THU: 5, SAT: 15, SUN: 5},
].to_ints


cal = Icalendar::Calendar.new

(start...day0).each.with_index do |date, i|

    is_mobility_day = mobility_days[i]
    is_strength_day = strength_days[i]
    run_distance = run_days[i]

    def with_name_and_date(name, date)

        event = Icalendar::Event.new
        event.summary = name
        event.dtstart = Icalendar::Values::Date.new(date)
        event.alarm do |a|

            a.trigger = Icalendar::Values::DateTime.new(date.to_time.utc.advance(hours: 8, minutes: 30))
        end
        event
    end

    if is_mobility_day && is_strength_day
        cal.add_event(with_name_and_date("Strength and Mobility exercise", date))
    elsif is_mobility_day
        cal.add_event(with_name_and_date("Mobility exercise", date))
    elsif is_strength_day
        cal.add_event(with_name_and_date("Strength exercise", date))
    elsif !!run_distance
        name = "#{run_distance}mi #{run_distance > 10 ? 'Training Hike' : 'Hills Training Run'}"
        cal.add_event(with_name_and_date(name, date))
    end
end

File.write("training.ics", cal.to_ical)
