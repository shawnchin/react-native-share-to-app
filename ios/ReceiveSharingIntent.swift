import Foundation
import Photos
import UIKit

@objc(ReceiveSharingIntent)
class ReceiveSharingIntent: NSObject {

    private var latestMedia: [SharedMediaFile]? = nil
    private var latestText: String? = nil
    let maxImageDim = 1200 as CGFloat
    let compressionQuality = 0.5

    @objc
    func getFileNames(
        _ url: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        let fileUrl = URL(string: url)
        let json = handleUrl(url: fileUrl)
        if json == "error" {
            let error = NSError(domain: "", code: 400, userInfo: nil)
            reject("message", "file type is Invalid", error)
        } else if json == "invalid group name" {
            let error = NSError(domain: "", code: 400, userInfo: nil)
            reject(
                "message",
                "invalid group name. Please check your share extention bundle name is same as `group.mainbundle name`  ",
                error)
        } else {
            resolve(json)
        }
    }

    private func handleUrl(url: URL?) -> String? {
        if let url = url {
            let appDomain = Bundle.main.bundleIdentifier!
            let userDefaults = UserDefaults(suiteName: "group.\(appDomain)")
            if url.fragment == "file" {
                if let key = url.host?.components(separatedBy: "=").last,
                    let json = userDefaults?.object(forKey: key) as? Data
                {
                    let sharedArray = decode(data: json)
                    let sharedMediaFiles: [SharedMediaFile] =
                        sharedArray.compactMap {
                            if let path = getAbsolutePath(for: $0.path) {
                                if $0.type == .image {
                                    if let compressed =
                                        self.rescaleAndCompressImage(
                                            path: path)
                                    {
                                        return SharedMediaFile.init(
                                            path: compressed, type: $0.type)
                                    } else {
                                        return nil
                                    }
                                } else {
                                    return SharedMediaFile.init(
                                        path: path, type: $0.type)
                                }
                            } else {
                                return nil
                            }

                        }
                    latestMedia = sharedMediaFiles
                    let json = toJson(data: latestMedia)
                    return json
                }
            } else if url.fragment == "text" {
                if let key = url.host?.components(separatedBy: "=").last,
                    let sharedArray = userDefaults?.object(forKey: key)
                        as? [String]
                {
                    latestText = sharedArray.joined(separator: ",")

                    let optionalString = latestText
                    if let unwrapped = optionalString {
                        let text = "text:" + unwrapped
                        return text
                    }
                    return latestText!

                }
            } else {
                latestText = url.absoluteString

                let optionalString = latestText
                // now unwrap it
                if let unwrapwebUrl = optionalString {
                    let webUrl = "webUrl:" + unwrapwebUrl
                    return webUrl
                }
            }
            return "error"
        }
        return "invalid group name"
    }

    private func rescaleAndCompressImage(path: String) -> String? {
        do {
            // Read image data
            if let fileData = try? Data.init(contentsOf: URL(string: path)!) {
                if let image = UIImage(data: fileData) {
                    // rescale image and write as compressed JPG
                    if let compressed = image.scale(
                        maxWidth: maxImageDim, maxHeight: maxImageDim
                    ).jpegData(compressionQuality: compressionQuality) {
                        // create a new path to write compressed file to
                        let oldFilename = (path as NSString).lastPathComponent
                        let filenamePrefix = (oldFilename as NSString)
                            .deletingPathExtension
                        let newPath = getFilepathInTempDir(
                            filenamePrefix: filenamePrefix, ext: "jpg")

                        // write to out compressed image and return path
                        try compressed.write(to: newPath)
                        return newPath.path
                    }
                }
            }
        } catch (let error) {
            print("Image compression failed: \(error)")
        }
        return nil
    }

    private func getFilepathInTempDir(filenamePrefix: String, ext: String)
        -> URL
    {
        // If possible, we try to keep the same name
        var url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "\(filenamePrefix).\(ext)")

        // If it clashes with an existing file, add a suffix to make it unique
        if FileManager.default.fileExists(atPath: url.path) {
            url = FileManager.default.temporaryDirectory.appendingPathComponent(
                "\(filenamePrefix)\(Date().timestamp()).\(ext)")
        }

        return url
    }

    private func getAbsolutePath(for identifier: String) -> String? {
        if identifier.starts(with: "file://")
            || identifier.starts(with: "/var/mobile/Media")
            || identifier.starts(with: "/private/var/mobile")
        {
            return identifier
        }
        let phAsset = PHAsset.fetchAssets(
            withLocalIdentifiers: [identifier], options: .none
        ).firstObject
        if phAsset == nil {
            return nil
        }
        let (url, _) = getFullSizeImageURLAndOrientation(for: phAsset!)
        return url
    }

    private func getFullSizeImageURLAndOrientation(for asset: PHAsset) -> (
        String?, Int
    ) {
        var url: String? = nil
        var orientation: Int = 0
        let semaphore = DispatchSemaphore(value: 0)
        let options2 = PHContentEditingInputRequestOptions()
        options2.isNetworkAccessAllowed = true
        asset.requestContentEditingInput(with: options2) { (input, info) in
            orientation = Int(input?.fullSizeImageOrientation ?? 0)
            url = input?.fullSizeImageURL?.path
            semaphore.signal()
        }
        semaphore.wait()
        return (url, orientation)
    }

    private func decode(data: Data) -> [SharedMediaFile] {
        let encodedData = try? JSONDecoder().decode(
            [SharedMediaFile].self, from: data)
        return encodedData!
    }

    private func toJson(data: [SharedMediaFile]?) -> String? {
        if data == nil {
            return nil
        }
        let encodedData = try? JSONEncoder().encode(data)
        let json = String(data: encodedData!, encoding: .utf8)!
        return json
    }

    class SharedMediaFile: Codable {
        var path: String
        var type: SharedMediaType

        init(path: String, type: SharedMediaType) {
            self.path = path
            self.type = type
        }
    }

    enum SharedMediaType: Int, Codable {
        case image
        case video
        case file
    }

    @objc
    func clearFileNames() {
        print("clearFileNames")
    }

    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

extension Date {
    func timestamp() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
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
