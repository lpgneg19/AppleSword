import SwiftUI

struct TaskListView: View {
    let status: String
    @Binding var selectedTaskGids: Set<String>
    @Binding var isShowingAddTask: Bool
    @EnvironmentObject var taskStore: TaskStore

    var filteredTasks: [DownloadTask] {
        switch status {
        case "downloading":
            return taskStore.tasks.filter { $0.status == .active }
        case "waiting":
            return taskStore.tasks.filter { $0.status == .waiting }
        case "stopped":
            return taskStore.tasks.filter { $0.status == .paused }
        case "completed":
            return taskStore.tasks.filter { $0.status == .complete || $0.status == .error }
        default:
            return taskStore.tasks
        }
    }

    var body: some View {
        Group {
            if filteredTasks.isEmpty {
                ContentUnavailableView(
                    "暂无任务",
                    systemImage: "tray",
                    description: Text("点击上方 '+' 按钮或拖入链接开始下载")
                )
            } else {
                List(selection: $selectedTaskGids) {
                    ForEach(filteredTasks) { task in
                        TaskRow(task: task)
                            .tag(task.gid)
                            .contextMenu {
                                Button {
                                    if task.status == .active {
                                        taskStore.pauseTasks(gids: [task.gid])
                                    } else {
                                        taskStore.resumeTasks(gids: [task.gid])
                                    }
                                } label: {
                                    Label(
                                        task.status == .active ? "暂停" : "开始",
                                        systemImage: task.status == .active
                                            ? "pause.fill" : "play.fill")
                                }

                                Button {
                                    taskStore.stopTasks(gids: [task.gid])
                                } label: {
                                    Label("停止", systemImage: "stop.fill")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    taskStore.removeTasks(gids: [task.gid])
                                } label: {
                                    Label("删除", systemImage: "trash.fill")
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    let filteredGids = Set(filteredTasks.map { $0.gid })
                    if selectedTaskGids.isSuperset(of: filteredGids) && !filteredGids.isEmpty {
                         selectedTaskGids.subtract(filteredGids)
                    } else {
                         selectedTaskGids.formUnion(filteredGids)
                    }
                }) {
                    let filteredGids = Set(filteredTasks.map { $0.gid })
                    let isAllSelected = selectedTaskGids.isSuperset(of: filteredGids) && !filteredGids.isEmpty
                    
                    Label(
                        isAllSelected ? "取消全选" : "全选",
                        systemImage: isAllSelected ? "checkmark.square.fill" : "checkmark.square"
                    )
                }
                .help("全选 / 取消全选")

                Button(action: { taskStore.resumeTasks(gids: selectedTaskGids) }) {
                    Label("开始", systemImage: "play.fill")
                }
                .disabled(selectedTaskGids.isEmpty)
                .help("开始任务")

                Button(action: { taskStore.pauseTasks(gids: selectedTaskGids) }) {
                    Label("暂停", systemImage: "pause.fill")
                }
                .disabled(selectedTaskGids.isEmpty)
                .help("暂停任务")

                Button(action: { taskStore.stopTasks(gids: selectedTaskGids) }) {
                    Label("停止", systemImage: "stop.fill")
                }
                .disabled(selectedTaskGids.isEmpty)
                .help("停止任务")

                Button(action: {
                    taskStore.removeTasks(gids: selectedTaskGids)
                    selectedTaskGids.removeAll()
                }) {
                    Label("删除", systemImage: "trash.fill")
                }
                .disabled(selectedTaskGids.isEmpty)
                .help("删除任务")

                Button(action: { isShowingAddTask = true }) {
                    Label("新建任务", systemImage: "plus")
                }
                .help("创建新下载任务")

                Button(action: { taskStore.fetchTasks() }) {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .help("刷新列表")
            }
        }
    }
}

struct TaskRow: View {
    let task: DownloadTask

    var body: some View {
        HStack {
            Image(systemName: task.bittorrent != nil ? "arrow.down.doc.fill" : "link.circle.fill")
                .font(.title2)
                .foregroundColor(statusColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    task.bittorrent?.info?.name ?? task.files.first?.path.components(
                        separatedBy: "/"
                    ).last ?? "未知文件"
                )
                .font(.headline)
                .lineLimit(1)

                ProgressView(value: Double(task.completedLength), total: Double(task.totalLength))
                    .progressViewStyle(.linear)

                HStack {
                    Text(formatBytes(task.completedLength) + " / " + formatBytes(task.totalLength))
                    Spacer()
                    Text(formatBytes(task.downloadSpeed) + "/s")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch task.status {
        case .active: return .accentColor
        case .waiting: return .orange
        case .paused: return .gray
        case .complete: return .green
        case .error: return .red
        case .removed: return .secondary
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
