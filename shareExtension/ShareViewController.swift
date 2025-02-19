import AVFoundation
import MobileCoreServices
import Photos
import UIKit

@objc(PrincipalClassName)
class QwilShareViewController: UIViewController {
  let hostAppBundleIdentifier = "<your app bundler identifier>"
  let shareProtocol = "<your app protocol>"
  let sharedKey = "ShareKey"
  var sharedMedia: [SharedMediaFile] = []
  var sharedText: [String] = []
  let imageContentType = kUTTypeImage as String
  let videoContentType = kUTTypeMovie as String
  let textContentType = kUTTypeText as String
  let urlContentType = kUTTypeURL as String
  let fileURLType = kUTTypeFileURL as String

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    guard
      let extensionItems = extensionContext?.inputItems as? [NSExtensionItem]
    else {
      return
    }

    if let itemProviders = extensionItems.first?.attachments {
      // since the handlers perform the operation within callbacks to an async operation,
      // we need to track completion of tasks and only pass to main app when all are done
      var remaining = itemProviders.count
      let doneCallback = { () -> Void in
        remaining = remaining - 1
        if remaining == 0 {
          self.writeSharedDataAndRedirectToHost()
        }
      }

      for attachment in itemProviders {
        if attachment.hasItemConformingToTypeIdentifier(imageContentType) {
          handleImageAttachment(attachment: attachment, onDone: doneCallback)
        } else if attachment.hasItemConformingToTypeIdentifier(fileURLType) {
          handleFileAttachment(attachment: attachment, onDone: doneCallback)
        } else if attachment.hasItemConformingToTypeIdentifier(
          videoContentType)
        {
          handleVideoAttachment(attachment: attachment, onDone: doneCallback)
        } else if attachment.hasItemConformingToTypeIdentifier(
          textContentType)
        {
          handleTextAttachment(attachment: attachment, onDone: doneCallback)
        } else if attachment.hasItemConformingToTypeIdentifier(urlContentType) {
          handleUrlAttachment(attachment: attachment, onDone: doneCallback)
        } else {
          print(
            "unsupported attachment of type \(attachment.registeredTypeIdentifiers)"
          )
          doneCallback()
        }
      }

    }
  }

  private func handleImageAttachment(
    attachment: NSItemProvider, onDone: @escaping () -> Void
  ) {
    attachment.loadItem(forTypeIdentifier: imageContentType, options: nil) {
      [weak self] data, error in
      if error == nil, let this = self {

        var url: URL? = nil
        if let dataURL = data as? URL {
          url = dataURL
        } else if let imageData = data as? UIImage {
          url = this.saveScreenshot(imageData)
        }

        let newName = this.getFileName(from: url!)
        let newPath = FileManager.default
          .containerURL(
            forSecurityApplicationGroupIdentifier:
              "group.\(this.hostAppBundleIdentifier)")!
          .appendingPathComponent("\(newName)")
        this.copyFile(at: url!, to: newPath)
        this.sharedMedia.append(
          SharedMediaFile(
            path: newPath.absoluteString, fileName: newName, type: .image))

      } else {
        self?.dismissWithError(message: "Failed to access shared image")
      }
      onDone()
    }
  }

  private func documentDirectoryPath() -> URL? {
    return FileManager.default.temporaryDirectory
  }

  private func saveScreenshot(_ image: UIImage) -> URL? {
    var screenshotURL: URL? = nil
    if let screenshotData = image.pngData(),
      let screenshotPath = documentDirectoryPath()?.appendingPathComponent(
        "Screenshot.png")
    {
      try? screenshotData.write(to: screenshotPath)
      screenshotURL = screenshotPath
    }
    return screenshotURL
  }

  private func handleTextAttachment(
    attachment: NSItemProvider, onDone: @escaping () -> Void
  ) {
    attachment.loadItem(forTypeIdentifier: textContentType, options: nil) {
      [weak self] data, error in

      if error == nil, let item = data as? String, let this = self {
        this.sharedText.append(item)
      } else {
        self?.dismissWithError(message: "Failed to access shared text")
      }
    }
  }

  private func handleUrlAttachment(
    attachment: NSItemProvider, onDone: @escaping () -> Void
  ) {
    attachment.loadItem(forTypeIdentifier: urlContentType, options: nil) {
      [weak self] data, error in

      if error == nil, let item = data as? URL, let this = self {
        this.sharedText.append(item.absoluteString)
      } else {
        self?.dismissWithError(message: "Failed to access shared url")
      }
      onDone()
    }
  }

  private func handleVideoAttachment(
    attachment: NSItemProvider, onDone: @escaping () -> Void
  ) {
    attachment.loadItem(forTypeIdentifier: videoContentType, options: nil) {
      [weak self] data, error in

      if error == nil, let url = data as? URL, let this = self {
        // Copy to app directory so main app has access to it without needing extra perms
        let newName = this.getFileName(from: url)
        let newPath = FileManager.default
          .containerURL(
            forSecurityApplicationGroupIdentifier:
              "group.\(this.hostAppBundleIdentifier)")!
          .appendingPathComponent("\(newName)")

        this.copyFile(at: url, to: newPath)

        this.sharedMedia.append(
          SharedMediaFile(
            path: newPath.absoluteString, fileName: newName, type: .file))

      } else {
        self?.dismissWithError(message: "Failed to access shared video")
      }
      onDone()
    }
  }

  private func handleFileAttachment(
    attachment: NSItemProvider, onDone: @escaping () -> Void
  ) {
    attachment.loadItem(forTypeIdentifier: fileURLType, options: nil) {
      [weak self] data, error in

      if error == nil, let url = data as? URL, let this = self {
        // Copy to app directory so main app has access to it without needing extra perms
        let newName = this.getFileName(from: url)
        let newPath = FileManager.default
          .containerURL(
            forSecurityApplicationGroupIdentifier:
              "group.\(this.hostAppBundleIdentifier)")!
          .appendingPathComponent("\(newName)")

        this.copyFile(at: url, to: newPath)

        this.sharedMedia.append(
          SharedMediaFile(
            path: newPath.absoluteString, fileName: newName, type: .file))
      } else {
        self?.dismissWithError(message: "Failed to access shared file")
      }
      onDone()
    }
  }

  private func writeSharedDataAndRedirectToHost() {
    let userDefaults = UserDefaults(
      suiteName: "group.\(self.hostAppBundleIdentifier)")

    if sharedMedia.count > 0 {
      userDefaults?.set(toData(data: self.sharedMedia), forKey: self.sharedKey)
      userDefaults?.synchronize()
      redirectToHostApp(type: .file)
    } else if sharedText.count > 0 {
      userDefaults?.set(self.sharedText, forKey: self.sharedKey)
      userDefaults?.synchronize()
      redirectToHostApp(type: .text)
    } else {
      print("Nothing to share")

      completeRequest(success: false)
    }
  }

  func completeRequest(success: Bool = true) {
    extensionContext?.completeRequest(
      returningItems: [], completionHandler: nil)
  }

  private func dismissWithError(
    title: String = "Error", message: String = "Error loading data"
  ) {
    print("[ERROR] \(message)")
    let alert = UIAlertController(
      title: title, message: message, preferredStyle: .alert)

    let action = UIAlertAction(title: title, style: .cancel) { _ in
      self.dismiss(animated: true, completion: nil)
    }

    alert.addAction(action)
    present(alert, animated: true, completion: nil)
    completeRequest(success: false)
  }

  private func getExtension(from url: URL, type: SharedMediaType) -> String {
    let parts = url.lastPathComponent.components(separatedBy: ".")
    var ex: String? = nil
    if parts.count > 1 {
      ex = parts.last
    }

    if ex == nil {
      switch type {
      case .image:
        ex = "PNG"
      case .video:
        ex = "MP4"
      case .file:
        ex = "TXT"
      }
    }
    return ex ?? "Unknown"
  }

  private func getFileName(from url: URL) -> String {
    var name = url.lastPathComponent

    if name == "" {
      name = UUID().uuidString + "." + getExtension(from: url, type: .file)
    }

    return name
  }

  private func copyFile(at srcURL: URL, to dstURL: URL) {
    do {
      if FileManager.default.fileExists(atPath: dstURL.path) {
        try FileManager.default.removeItem(at: dstURL)
      }
      try FileManager.default.copyItem(at: srcURL, to: dstURL)
    } catch (let error) {
      print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
      dismissWithError(message: "Failed to copy file to application")
    }
  }

  @objc @discardableResult private func openURL(_ url: URL) -> Bool {
    // from https://stackoverflow.com/a/78975759/115845
    var responder: UIResponder? = self
    while responder != nil {
      if let application = responder as? UIApplication {
        if #available(iOS 18.0, *) {
          application.open(url, options: [:], completionHandler: nil)
          return true
        } else {
          return application.perform(#selector(openURL(_:)), with: url) != nil
        }
      }
      responder = responder?.next
    }
    return false
  }

  private func redirectToHostApp(type: RedirectType) {
    guard
      let url = URL(string: "\(shareProtocol)://dataUrl=\(sharedKey)#\(type)")
    else {
      dismissWithError(message: "Failed to address application")
      return  //be safe
    }
    openURL(url)
    completeRequest()
    //    UIApplication.shared.open(
    //      url, options: [:], completionHandler: completeRequest)
  }

  enum RedirectType {
    case text
    case file
    // We don't use "media" as expected by "react-native-receive-sharing-intent" for several reasons.
    //   1. main difference between "media" and "file" is the setting of "duration" and "thumbnail"
    //      which we don't use
    //   2. the design is flawed. "type" is decided based on the last attachment in the list, which
    //      means it could be wrong if both video and file types are multi-selected.
    //case media
  }

  class SharedMediaFile: Codable {
    var path: String  // can be image, video or url path. It can also be text content
    var fileName: String
    var type: SharedMediaType

    init(
      path: String, fileName: String, type: SharedMediaType
    ) {
      self.path = path
      self.type = type
      self.fileName = fileName
    }

    // Debug method to print out SharedMediaFile details in the console
    func toString() {
      print(
        "[SharedMediaFile] \n\tpath: \(self.path)\n\tfileName: \(self.fileName)\n\ttype: \(self.type)"
      )
    }
  }

  enum SharedMediaType: Int, Codable {
    case image
    case video
    case file
  }

  func toData(data: [SharedMediaFile]) -> Data {
    let encodedData = try? JSONEncoder().encode(data)
    return encodedData!
  }
}

extension UIImage {
  func scale(maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
    let maxSize = CGSize(width: maxWidth, height: maxHeight)

    let availableRect = AVFoundation.AVMakeRect(
      aspectRatio: self.size,
      insideRect: .init(origin: .zero, size: maxSize)
    )
    let targetSize = availableRect.size

    // Set scale of renderer so that 1pt == 1px
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

    // Resize the image
    let resized = renderer.image { _ in
      self.draw(in: CGRect(origin: .zero, size: targetSize))
    }

    return resized
  }
}
