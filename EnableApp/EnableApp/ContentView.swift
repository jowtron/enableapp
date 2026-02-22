import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isTargeted = false
    @State private var results: [ResultEntry] = []

    var body: some View {
        VStack(spacing: 0) {
            dropZone
            if !results.isEmpty {
                resultsList
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
                )

            VStack(spacing: 12) {
                Image(systemName: "app.badge.checkmark")
                    .font(.system(size: 48))
                    .foregroundStyle(isTargeted ? .accent : .secondary)
                Text("Drop .app here to fix")
                    .font(.title3)
                    .foregroundStyle(isTargeted ? .primary : .secondary)
                Text("Runs xattr -cr to remove quarantine attributes")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(height: 200)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private var resultsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(results) { entry in
                    HStack(spacing: 8) {
                        Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(entry.success ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                            if let msg = entry.message {
                                Text(msg)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(maxHeight: 200)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    process(url: url)
                }
            }
        }
        return true
    }

    private func process(url: URL) {
        let path = url.path
        let name = url.lastPathComponent

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        task.arguments = ["-cr", path]

        let pipe = Pipe()
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()
            let status = task.terminationStatus
            if status == 0 {
                results.insert(ResultEntry(name: name, success: true, message: nil), at: 0)
            } else {
                let errData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errMsg = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                results.insert(ResultEntry(name: name, success: false, message: errMsg), at: 0)
            }
        } catch {
            results.insert(ResultEntry(name: name, success: false, message: error.localizedDescription), at: 0)
        }
    }
}

struct ResultEntry: Identifiable {
    let id = UUID()
    let name: String
    let success: Bool
    let message: String?
}
