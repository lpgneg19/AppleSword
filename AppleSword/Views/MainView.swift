import SwiftUI

struct MainView: View {
    @State private var selection: String? = "downloading"
    @State private var isShowingAddTask = false
    @State private var selectedTaskGids: Set<String> = []
    @State private var confirmGid: String? = nil
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section(LocalizedStringKey("下载状态")) {
                    NavigationLink(value: "downloading") {
                        Label(LocalizedStringKey("正在下载"), systemImage: "arrow.down.circle")
                    }
                    NavigationLink(value: "waiting") {
                        Label(LocalizedStringKey("等待下载"), systemImage: "clock")
                    }
                    NavigationLink(value: "stopped") {
                        Label(LocalizedStringKey("已停止"), systemImage: "stop.circle")
                    }
                    NavigationLink(value: "completed") {
                        Label(LocalizedStringKey("已完成"), systemImage: "checkmark.circle")
                    }
                }
            }
            .listStyle(.sidebar)
        } detail: {
            ZStack(alignment: .bottom) {
                if let selection = selection {
                    TaskListView(
                        status: selection,
                        selectedTaskGids: $selectedTaskGids,
                        isShowingAddTask: $isShowingAddTask
                    )
                } else {
                    ContentUnavailableView(LocalizedStringKey("请选择一个分类"), systemImage: "sidebar.left")
                }

                // Bottom-up Task Details Popup
                if selectedTaskGids.count == 1,
                    let gid = selectedTaskGids.first,
                    let task = taskStore.tasks.first(where: { $0.gid == gid })
                {

                    TaskDetailView(task: task) {
                        withAnimation(.spring()) {
                            selectedTaskGids.removeAll()
                        }
                    }
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -5)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .zIndex(10)
                }
            }
        }
        .sheet(isPresented: $isShowingAddTask) {
            AddTaskView()
                .environmentObject(taskStore)
        }
        .sheet(
            item: Binding(
                get: { confirmGid.map { IdentifiableString(id: $0) } },
                set: { confirmGid = $0?.id }
            )
        ) { item in
            if let task = taskStore.tasks.first(where: { $0.gid == item.id }) {
                TorrentConfirmView(task: task) { path in
                    taskStore.resumeTask(gid: item.id, options: ["dir": path])
                    confirmGid = nil
                } onCancel: {
                    taskStore.removeTasks(gids: [item.id])
                    confirmGid = nil
                }
                .environmentObject(taskStore)
                .environmentObject(settings)
            }
        }
        .dropDestination(for: URL.self) { items, location in
            let torrents = items.filter { $0.pathExtension.lowercased() == "torrent" }
            for torrent in torrents {
                taskStore.addTorrent(at: torrent.path)
            }
            return !torrents.isEmpty
        }
        .onChange(of: taskStore.lastAddedGid) {
            if let gid = taskStore.lastAddedGid {
                let task = taskStore.tasks.first(where: { $0.gid == gid })
                let isTorrent = task?.bittorrent != nil

                withAnimation(.spring()) {
                    if isTorrent && task?.status == .waiting {
                        confirmGid = gid
                    } else {
                        selectedTaskGids = [gid]
                    }
                    taskStore.lastAddedGid = nil
                }
            }
        }
        .onChange(of: selection) {
            withAnimation(.spring()) {
                selectedTaskGids.removeAll()
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .overlay(alignment: .bottom) {
            if let error = taskStore.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("引擎错误: \(error)")
                    Spacer()
                    Button("重试") {
                        taskStore.lastError = nil
                        EngineManager.shared.restart()
                    }
                    .buttonStyle(.link)
                }
                .padding(8)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
            } else if !taskStore.isConnected {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                    Text(LocalizedStringKey("正在连接引擎..."))
                    Spacer()
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
            }
        }
    }
}

struct IdentifiableString: Identifiable {
    let id: String
}
