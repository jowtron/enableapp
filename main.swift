import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main entry point
let app = NSApplication.shared
app.setActivationPolicy(.regular)

let delegate = AppDelegate()
app.delegate = delegate
app.run()

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "EnableApp"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

// MARK: - SwiftUI Views
struct ContentView: View {
    @State private var isTargeted = false
    @State private var results: [ResultEntry] = []

    var body: some View {
        VStack(spacing: 0) {
            dropZone
            if !results.isEmpty {
                Divider()
                resultsList
            }
        }
        .frame(minWidth: 420, minHeight: 260)
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
            VStack(spacing: 10) {
                Image(systemName: "app.badge.checkmark")
                    .font(.system(size: 44))
                    .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                Text("Drop .app bundles here")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(isTargeted ? .primary : .secondary)
                Text("Removes quarantine & damage flags via xattr -cr")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .frame(height: 190)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private var resultsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(results) { entry in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(entry.success ? .green : .red)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                            if let msg = entry.message {
                                Text(msg)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(7)
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 160)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async { process(url: url) }
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
        let errPipe = Pipe()
        task.standardError = errPipe
        task.standardOutput = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                results.insert(ResultEntry(name: name, success: true, message: "Attributes cleared"), at: 0)
            } else {
                let data = errPipe.fileHandleForReading.readDataToEndOfFile()
                let msg = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
                results.insert(ResultEntry(name: name, success: false, message: msg), at: 0)
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
