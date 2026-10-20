import SwiftUI
import Charts

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
                Text("\(left < 60 ? "\(left) minutes" : "\(LifetimeFormat.hours(left)) hours") to \(next.title), when \(next.companions.map(\.name).joined(separator: " and ")) joins you")
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
                        HStack(spacing: 5) {
                            ForEach(step.companions) { companion in
                                OmoFigure(companion: companion, size: 24, locked: !reached, backdrop: true)
                            }
                            let names = step.companions.map(\.name).joined(separator: " & ")
                            Text(step.hours == 0 ? "\(names), from the start" : (reached ? "\(names) joined you" : "\(names) joins you"))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(reached ? Color.omoGold : .secondary)
                        }
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

/// Shown once when you reach a new title: meet the OMO who joins you.
struct RankUpView: View {
    var rank: FocusRank
    var onUse: (OmoCompanion) -> Void
    var onClose: () -> Void

    var body: some View {
        let companion = rank.companions.first ?? .glaux
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 6) {
                Text("You're now a").font(.system(.title3, design: .serif).italic()).foregroundStyle(.secondary)
                Text(rank.title).font(.omoSerif(.largeTitle, weight: .bold)).foregroundStyle(Color.omoPrimary)
                Text("\(rank.hours.formatted()) hours of focus").font(.subheadline).foregroundStyle(.secondary)
            }

            OmoFigure(companion: companion, size: 190, backdrop: true)
                .shadow(color: Color.omoInk.opacity(0.25), radius: 18, y: 12)
                .hovering(6)
                .padding(.vertical, 8)

            VStack(spacing: 6) {
                Text("\(companion.name) joins you")
                    .font(.omoSerif(.title3))
                    .multilineTextAlignment(.center)
                Text(companion.story)
                    .font(.system(.body, design: .serif).italic())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("Brings: \(companion.themeDescription)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            VStack(spacing: 10) {
                Button("Study with \(companion.name)") { onUse(companion) }
                    .buttonStyle(PrimaryButtonStyle())
                Button("Not now", action: onClose)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(24)
        .background(OmoBackground())
    }
}
