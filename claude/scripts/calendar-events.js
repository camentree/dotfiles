function run(argv) {
  const dayOffset = argv.length ? parseInt(argv[0], 10) : 0;
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  start.setDate(start.getDate() + dayOffset);
  const end = new Date(start);
  end.setDate(end.getDate() + 1);
  const app = Application("Calendar");
  const lines = [];
  app.calendars().forEach((calendar, index) => {
    const name = calendar.name();
    if (
      !calendar.writable() ||
      name === "Engineering" ||
      name === "Scheduled Reminders"
    )
      return;
    const events = calendar.events.whose({
      _and: [
        { startDate: { _lessThan: end } },
        { endDate: { _greaterThan: start } },
      ],
    })();
    for (const event of events) {
      const format = (date) => date.toTimeString().slice(0, 5);
      const when = event.alldayEvent()
        ? "all-day   "
        : `${format(event.startDate())}-${format(event.endDate())}`;
      lines.push(
        `${when}\t[${name}#${index}]\t${event.summary()}\t${event.status()}`,
      );
    }
  });
  return lines.sort().join("\n") || "(no events)";
}
