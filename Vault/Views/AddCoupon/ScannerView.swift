import SwiftUI
import AVFoundation
import UIKit

// MARK: - Vue principale

struct ScannerView: View {
    let onScan: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var coordinator = CameraCoordinator()
    @State private var status: ScanStatus = .loading
    @State private var showManualEntry = false
    @State private var manualCode = ""

    private enum ScanStatus: Equatable {
        case loading
        case unauthorized
        case scanning
        case found(String)

        static func == (lhs: ScanStatus, rhs: ScanStatus) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.unauthorized, .unauthorized), (.scanning, .scanning): return true
            case (.found(let a), .found(let b)): return a == b
            default: return false
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch status {
            case .loading:
                loadingView
            case .unauthorized:
                unauthorizedView
            case .scanning:
                scanningView
            case .found(let code):
                foundView(code: code)
            }
        }
        .onAppear { checkPermissionAndSetup() }
        .onDisappear { coordinator.stopSession() }
        .sheet(isPresented: $showManualEntry, onDismiss: {
            if case .scanning = status { coordinator.restartSession() }
        }) {
            manualEntrySheet
        }
    }

    // MARK: - Setup caméra

    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { startCamera() } else { status = .unauthorized }
                }
            }
        default:
            status = .unauthorized
        }
    }

    private func startCamera() {
        coordinator.onCodeDetected = { code in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(duration: 0.3, bounce: 0.1)) { status = .found(code) }
        }
        coordinator.configure { success in
            status = success ? .scanning : .unauthorized
        }
    }

    // MARK: - Chargement

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(.white).scaleEffect(1.3)
            Text("Initialisation…")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Permission refusée

    private var unauthorizedView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle().fill(.white.opacity(0.07)).frame(width: 130, height: 130)
                    Circle().fill(.white.opacity(0.04)).frame(width: 100, height: 100)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.55))
                }

                VStack(spacing: 12) {
                    Text("Accès caméra requis")
                        .font(.title2).fontWeight(.bold).foregroundStyle(.white)

                    Text("Vault utilise la caméra uniquement pour lire tes codes promo et QR codes. Rien n'est sauvegardé sans ta validation.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Ouvrir les Réglages", systemImage: "gear")
                        .font(.body).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    showManualEntry = true
                } label: {
                    Text("Saisir le code manuellement")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                }

                // Fermer
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Scan actif

    private var scanningView: some View {
        ZStack {
            CameraPreviewView(session: coordinator.session)
                .ignoresSafeArea()

            ScannerOverlay(frameSize: 260)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Barre supérieure
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.ultraThinMaterial.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Scanner")
                        .font(.headline).foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Instructions
                VStack(spacing: 6) {
                    Text("Positionne le code dans le cadre")
                        .font(.subheadline).fontWeight(.medium).foregroundStyle(.white)
                    Text("QR Code · EAN-13 · EAN-8 · Code 128 · Code 39")
                        .font(.caption2).foregroundStyle(.white.opacity(0.5))
                }
                .padding(.vertical, 12).padding(.horizontal, 20)
                .background(.black.opacity(0.45))
                .clipShape(Capsule())

                // Bouton saisie manuelle
                Button {
                    coordinator.stopSession()
                    showManualEntry = true
                } label: {
                    Label("Saisir manuellement", systemImage: "keyboard")
                        .font(.subheadline).fontWeight(.medium).foregroundStyle(.white)
                        .padding(.horizontal, 22).padding(.vertical, 13)
                        .background(.white.opacity(0.14))
                        .clipShape(Capsule())
                }
                .padding(.top, 20)
                .padding(.bottom, 54)
            }
        }
    }

    // MARK: - Code détecté

    private func foundView(code: String) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle().fill(.green.opacity(0.15)).frame(width: 140, height: 140)
                    Circle().fill(.green.opacity(0.08)).frame(width: 108, height: 108)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(.green)
                }

                VStack(spacing: 10) {
                    Text("Code détecté !")
                        .font(.title2).fontWeight(.bold).foregroundStyle(.white)

                    Text(code)
                        .font(.system(.title3, design: .monospaced)).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onScan(code)
                    dismiss()
                } label: {
                    Text("Utiliser ce code")
                        .font(.body).fontWeight(.semibold)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(.green).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    withAnimation { status = .scanning }
                    coordinator.restartSession()
                } label: {
                    Text("Scanner à nouveau")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 52)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    // MARK: - Sheet saisie manuelle

    private var manualEntrySheet: some View {
        NavigationStack {
            VStack(spacing: 28) {
                ZStack {
                    Circle().fill(.blue.opacity(0.1)).frame(width: 88, height: 88)
                    Image(systemName: "keyboard")
                        .font(.largeTitle).foregroundStyle(.blue)
                }
                .padding(.top, 20)

                VStack(spacing: 6) {
                    Text("Saisie manuelle")
                        .font(.title3).fontWeight(.semibold)
                    Text("Entre le code promo ou le numéro de carte")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                TextField("ex : SAVE20, PROMO2024…", text: $manualCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        showManualEntry = false
                        coordinator.restartSession()
                        status = .scanning
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider") {
                        let code = manualCode.trimmingCharacters(in: .whitespaces)
                        guard !code.isEmpty else { return }
                        showManualEntry = false
                        manualCode = ""
                        onScan(code)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(manualCode.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Prévisualisation caméra (UIViewRepresentable)

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewUIView { VideoPreviewUIView() }

    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {
        uiView.previewLayer.session = session
        uiView.previewLayer.videoGravity = .resizeAspectFill
    }

    final class VideoPreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Overlay du cadre de scan

private struct ScannerOverlay: View {
    let frameSize: CGFloat
    @State private var scanLineY: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            let hx = (geo.size.width - frameSize) / 2
            let hy = (geo.size.height - frameSize) / 2

            ZStack {
                // Fond noir troué par le cadre de scan
                Canvas { ctx, size in
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.65)))
                    ctx.blendMode = .destinationOut
                    ctx.fill(
                        Path(roundedRect: CGRect(x: hx, y: hy, width: frameSize, height: frameSize), cornerRadius: 16),
                        with: .color(.white)
                    )
                }
                .compositingGroup()

                // Coins du cadre
                ScanCornerShape()
                    .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: frameSize, height: frameSize)
                    .position(x: cx, y: cy)

                // Ligne de scan animée
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .green.opacity(0.85), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: frameSize - 12, height: 2)
                        .offset(y: scanLineY)
                }
                .frame(width: frameSize, height: frameSize)
                .clipped()
                .position(x: cx, y: cy)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                scanLineY = frameSize - 2
            }
        }
    }
}

// Coins en L aux quatre angles du cadre
private struct ScanCornerShape: Shape {
    private let armLength: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Haut-gauche
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + armLength))
        p.addLine(to: .init(x: rect.minX, y: rect.minY))
        p.addLine(to: .init(x: rect.minX + armLength, y: rect.minY))
        // Haut-droit
        p.move(to: .init(x: rect.maxX - armLength, y: rect.minY))
        p.addLine(to: .init(x: rect.maxX, y: rect.minY))
        p.addLine(to: .init(x: rect.maxX, y: rect.minY + armLength))
        // Bas-droit
        p.move(to: .init(x: rect.maxX, y: rect.maxY - armLength))
        p.addLine(to: .init(x: rect.maxX, y: rect.maxY))
        p.addLine(to: .init(x: rect.maxX - armLength, y: rect.maxY))
        // Bas-gauche
        p.move(to: .init(x: rect.minX + armLength, y: rect.maxY))
        p.addLine(to: .init(x: rect.minX, y: rect.maxY))
        p.addLine(to: .init(x: rect.minX, y: rect.maxY - armLength))
        return p
    }
}

// MARK: - Coordinateur AVFoundation

final class CameraCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    // nonisolated(unsafe) : propriétés accédées à la fois depuis le fil AVCapture et le main thread
    nonisolated(unsafe) var onCodeDetected: ((String) -> Void)?
    nonisolated(unsafe) let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "vault.camera.session", qos: .userInitiated)
    nonisolated(unsafe) private var isConfigured = false

    func configure(completion: @escaping (Bool) -> Void) {
        guard !isConfigured else {
            sessionQueue.async { [weak self] in self?.session.startRunning() }
            DispatchQueue.main.async { completion(true) }
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            // Input : caméra arrière
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.session.addInput(input)

            // Output : métadonnées (codes)
            let output = AVCaptureMetadataOutput()
            guard self.session.canAddOutput(output) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr, .ean13, .ean8, .code128, .code39, .pdf417, .aztec]

            self.session.commitConfiguration()
            self.isConfigured = true
            self.session.startRunning()
            DispatchQueue.main.async { completion(true) }
        }
    }

    nonisolated func stopSession() {
        sessionQueue.async { [weak self] in self?.session.stopRunning() }
    }

    nonisolated func restartSession() {
        sessionQueue.async { [weak self] in self?.session.startRunning() }
    }

    // nonisolated : requis en Swift 6 pour les protocoles @objc.
    // Le délégué est appelé sur .main (configuré via queue: .main), donc MainActor.assumeIsolated est sûr.
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let code = obj.stringValue,
            !code.isEmpty
        else { return }

        // Arrêt via sessionQueue — pas d'accès à stopSession() (main-actor) depuis ici
        sessionQueue.async { [weak self] in self?.session.stopRunning() }

        // On est sur le main thread (queue: .main), MainActor.assumeIsolated confirme au compilateur
        MainActor.assumeIsolated { [weak self] in
            self?.onCodeDetected?(code)
        }
    }
}
