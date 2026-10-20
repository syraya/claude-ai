import SwiftUI
import Charts

/// Titles you earn as your lifetime focus grows, borrowed from the Renaissance
/// guilds, where an apprentice worked their way up to master.
struct FocusRank: Identifiable, Equatable {
    let title: String
    let hours: Int
    let motto: String

    var id: String { title }

    static let all = [
        FocusRank(title: "Novice", hours: 0, motto: "Every master was once a beginner."),
        FocusRank(title: "Apprentice", hours: 10, motto: "You've started learning the craft."),
        FocusRank(title: "Scholar", hours: 50, motto: "Focus is turning into a habit."),
        FocusRank(title: "Journeyman", hours: 100, motto: "A hundred hours of real work."),
        FocusRank(title: "Master", hours: 500, motto: "Few people ever focus this much."),
        FocusRank(title: "Maestro", hours: 1_000, motto: "A thousand hours of deep thought."),
        FocusRank(title: "Sage", hours: 5_000, motto: "Wisdom, built one session at a time."),
        FocusRank(title: "Polymath", hours: 10_000, motto: "Ten thousand hours: the mark of true mastery."),
    ]

    static func current(forMinutes minutes: Int) -> FocusRank {
        all.last { minutes >= $0.hours * 60 } ?? all[0]
    }

    static func next(after rank: FocusRank) -> FocusRank? {
        guard let index = all.firstIndex(of: rank), index + 1 < all.count else { return nil }
        return all[index + 1]
    }

    /// 0...1 progress from `rank` toward the next one.
    static func progress(minutes: Int, from rank: FocusRank) -> Double {
        guard let next = next(after: rank) else { return 1 }
        let span = Double((next.hours - rank.hours) * 60)
        return min(1, max(0, Double(minutes - rank.hours * 60) / span))
    }
}

enum LifetimeFormat {
    /// "1,284" for big totals, "3.5" while you're still under 10 hours.
    static func hours(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60
        if hours < 10 { return hours.formatted(.number.precision(.fractionLength(0...1))) }
        return Int(hours).formatted(.number.grouping(.automatic))
    }
}

/// The small card on the Focus tab that opens the full tracker.
struct LifetimeCard: View {
    var lifetime: LifetimeStats

    var body: some View {
        let rank = FocusRank.current(forMinutes: lifetime.totalFocusMinutes)
        let next = FocusRank.next(after: rank)
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL FOCUS")
                    .font(.caption2.weight(.semibold))
                    .kerning(1.5)
                    .foregroundStyle(Color.omoClay)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(LifetimeFormat.hours(lifetime.totalFocusMinutes))
                        .font(.system(size: 34, weight: .semibold, design: .serif).monospacedDigit())
                        .foregroundStyle(Color.omoInk)
                    Text("hours").font(.subheadline).foregroundStyle(.secondary)
                }
                Text(next.map { "\(rank.title) · \(hoursLeft(to: $0)) to \($0.title)" } ?? rank.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: FocusRank.progress(minutes: lifetime.totalFocusMinutes, from: rank))
                    .tint(.omoGold)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .card()
    }

    private func hoursLeft(to rank: FocusRank) -> String {
        let minutes = max(0, rank.hours * 60 - lifetime.totalFocusMinutes)
        return minutes < 60 ? "\(minutes)m" : "\(LifetimeFormat.hours(minutes))h"
    }
}

/// Everything you've focused since installing OMO.
struct LifetimeView: View {
    @Environment(FocusController.self) private var focus
    @State private var shownMinutes = 0

    private var lifetime: LifetimeStats { focus.lifetime }
    private var rank: FocusRank { FocusRank.current(forMinutes: lifetime.totalFocusMinutes) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                counter
                rankCard
                if chartPoints.count > 1 { chartCard }
                statsGrid
                ladder
            }
            .padding()
        }
        .background(OmoBackground())
        .navigationTitle("Lifetime")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { shownMinutes = lifetime.totalFocusMinutes }
        }
    }

    private var counter: some View {
        VStack(spacing: 6) {
            Text("SINCE \(lifetime.startedAt.formatted(date: .abbreviated, time: .omitted).uppercased())")
                .font(.caption2.weight(.semibold))
                .kerning(1.5)
                .foregroundStyle(Color.omoClay)
            Text(LifetimeFormat.hours(shownMinutes))
                .font(.system(size: 72, weight: .semibold, design: .serif).monospacedDigit())
                .foregroundStyle(Color.omoInk)
                .contentTransition(.numericText(value: Double(shownMinutes)))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("hours focused")
                .font(.system(.title3, design: .serif).italic())
                .foregroundStyle(.secondary)
            Text("\(lifetime.totalFocusMinutes.formatted()) minutes in total")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var rankCard: some View {
        let next = FocusRank.next(after: rank)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your title").font(.caption).foregroundStyle(.secondary)
                    Text(rank.title).font(.omoSerif(.title2, weight: .bold)).foregroundStyle(Color.omoPrimary)
                }
                Spacer()
                Image(systemName: "laurel.leading").font(.title).foregroundStyle(Color.omoGold)
            }
            Text(rank.motto).font(.system(.body, design: .serif).italic()).foregroundStyle(.secondary)
            if let next {
                ProgressView(value: FocusRank.progress(minutes: lifetime.totalFocusMinutes, from: rank))
                    .tint(.omoGold)
                let left = max(0, next.hours * 60 - lifetime.totalFocusMinutes)
                Text("\(left < 60 ? "\(left) minutes" : "\(LifetimeFormat.hours(left)) hours") to \(next.title) (\(next.hours.formatted()) h)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("You've reached the top. Ten thousand hours.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .card()
    }

    /// Running total at the end of each month since you started.
    private var chartPoints: [(date: Date, hours: Double)] {
        let months = lifetime.monthlyMinutes.keys.sorted()
        var running = 0
        var points: [(date: Date, hours: Double)] = []
        if let first = months.first.flatMap({ LifetimeStats.monthFormatter.date(from: $0) }) {
            points.append((date: first, hours: 0))
        }
        for key in months {
            guard let start = LifetimeStats.monthFormatter.date(from: key),
                  let end = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: start) else { continue }
            running += lifetime.monthlyMinutes[key] ?? 0
            points.append((date: min(end, Date()), hours: Double(running) / 60))
        }
        return points
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total focus over time").font(.omoSerif(.headline))
            Chart(chartPoints, id: \.date) { point in
                AreaMark(x: .value("Date", point.date), y: .value("Hours", point.hours))
                    .foregroundStyle(LinearGradient(colors: [Color.omoPrimary.opacity(0.3), Color.omoPrimary.opacity(0.02)],
                                                    startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Date", point.date), y: .value("Hours", point.hours))
                    .foregroundStyle(Color.omoPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.monotone)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Color.omoInk.opacity(0.08))
                    AxisValueLabel { if let h = value.as(Double.self) { Text("\(Int(h))h") } }
                }
            }
            .frame(height: 180)
        }
        .card()
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatPill(value: lifetime.sessionsCompleted.formatted(), label: "Sessions completed", color: .omoPrimary)
            StatPill(value: lifetime.friendSessions.formatted(), label: "Study Circles", color: .omoClay)
            StatPill(value: Format.minutes(lifetime.longestSessionMinutes), label: "Longest session", color: .omoSuccess)
            StatPill(value: "\(lifetime.streak()) 🔥", label: "Day streak (best \(lifetime.longestStreak))", color: .omoGold)
            StatPill(value: Format.minutes(lifetime.totalFocusMinutes / lifetime.daysSinceStart), label: "Average per day", color: .omoSuccess)
            StatPill(value: lifetime.daysSinceStart.formatted(), label: "Days with OMO", color: .omoPrimary)
        }
    }

    private var ladder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The path").font(.omoSerif(.headline))
            ForEach(FocusRank.all) { step in
                let reached = lifetime.totalFocusMinutes >= step.hours * 60
                HStack(spacing: 12) {
                    Image(systemName: reached ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(reached ? Color.omoGold : Color.omoInk.opacity(0.25))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(step.title).fontWeight(step == rank ? .bold : .regular)
                        Text(step.motto).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(step.hours.formatted()) h")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .opacity(reached || step == FocusRank.next(after: rank) ? 1 : 0.55)
            }
        }
        .card()
    }
}
