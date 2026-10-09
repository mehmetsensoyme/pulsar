import SwiftUI

public final class WarpBenchmarkViewModel: ObservableObject {
    @Published public var selectedThreads: Int = ProcessInfo.processInfo.processorCount
    public init() {}
}

public struct WarpBenchmarkView: View {
    @ObservedObject var bench = BenchmarkService.shared
    @StateObject private var vm = WarpBenchmarkViewModel()
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 0) {
            // Sci-Fi Başlık
            HStack {
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 24))
                    .shadow(color: .cyan.opacity(0.8), radius: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text("PULSAR WARP CORE BENCHMARK")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                    Text("Apple Silicon Donanım Sıkıştırma ve Açma Hız Testi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Kapat") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Warp Core Göstergesi (Sci-Fi Gauge)
                    ZStack {
                        // Dış halka
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.blue, .purple, .pink, .cyan, .blue]),
                                    center: .center
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 170, height: 170)
                            .rotationEffect(.degrees(bench.isRunning ? 360 : 0))
                            .animation(bench.isRunning ? .linear(duration: 3).repeatForever(autoreverses: false) : .default, value: bench.isRunning)
                            .opacity(bench.isRunning ? 1.0 : 0.4)

                        // İç Skor
                        VStack(spacing: 4) {
                            Text("WARP PUANI")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)

                            Text("\(bench.currentResult.warpScore)")
                                .font(.system(size: 32, weight: .black, design: .monospaced))
                                .foregroundColor(.primary)

                            Text("MIPS")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 12)

                    // Canlı Durum Metni
                    Text(bench.progressText)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(bench.isRunning ? .cyan : .secondary)

                    Divider()

                    // Donanım Verileri Kartları
                    HStack(spacing: 12) {
                        MetricCard(
                            title: "İŞLEMCİ",
                            value: bench.currentResult.cpuModel.isEmpty ? "Apple Silicon" : bench.currentResult.cpuModel,
                            icon: "cpu"
                        )
                        MetricCard(
                            title: "İŞ PARÇACIĞI",
                            value: "\(bench.currentResult.threads) Çekirdek",
                            icon: "square.grid.3x3.fill"
                        )
                        MetricCard(
                            title: "BELLEK",
                            value: "\(bench.currentResult.ramSizeMB > 0 ? "\(bench.currentResult.ramSizeMB) MB" : "Birleşik Bellek")",
                            icon: "memorychip"
                        )
                    }

                    // Sıkıştırma ve Açma Skorları
                    HStack(spacing: 16) {
                        SpeedGaugeCard(
                            title: "SIKIŞTIRMA (COMPRESS)",
                            speed: bench.currentResult.compressSpeedKBps,
                            mips: bench.currentResult.compressMIPS,
                            color: .blue
                        )
                        SpeedGaugeCard(
                            title: "AÇMA (DECOMPRESS)",
                            speed: bench.currentResult.decompressSpeedKBps,
                            mips: bench.currentResult.decompressMIPS,
                            color: .purple
                        )
                    }

                    // Geçmiş Testler Listesi
                    if !bench.pastRuns.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ÖNCEKİ TEST SKORLARI")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)

                            ForEach(Array(bench.pastRuns.prefix(3).enumerated()), id: \.offset) { _, run in
                                HStack {
                                    Text("\(run.cpuModel) (\(run.threads)T)")
                                        .font(.system(size: 11))
                                    Spacer()
                                    Text("\(run.warpScore) MIPS")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.cyan)
                                }
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Alt Kontrol Butonları
            HStack {
                HStack(spacing: 8) {
                    Text("Çekirdek:")
                        .font(.system(size: 11))
                    Stepper("\(vm.selectedThreads)", value: $vm.selectedThreads, in: 1...ProcessInfo.processInfo.processorCount)
                        .disabled(bench.isRunning)
                }

                Spacer()

                if bench.isRunning {
                    Button("İptal Et") {
                        bench.cancel()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: {
                        bench.startBenchmark(threads: vm.selectedThreads)
                    }) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Warp Testini Başlat")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 580)
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.cyan)
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

private struct SpeedGaugeCard: View {
    let title: String
    let speed: Int
    let mips: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(color)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(mips)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                Text("MIPS")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            if speed > 0 {
                Text(String(format: "%.1f MB/s", Double(speed) / 1024.0))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
