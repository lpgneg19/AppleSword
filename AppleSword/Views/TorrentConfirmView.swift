import SwiftUI

struct TorrentConfirmView: View {
    let task: DownloadTask
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var settings: SettingsStore
    @State private var downloadPath: String
    var onConfirm: (String) -> Void
    var onCancel: () -> Void

    init(task: DownloadTask, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void)
    {
        self.task = task
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _downloadPath = State(initialValue: task.dir)
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

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.bittorrent?.info?.name ?? "未知种子")
                                .font(.title3)
                                .bold()
                                .lineLimit(2)

                            Text(ByteCountFormatterUtil.string(fromByteCount: task.totalLength))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

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

                    // Files List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("文件列表 (\(task.files.count))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 0) {
                            ForEach(task.files, id: \.index) { file in
                                HStack {
                                    Image(systemName: "doc")
                                        .foregroundColor(.secondary)
                                    Text((file.path as NSString).lastPathComponent)
                                        .font(.system(size: 13))
                                    Spacer()
                                    Text(ByteCountFormatterUtil.string(fromByteCount: file.length))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)

                                if file.index != task.files.last?.index {
                                    Divider().padding(.horizontal)
                                }
                            }
                        }
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }

            Divider()

            // Footer
            HStack {
                Button("取消下载") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("立即下载") {
                    onConfirm(downloadPath)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 500, height: 600)
    }
}
