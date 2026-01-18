import Alamofire
import AnyCodable
import Aria2Kit
import Combine
import Foundation
import SwiftUI
import UserNotifications

// Standard response wrapper for Aria2 RPC
struct Aria2Response<T: Codable>: Codable {
    let id: String
    let jsonrpc: String
    let result: T?
    let error: Aria2RPCError?
}

struct Aria2RPCError: Codable {
    let code: Int
    let message: String
}

@MainActor
class TaskStore: ObservableObject {
    @Published var tasks: [DownloadTask] = []
    @Published var isConnected = false
    @Published var lastError: String?
    @Published var lastAddedGid: String?

    private var aria2: Aria2
    private var timer: AnyCancellable?
    private var connectionAttempts = 0

    init(rpcHost: String = "localhost", rpcPort: Int = 16800, rpcSecret: String = "") {
        let settings = SettingsStore()
        EngineManager.shared.start(settings: settings)

        let actualPort = settings.rpcPort
        let actualSecret = settings.rpcSecret

        print("[TaskStore] Initializing Aria2Kit (HTTP) on \(rpcHost):\(actualPort)")

        self.aria2 = Aria2(
            ssl: false, host: rpcHost, port: UInt16(actualPort),
            token: actualSecret.isEmpty ? nil : actualSecret)

        requestNotificationPermission()
        startPolling()
    }

    private func requestNotificationPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    print("[TaskStore] Notification permission granted")
                }
            } catch {
                print("[TaskStore] Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    deinit {
        Task { @MainActor in
            EngineManager.shared.stop()
        }
    }

    func fetchTasks() {
        performCall(method: .tellActive, params: [])
        performCall(method: .tellWaiting, params: [AnyEncodable(0), AnyEncodable(100)])
        performCall(method: .tellStopped, params: [AnyEncodable(0), AnyEncodable(100)])
    }

    private func performCall(method: Aria2Method, params: [AnyEncodable]) {
        aria2.call(method: method, params: params)
            .response { [weak self] response in
                Task { @MainActor in
                    switch response.result {
                    case .success(let data):
                        guard let data = data else { return }
                        // Multi-way decoding based on expected method result
                        if let rpcResponse = try? JSONDecoder().decode(
                            Aria2Response<[DownloadTask]>.self, from: data),
                            let fetchedTasks = rpcResponse.result
                        {
                            self?.handleTasksResult(.success(fetchedTasks))
                        } else if let rpcResponse = try? JSONDecoder().decode(
                            Aria2Response<String>.self, from: data),
                            let gid = rpcResponse.result
                        {
                            print("[TaskStore] Action success for GID: \(gid)")
                            self?.isConnected = true
                            self?.lastError = nil
                            // Small delay before fetching to allow engine state transition
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self?.fetchTasks()
                            }
                        } else if let rpcResponse = try? JSONDecoder().decode(
                            Aria2Response<AnyCodable>.self, from: data),
                            let error = rpcResponse.error
                        {
                            print("[TaskStore] RPC Error: \(error.message)")
                            self?.isConnected = false
                            self?.lastError = "内核错误: \(error.message)"
                        }
                    case .failure(let error):
                        self?.handleTasksResult(.failure(error))
                    }
                }
            }
    }

    private func handleTasksResult(_ result: Result<[DownloadTask], Error>) {
        switch result {
        case .success(let fetchedTasks):
            mergeTasks(fetchedTasks)
            if !isConnected {
                print("[TaskStore] RPC handshake success")
                isConnected = true
                lastError = nil
            }
        case .failure(let error):
            print("[TaskStore] Fetch error: \(error.localizedDescription)")
            isConnected = false
            lastError = "引擎连接失败: \(error.localizedDescription)"
        }
    }

    private func mergeTasks(_ newTasks: [DownloadTask]) {
        let settings = SettingsStore()
        var currentTasksMap = self.tasks.reduce(into: [String: DownloadTask]()) { $0[$1.gid] = $1 }

        for task in newTasks {
            if let oldTask = currentTasksMap[task.gid] {
                // Status transition: active -> complete
                if oldTask.status != .complete && task.status == .complete {
                    if settings.notificationEnabled {
                        sendCompletionNotification(for: task)
                    }
                }
            }
            currentTasksMap[task.gid] = task
        }

        self.tasks = Array(currentTasksMap.values).sorted { $0.gid > $1.gid }
    }

    private func sendCompletionNotification(for task: DownloadTask) {
        let content = UNMutableNotificationContent()
        content.title = "下载完成"
        content.body =
            task.bittorrent?.info?.name ?? task.files.first?.path.components(separatedBy: "/").last
            ?? "未知文件"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "complete-\(task.gid)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func startPolling() {
        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchTasks()
            }
    }

    // MARK: - Actions
    func addUri(_ uris: [String]) {
        aria2.call(method: .addUri, params: [AnyEncodable(uris)]).response { [weak self] response in
            if case .success(let data) = response.result, let data = data {
                if let rpcResponse = try? JSONDecoder().decode(
                    Aria2Response<String>.self, from: data),
                    let gid = rpcResponse.result
                {
                    Task { @MainActor in
                        self?.lastAddedGid = gid
                        self?.fetchTasks()
                    }
                }
            }
        }
    }

    func addTorrent(at path: String) {
        let settings = SettingsStore()
        addTorrent(at: path, paused: !settings.btAutoStart)
    }

    func addTorrent(at path: String, paused: Bool) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
        var params: [AnyEncodable] = [AnyEncodable(data.base64EncodedString())]

        let settings = SettingsStore()
        var options: [String: String] = [:]
        if paused {
            options["pause"] = "true"
        }
        // Always set the default download path if specified
        if !settings.downloadPath.isEmpty {
            options["dir"] = settings.downloadPath
        }

        // Aria2 RPC addTorrent(torrent, uris, options)
        params.append(AnyEncodable([String]()))  // Empty URIs list
        if !options.isEmpty {
            params.append(AnyEncodable(options))
        }

        aria2.call(method: .addTorrent, params: params).response { [weak self] response in
            if case .success(let data) = response.result, let data = data {
                if let rpcResponse = try? JSONDecoder().decode(
                    Aria2Response<String>.self, from: data),
                    let gid = rpcResponse.result
                {
                    Task { @MainActor in
                        self?.lastAddedGid = gid
                        self?.fetchTasks()
                    }
                }
            }
        }
    }

    func pauseTasks(gids: Set<String>) {
        for gid in gids {
            aria2.call(method: .pause, params: [AnyEncodable(gid)]).response { _ in }
        }
    }

    func resumeTasks(gids: Set<String>) {
        for gid in gids {
            aria2.call(method: .unpause, params: [AnyEncodable(gid)]).response { [weak self] _ in
                Task { @MainActor in self?.fetchTasks() }
            }
        }
    }

    func resumeTask(gid: String, options: [String: String] = [:]) {
        if !options.isEmpty {
            changeOption(gid: gid, options: options) { [weak self] in
                Task { @MainActor in
                    self?.aria2.call(method: .unpause, params: [AnyEncodable(gid)]).response { _ in
                        Task { @MainActor in self?.fetchTasks() }
                    }
                }
            }
        } else {
            aria2.call(method: .unpause, params: [AnyEncodable(gid)]).response { [weak self] _ in
                Task { @MainActor in self?.fetchTasks() }
            }
        }
    }

    func changeOption(gid: String, options: [String: String], completion: @escaping @Sendable () -> Void = {})
    {
        aria2.call(method: .changeOption, params: [AnyEncodable(gid), AnyEncodable(options)])
            .response { _ in
                completion()
            }
    }

    func removeTasks(gids: Set<String>) {
        for gid in gids {
            if let task = tasks.first(where: { $0.gid == gid }) {
                if task.status == .complete || task.status == .removed || task.status == .error {
                    // Use removeDownloadResult for finished tasks
                    aria2.call(method: .removeDownloadResult, params: [AnyEncodable(gid)]).response
                    { _ in }
                } else {
                    // Use remove for active/waiting/paused tasks
                    aria2.call(method: .remove, params: [AnyEncodable(gid)]).response { _ in }
                }
            }
        }
        // Force local removal immediately to prevent re-appearance during poll delay
        tasks.removeAll(where: { gids.contains($0.gid) })
    }

    func stopTasks(gids: Set<String>) {
        for gid in gids {
            aria2.call(method: .forcePause, params: [AnyEncodable(gid)]).response { _ in }
        }
    }
}
