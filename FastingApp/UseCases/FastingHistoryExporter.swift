import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct FastingHistoryExport: Transferable {
    let csvText: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { export in
            Data(export.csvText.utf8)
        }
        .suggestedFileName("FeastClock-Fasting-History.csv")
    }
}

struct FastingHistoryExporter {
    func csv(for sessions: [FastingSession], calendar: Calendar = .current) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let timeFormatter = DateFormatter()
        timeFormatter.calendar = calendar
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        let rows = sessions.map { session in
            [
                dateFormatter.string(from: session.startedAt),
                session.status.rawValue,
                session.planName ?? "",
                timeFormatter.string(from: session.startedAt),
                session.endedAt.map { timeFormatter.string(from: $0) } ?? "",
                String(session.actualFastingMinutes ?? 0),
                session.source.rawValue,
                session.notes ?? ""
            ].map(escape).joined(separator: ",")
        }

        return ([
            "Date,Status,Plan,Start Time,End Time,Duration Minutes,Source,Notes"
        ] + rows).joined(separator: "\n")
    }

    private func escape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }
}
