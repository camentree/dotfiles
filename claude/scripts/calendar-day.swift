import EventKit
import Foundation

let store = EKEventStore()
let semaphore = DispatchSemaphore(value: 0)
var accessGranted = false
store.requestFullAccessToEvents { granted, _ in
    accessGranted = granted
    semaphore.signal()
}
semaphore.wait()
guard accessGranted else {
    FileHandle.standardError.write("no calendar access\n".data(using: .utf8)!)
    exit(1)
}

let excludedCalendars: Set<String> = ["Sarit"]

let dayFormatter = DateFormatter()
dayFormatter.dateFormat = "yyyy-MM-dd"
let requestedDay = CommandLine.arguments.count > 1 ? dayFormatter.date(from: CommandLine.arguments[1]) : nil
let dayStart = Calendar.current.startOfDay(for: requestedDay ?? Date())
let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!

let timeFormatter = DateFormatter()
timeFormatter.dateFormat = "HH:mm"
let events = store.events(matching: store.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: nil))
for event in events.sorted(by: { $0.startDate < $1.startDate }) where !excludedCalendars.contains(event.calendar.title) {
    let myStatus = event.attendees?.first(where: { $0.isCurrentUser })?.participantStatus
    let declined = myStatus == .declined
    let fields = [
        event.isAllDay ? "all-day" : timeFormatter.string(from: event.startDate),
        event.isAllDay ? "all-day" : timeFormatter.string(from: event.endDate),
        declined ? "declined" : "attending",
        event.calendar.title,
        event.title ?? ""
    ]
    print(fields.joined(separator: " | "))
}
