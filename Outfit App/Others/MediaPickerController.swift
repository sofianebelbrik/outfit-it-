
import UIKit
import AVFoundation
import MobileCoreServices

public enum MediaPickerControllerType {
	case imageOnly
	case imageAndVideo
}

@objc public protocol MediaPickerControllerDelegate {
	@objc optional func mediaPickerControllerDidPickImage(_ image: UIImage)
	@objc optional func mediaPickerControllerDidPickVideo(url: URL, data: Data, thumbnail: UIImage)
}

open class MediaPickerController: NSObject {
	
	// MARK: - Public
	
	open weak var delegate: MediaPickerControllerDelegate?
	
	public init(type: MediaPickerControllerType, presentingViewController controller: UIViewController) {
		self.type = type
		self.presentingController = controller
		self.mediaPicker = UIImagePickerController()
		super.init()
		self.mediaPicker.delegate = self
	}
	
	open func show() {
		let actionSheet = self.optionsActionSheet
		self.presentingController.present(actionSheet, animated: true, completion: nil)
//        self.mediaPicker.sourceType = UIImagePickerController.SourceType.photoLibrary
//        self.mediaPicker.mediaTypes = self.chooseExistingMediaTypes
//        self.presentingController.present(self.mediaPicker, animated: true, completion: nil)
	}
	
	// MARK: - Private
	
	fileprivate let presentingController: UIViewController
	fileprivate let type: MediaPickerControllerType
	fileprivate let mediaPicker: UIImagePickerController
	
}

extension MediaPickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	// MARK: - UIImagePickerControllerDelegate
	
	public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		self.dismiss()
			let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
			self.delegate?.mediaPickerControllerDidPickImage?(chosenImage)
	}
	
	public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.dismiss()
	}
	
	// MARK: - UINavigationControllerDelegate
	
	public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		UIApplication.shared.statusBarStyle = .lightContent
	}
	
}

// MARK: - Private

private extension MediaPickerController {
	
	var optionsActionSheet: UIAlertController {
        let actionSheet = UIAlertController(title: Strings.Title, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
		self.addChooseExistingMediaActionToSheet(actionSheet)
		
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			self.addTakePhotoActionToSheet(actionSheet)
			if self.type == .imageAndVideo {
				self.addTakeVideoActionToSheet(actionSheet)
			}
		}
		self.addCancelActionToSheet(actionSheet)
		return actionSheet
	}
	
	func addChooseExistingMediaActionToSheet(_ actionSheet: UIAlertController) {
        let chooseGallery = UIAlertAction(title: "Gallery", style: UIAlertAction.Style.default) { (_) -> Void in
            self.mediaPicker.sourceType = UIImagePickerController.SourceType.photoLibrary
			self.mediaPicker.mediaTypes = self.chooseExistingMediaTypes
			self.presentingController.present(self.mediaPicker, animated: true, completion: nil)
		}
        
        let chooseCamera = UIAlertAction(title: "Camera", style: UIAlertAction.Style.default) { (_) -> Void in
            self.mediaPicker.sourceType = UIImagePickerController.SourceType.camera
            self.mediaPicker.mediaTypes = self.chooseExistingMediaTypes
            self.presentingController.present(self.mediaPicker, animated: true, completion: nil)
        }
		actionSheet.addAction(chooseGallery)
        actionSheet.addAction(chooseCamera)
	}
	
	func addTakePhotoActionToSheet(_ actionSheet: UIAlertController) {
        let takePhotoAction = UIAlertAction(title: Strings.TakePhoto, style: UIAlertAction.Style.default) { (_) -> Void in
            self.mediaPicker.sourceType = UIImagePickerController.SourceType.camera
			self.mediaPicker.mediaTypes = [kUTTypeImage as String]
			self.presentingController.present(self.mediaPicker, animated: true, completion: nil)
		}
		actionSheet.addAction(takePhotoAction)
	}
	
	func addTakeVideoActionToSheet(_ actionSheet: UIAlertController) {
        let takeVideoAction = UIAlertAction(title: Strings.TakeVideo, style: UIAlertAction.Style.default) { (_) -> Void in
            self.mediaPicker.sourceType = UIImagePickerController.SourceType.camera
			self.mediaPicker.mediaTypes = [kUTTypeMovie as String]
			self.presentingController.present(self.mediaPicker, animated: true, completion: nil)
		}
		actionSheet.addAction(takeVideoAction)
	}
	
	func addCancelActionToSheet(_ actionSheet: UIAlertController) {
		let cancel = Strings.Cancel
        let cancelAction = UIAlertAction(title: cancel, style: UIAlertAction.Style.cancel, handler: nil)
		actionSheet.addAction(cancelAction)
	}
	
	func dismiss() {
		DispatchQueue.main.async {
			self.presentingController.dismiss(animated: true, completion: nil)
		}
	}
	
	var chooseExistingText: String {
		switch self.type {
		case .imageOnly: return Strings.ChoosePhoto
		case .imageAndVideo: return Strings.ChoosePhotoOrVideo
		}
	}
	
	var chooseExistingMediaTypes: [String] {
		switch self.type {
		case .imageOnly: return [kUTTypeImage as String]
		case .imageAndVideo: return [kUTTypeImage as String, kUTTypeMovie as String]
		}
	}
	
	// MARK: - Constants
	
	struct Strings {
        static let Title = NSLocalizedString("Please Select a Option", comment: "Title for a generic action sheet for picking media from the device.")
		static let ChoosePhoto = NSLocalizedString("Choose existing photo", comment: "Text for an option that lets the user choose an existing photo in a generic action sheet for picking media from the device.")
		static let ChoosePhotoOrVideo = NSLocalizedString("Choose existing photo or video", comment: "Text for an option that lets the user choose an existing photo or video in a generic action sheet for picking media from the device.")
        static let TakePhoto = NSLocalizedString("Take a photo", comment: "Text for an option that lets the user take a picture with the device camera in a generic action sheet for picking media from the device.")
		static let TakeVideo = NSLocalizedString("Take a video", comment: "Text for an option that lets the user take a video with the device camera in a generic action sheet for picking media from the device.")
		static let Cancel = NSLocalizedString("Cancel", comment: "Text for the 'cancel' action in a generic action sheet for picking media from the device.")
	}
	
}

private extension URL {
	
	func generateThumbnail() -> UIImage {
		let asset = AVAsset(url: self)
		let generator = AVAssetImageGenerator(asset: asset)
		generator.appliesPreferredTrackTransform = true
		var time = asset.duration
		time.value = 0
		let imageRef = try? generator.copyCGImage(at: time, actualTime: nil)
		let thumbnail = UIImage(cgImage: imageRef!)
		return thumbnail
	}
	
}
