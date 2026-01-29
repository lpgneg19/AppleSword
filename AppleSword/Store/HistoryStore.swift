import Foundation

@MainActor
class HistoryStore: ObservableObject {
    @Published var archivedTasks: [DownloadTask] = []

    private let fileURL: URL

    init() {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("AppleSword", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: appSupport, withIntermediateDirectories: true, attributes: nil)
        self.fileURL = appSupport.appendingPathComponent("history.json")
        load()
    }

    func add(_ task: DownloadTask) {
        // Avoid duplicates
        if !archivedTasks.contains(where: { $0.gid == task.gid }) {
            var taskToArchive = task
            // Ensure status is recorded as something final if not already
            if taskToArchive.status == .active || taskToArchive.status == .waiting
                || taskToArchive.status == .paused
            {
                // If we are archiving an active task (e.g. user removed it), mark it as removed
                taskToArchive.status = .removed
            }
            // If it's complete, keep it as complete

            archivedTasks.insert(taskToArchive, at: 0)
            save()
        }
    }

    func remove(gid: String) {
        archivedTasks.removeAll { $0.gid == gid }
        save()
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(archivedTasks)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[HistoryStore] Failed to save history: \(error)")
        }
    }

    func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            archivedTasks = try JSONDecoder().decode([DownloadTask].self, from: data)
        } catch {
            print("[HistoryStore] Failed to load history (may be new): \(error)")
            archivedTasks = []
        }
    }
}
