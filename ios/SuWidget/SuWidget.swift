import SwiftUI
import WidgetKit

// Uygulama ile paylaşılan App Group. Runner ve SuWidgetExtension hedeflerinde aynı olmalı.
private let appGroupId = "group.com.furkanbalci.suHatirlatici"

struct SuEntry: TimelineEntry {
    let date: Date
    let totalMl: Int
    let goalMl: Int
    let glassMl: Int
    let next: String

    var progress: Double { min(1, Double(totalMl) / Double(max(goalMl, 1))) }
    var liters: String { String(format: "%d.%d L", totalMl / 1000, (totalMl % 1000) / 100) }
    var goalLiters: String { String(format: "%d.%d L", goalMl / 1000, (goalMl % 1000) / 100) }
}

struct SuProvider: TimelineProvider {
    func placeholder(in context: Context) -> SuEntry {
        SuEntry(date: .now, totalMl: 1400, goalMl: 2500, glassMl: 330, next: "14:30")
    }

    func getSnapshot(in context: Context, completion: @escaping (SuEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SuEntry>) -> Void) {
        completion(Timeline(entries: [load()], policy: .after(Date().addingTimeInterval(30 * 60))))
    }

    private func load() -> SuEntry {
        let d = UserDefaults(suiteName: appGroupId)
        let goal = d?.integer(forKey: "goal_ml") ?? 0
        return SuEntry(
            date: .now,
            totalMl: d?.integer(forKey: "total_ml") ?? 0,
            goalMl: goal > 0 ? goal : 2500,
            glassMl: d?.integer(forKey: "glass_ml") ?? 330,
            next: d?.string(forKey: "next") ?? ""
        )
    }
}

struct SuWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SuEntry

    private let water = Color(red: 0.12, green: 0.53, blue: 0.71)
    private let track = Color(red: 0.86, green: 0.93, blue: 0.96)

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(track, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(water, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "drop.fill").foregroundStyle(water).font(.system(size: 18))
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.liters).font(.system(size: 26, weight: .bold, design: .rounded))
                Text("hedef \(entry.goalLiters)").font(.system(size: 12)).foregroundStyle(.secondary)
                if !entry.next.isEmpty {
                    Label("Sıradaki \(entry.next)", systemImage: "alarm")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(water)
                        .padding(.top, 4)
                }
            }
            if family != .systemSmall { Spacer() }
        }
        .padding(family == .systemSmall ? 2 : 6)
        .widgetURL(URL(string: "suhatirlatici://add"))
        .containerBackground(for: .widget) { Color(UIColor.systemBackground) }
    }
}

struct SuWidget: Widget {
    let kind = "SuWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SuProvider()) { entry in
            SuWidgetView(entry: entry)
        }
        .configurationDisplayName("Su Hatırlatıcı")
        .description("Günlük su ilerlemen ve sıradaki hatırlatma.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
