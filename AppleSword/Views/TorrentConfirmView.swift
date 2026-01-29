import SwiftUI

struct TorrentConfirmView: View {
    let task: DownloadTask
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var settings: SettingsStore
    @State private var downloadPath: String
    var onConfirm: (String, Set<String>) -> Void
    var onCancel: () -> Void

    init(
        task: DownloadTask, onConfirm: @escaping (String, Set<String>) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.task = task
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _downloadPath = State(initialValue: task.dir)
    }

    @State private var selectedFileIndices: Set<String> = []
    @State private var isAllSelected: Bool = true {
        didSet {
            if isAllSelected {
                selectedFileIndices = Set(task.files.map { $0.index })
            } else {
                selectedFileIndices = []
            }
        }
    }

    // Sort files by path for better display order
    private var sortedFiles: [DownloadFile] {
        task.files.sorted { $0.path < $1.path }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("确认下载种子")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Torrent Info
                    HStack(spacing: 16) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                            .symbolRenderingMode(.hierarchical)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.bittorrent?.info?.name ?? "未知种子")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineLimit(2)

                            Text(
                                "总大小: \(ByteCountFormatterUtil.string(fromByteCount: task.totalLength))"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Download Path Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("下载路径")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            TextField("", text: $downloadPath)
                                .textFieldStyle(.roundedBorder)
                            Button("选择...") {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = true
                                panel.canChooseFiles = false
                                if panel.runModal() == .OK {
                                    downloadPath = panel.url?.path ?? downloadPath
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal)

                    // Files List Header
                    HStack {
                        Text("文件列表 (\(task.files.count))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: {
                            if selectedFileIndices.count == task.files.count {
                                selectedFileIndices.removeAll()
                            } else {
                                selectedFileIndices = Set(task.files.map { $0.index })
                            }
                        }) {
                            Text(selectedFileIndices.count == task.files.count ? "取消全选" : "全选")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal)

                    // Files List
                    VStack(spacing: 0) {
                        ForEach(sortedFiles, id: \.index) { file in
                            HStack {
                                Toggle(
                                    "",
                                    isOn: Binding(
                                        get: { selectedFileIndices.contains(file.index) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedFileIndices.insert(file.index)
                                            } else {
                                                selectedFileIndices.remove(file.index)
                                            }
                                        }
                                    )
                                )
                                .labelsHidden()

                                Image(systemName: "doc")
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.path.components(separatedBy: "/").last ?? file.path)
                                        .font(.system(size: 13))
                                        .lineLimit(1)
                                    // Show directory hint if in subdirectory
                                    if file.path.contains("/") {
                                        Text(file.path)
                                            .font(.caption2)
                                            .foregroundColor(.tertiaryLabel)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                }

                                Spacer()
                                Text(ByteCountFormatterUtil.string(fromByteCount: file.length))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())  // Make entire row clickable for toggle? Maybe not standard.
                            .onTapGesture {
                                // Optional: Tap row to toggle
                                if selectedFileIndices.contains(file.index) {
                                    selectedFileIndices.remove(file.index)
                                } else {
                                    selectedFileIndices.insert(file.index)
                                }
                            }

                            if file.index != sortedFiles.last?.index {
                                Divider().padding(.leading, 40)
                            }
                        }
                    }
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }

            Divider()

            // Footer
            HStack {
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                if selectedFileIndices.isEmpty {
                    Text("请至少选择一个文件")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.trailing)
                }

                Button("立即下载") {
                    // Pass selected indices via options?
                    // Currently onConfirm only returns path.
                    // We need to support selected indexes.
                    // But standard Aria2 addTorrent allows --select-file=1,2,4...
                    // The onConfirm callback signature is (String) -> Void.
                    // We might need to modify it or just trust that TaskStore handles it?
                    // TaskStore.resumeTask takes options.
                    // We need to modify MainView usage or change onConfirm to return options.
                    // But resizing this signature is complex via replace.
                    // Let's modify MainView to handle it? OR:
                    // We can change `onConfirm` signature in a separate edit if needed, OR:
                    // We can just rely on setting the options in TaskStore inside MainView.
                    // But wait, TaskStore calls resumeTask.
                    // Issue: MainView creates TorrentConfirmView. MainView passes closure.
                    // Closure in MainView calls resumeTask.
                    // So we need to pass selected indices out.
                    onConfirm(downloadPath)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFileIndices.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 550, height: 650)
        .onAppear {
            // Init selection
            selectedFileIndices = Set(task.files.map { $0.index })
        }
    }
}
