//
//  PalmFaceReadingView.swift
//  AiFortuneTelling
//

import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct PalmFaceReadingView: View {
    @EnvironmentObject private var appState: FortuneAppState
    @Binding var path: [AppRoute]

    @State private var palmImage: UIImage?
    @State private var faceImage: UIImage?
    @State private var palmPhotoItem: PhotosPickerItem?
    @State private var facePhotoItem: PhotosPickerItem?
    @State private var activeCamera: CaptureKind?
    @State private var permissionMessage: String?
    @State private var validationMessage: String?
    @State private var isSubmitting = false
    @State private var currentTaskID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DisclosureBanner(
                    title: "图片采集用途",
                    message: "掌纹与面部照片会在确认后压缩上传，用于本次服务端分析。你可以取消、重拍，并在历史记录中删除任务数据。"
                )

                ImageCaptureSlot(
                    title: "掌纹照片",
                    image: palmImage,
                    cameraAction: { requestCamera(.palm) },
                    libraryItem: $palmPhotoItem
                )
                .onChange(of: palmPhotoItem) { _, newValue in
                    loadPhoto(newValue, target: .palm)
                }

                ImageCaptureSlot(
                    title: "面相照片",
                    image: faceImage,
                    cameraAction: { requestCamera(.face) },
                    libraryItem: $facePhotoItem
                )
                .onChange(of: facePhotoItem) { _, newValue in
                    loadPhoto(newValue, target: .face)
                }

                if let permissionMessage {
                    ErrorBanner(message: permissionMessage, actionTitle: "打开系统设置") {
                        openSettings()
                    }
                }
                if let validationMessage {
                    ErrorBanner(message: validationMessage)
                }
                if let error = appState.latestError {
                    ErrorBanner(message: error.localizedDescription)
                }
                if isSubmitting {
                    LoadingOverlay(title: "正在上传并生成掌纹面相", task: currentTaskID.flatMap { appState.taskStates[$0] })
                }

                HStack {
                    Button {
                        palmImage = nil
                        faceImage = nil
                    } label: {
                        Label("取消", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    PrimaryActionButton(title: "确认上传", icon: "arrow.up.circle", isLoading: isSubmitting) {
                        submit()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("掌纹面相")
        .sheet(item: $activeCamera) { kind in
            CameraImagePicker(image: imageBinding(for: kind))
        }
    }

    private func requestCamera(_ kind: CaptureKind) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            validationMessage = "当前设备不可用相机，请改用相册导入"
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            activeCamera = kind
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        activeCamera = kind
                    } else {
                        permissionMessage = "相机权限已拒绝，无法拍摄掌纹或面相照片"
                    }
                }
            }
        case .denied, .restricted:
            permissionMessage = "相机权限已拒绝，无法拍摄掌纹或面相照片"
        @unknown default:
            permissionMessage = "相机权限状态异常，请前往系统设置确认"
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?, target: CaptureKind) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    switch target {
                    case .palm:
                        palmImage = image
                    case .face:
                        faceImage = image
                    }
                }
            }
        }
    }

    private func submit() {
        guard let palmData = palmImage?.jpegData(compressionQuality: 0.72),
              let faceData = faceImage?.jpegData(compressionQuality: 0.72) else {
            validationMessage = "请先提供掌纹和面相照片"
            return
        }

        validationMessage = nil
        isSubmitting = true
        Task {
            let request = PalmFaceReadingRequest(palmImageData: palmData, faceImageData: faceData)
            let taskID = await appState.submitPalmFace(request)
            await MainActor.run {
                isSubmitting = false
                if let taskID {
                    currentTaskID = taskID
                    path.append(.result(taskID))
                }
            }
        }
    }

    private func imageBinding(for kind: CaptureKind) -> Binding<UIImage?> {
        Binding {
            kind == .palm ? palmImage : faceImage
        } set: { image in
            if kind == .palm {
                palmImage = image
            } else {
                faceImage = image
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

enum CaptureKind: Identifiable {
    case palm
    case face

    var id: String {
        switch self {
        case .palm:
            return "palm"
        case .face:
            return "face"
        }
    }
}

private struct ImageCaptureSlot: View {
    let title: String
    let image: UIImage?
    let cameraAction: () -> Void
    @Binding var libraryItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("等待选择图片")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            HStack {
                Button(action: cameraAction) {
                    Label("拍摄", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                PhotosPicker(selection: $libraryItem, matching: .images) {
                    Label("相册", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .formSectionStyle()
    }
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
