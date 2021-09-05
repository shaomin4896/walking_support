//  LiveFaceDetect
//
//  Created by Mohammed Azeem Azeez on 18/02/2020.
//  Copyright © 2020 Blue Mango Global. All rights reserved.
//

import AVFoundation
import UIKit
import Vision
import JJFloatingActionButton
import Firebase

var db:Firestore!

class FaceDetectionViewController: UIViewController {
    var sequenceHandler = VNSequenceRequestHandler()
    var captureImage: Bool?
    @IBOutlet var faceView: FaceView!
    @IBOutlet var faceLaserLabel: UILabel!
    
    @IBOutlet weak var processImageView: UIVisualEffectView!
    @IBOutlet weak var scanFaceView: UIVisualEffectView!
    
    
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var faceImage: UIImage!
    var imageRect = CGRect()
    let dataOutputQueue = DispatchQueue(
        label: "video data queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem)
    
    var faceViewHidden = false
    
    var maxX: CGFloat = 0.0
    var midY: CGFloat = 0.0
    var maxY: CGFloat = 0.0
    
    // FaceLocation In this View
    var FaceCGRect : CGRect? = nil
    var AuthIO:FaceAuthIO = FaceAuthIO(api_key: "884e4a98-9ac9-45bb-9d41-3dba52f9e4f1", groupid: "FG202012020510258562949594")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureImage = false
        configureCaptureSession()
        processImageView.isHidden = true
        scanFaceView.isHidden = true
        
        
        maxX = view.bounds.maxX
        midY = view.bounds.midY
        maxY = view.bounds.maxY
        
        session.startRunning()
        
        addFloatingButtonComponents()
        
        db = Firestore.firestore()
    }
    // MARK: - Floating Button
    func addFloatingButtonComponents() -> Void {
        
        let actionButton = JJFloatingActionButton()

        actionButton.addItem(title: "login", image: UIImage(systemName: "arrow.clockwise")?.withRenderingMode(.alwaysTemplate)) { item in
            self.faceImage.face.crop { [self] result in
                switch result {
                case .success(let faces):
                    // When the `Vision` successfully find faces, and `FaceCropper` cropped it.
                    // `faces` argument is a collection of cropped images.
                    let ImgBase64String = self.toBase64String(Image: faces[0])
                    AuthIO.authFace(base64imageStr: ImgBase64String, completion:{ id,score in
                        DispatchQueue.main.async {
                            if score > 0.9{
                                let controller = UIAlertController(title: "登入成功", message: "Welcome \(id)", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                controller.addAction(okAction)
                                present(controller, animated: true, completion: nil)
                            }else{
                                let controller = UIAlertController(title: "登入失敗", message: "", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                controller.addAction(okAction)
                                present(controller, animated: true, completion: nil)
                                
                            }
                        }
                    })
                    break
                case .notFound:
                    print("No faces")
                    break
                case .failure(let error):
                    // When the any error occured, `result` will be `failure`.
                    print(error)
                    break
                }
            }
        }

        actionButton.addItem(title: "Signup", image: UIImage(systemName: "arrow.swap")?.withRenderingMode(.alwaysTemplate)) { item in
            func GetName(completion:@escaping (String)->()) {
                // 建立一個提示框
                let alertController = UIAlertController(
                    title: "Signup",
                    message: "Input username",
                    preferredStyle: .alert)
                
                // 建立輸入框
                alertController.addTextField {
                    (textField: UITextField!) -> Void in
                    textField.placeholder = "username:"
                }
                // 建立[取消]按鈕
                let cancelAction = UIAlertAction(
                    title: "取消",
                    style: .cancel,
                    handler: nil)
                alertController.addAction(cancelAction)
                
                // 建立[登入]按鈕
                let okAction = UIAlertAction(
                    title: "送出",
                    style: UIAlertAction.Style.default) {
                    (action: UIAlertAction!) -> Void in
                    let acc =
                        (alertController.textFields?.first)!
                        as UITextField
                    completion(acc.text!)
                }
                alertController.addAction(okAction)
                
                // 顯示提示框
                self.present(
                    alertController,
                    animated: true,
                    completion: nil)
            }
            self.faceImage.face.crop { [self] result in
                switch result {
                case .success(let faces):
                    // When the `Vision` successfully find faces, and `FaceCropper` cropped it.
                    // `faces` argument is a collection of cropped images.
                    let ImgBase64String = self.toBase64String(Image: faces[0])
                    GetName(completion: { username in
                        AuthIO.newFace(base64imageStr: ImgBase64String, nickname: username ,completion: { faceid in
                            DispatchQueue.main.async {
                                let dbContext = FirebaseIO()
                                
                                dbContext.addnew(username: username, faceID: faceid, completion: {
                                    let alertController = UIAlertController(
                                        title: "註冊成功",
                                        message: "\(faceid)\nWelcome\(username)",
                                        preferredStyle: .alert)
                                    let cancelAction = UIAlertAction(
                                        title: "Ok",
                                        style: .cancel,
                                        handler: nil)
                                    alertController.addAction(cancelAction)
                                    self.present(
                                        alertController,
                                        animated: true,
                                        completion: nil)
                                })
                            }
                        })
                    })
                    break
                case .notFound:
                    print("No faces")
                    break
                case .failure(let error):
                    // When the any error occured, `result` will be `failure`.
                    print(error)
                    break
                }
            }
        }
        actionButton.display(inViewController: self)
        
    }
    func imageFromSampleBuffer(sampleBuffer : CMSampleBuffer) -> UIImage
    {
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(imageBuffer!);
        let height = CVPixelBufferGetHeight(imageBuffer!);
        
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        
        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        // Create a Quartz image from the pixel data in the bitmap graphics context
        let quartzImage = context?.makeImage();
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        // Create an image object from the Quartz image
        let image = UIImage.init(cgImage: quartzImage!);
        return (image);
    }
    
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImageSegue" {
            self.processImageView.isHidden = true
            self.scanFaceView.isHidden = false
            captureImage = false
            if let imageViewController = segue.destination as? FinalImageVC {
                imageViewController.captureImaged = self.faceImage
                imageViewController.imageRect = self.imageRect
            }
        }
    }
    
    @IBAction func exit(unwindSegue: UIStoryboardSegue) {
        faceImage = nil
    }
    
}

// MARK: - Gesture methods

extension FaceDetectionViewController {
    
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        // This code doesnt work
        // DispatchQueue.main.async {
        //    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, true, 0)
        //             guard let context = UIGraphicsGetCurrentContext() else { return }
        //    self.view.layer.render(in: context)
        //             guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return }
        //             UIGraphicsEndImageContext()
        //
        //             //Save it to the camera roll
        //             UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        //   }
        
        captureImage = true
        scanFaceView.isHidden = true
        processImageView.isHidden = false
        
        
    }
    
    
}

// MARK: - Video Processing methods

extension FaceDetectionViewController {
    func configureCaptureSession() {
        // Define the capture device we want to use
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front) else {
                                                    fatalError("No front video camera available")
        }
        
        // Connect the camera to the capture session input
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            session.addInput(cameraInput)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        // Create the video data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        // Add the video output to the capture session
        session.addOutput(videoOutput)
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        
        // Configure the preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate methods

extension FaceDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 1
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // 2
        let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: detectedFace)
        
        // 3
        do {
            try sequenceHandler.perform(
                [detectFaceRequest],
                on: imageBuffer,
                orientation: .leftMirrored)
        } catch {
            print(error.localizedDescription)
        }
        //
        DispatchQueue.main.async {
            let sampleImg = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            self.faceImage = sampleImg
            
            self.captureImage = false
        }
        if captureImage == true {
            
        }
    }
    
}



extension FaceDetectionViewController {
    func convert(rect: CGRect) -> CGRect {
        // 1
        let origin = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.origin)
        
        // 2
        let size = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.size.cgPoint)
        
        // 3
        return CGRect(origin: origin, size: size.cgSize)
    }
    
    // 1
    func landmark(point: CGPoint, to rect: CGRect) -> CGPoint {
        // 2
        let absolute = point.absolutePoint(in: rect)
        
        // 3
        let converted = previewLayer.layerPointConverted(fromCaptureDevicePoint: absolute)
        
        // 4
        return converted
    }
    
    func landmark(points: [CGPoint]?, to rect: CGRect) -> [CGPoint]? {
        guard let points = points else {
            return nil
        }
        
        return points.compactMap { landmark(point: $0, to: rect) }
    }
    
    func updateFaceView(for result: VNFaceObservation) {
        defer {
            DispatchQueue.main.async {
                self.faceView.setNeedsDisplay()
            }
        }
        let box = result.boundingBox
        
        self.FaceCGRect = result.boundingBox
        
        faceView.boundingBox = convert(rect: box)
        if captureImage == true {
            imageRect = convert(rect: box)
        }
        guard let landmarks = result.landmarks else {
            return
        }
        
        if let leftEye = landmark(
            points: landmarks.leftEye?.normalizedPoints,
            to: result.boundingBox) {
            faceView.leftEye = leftEye
        }
        
        if let rightEye = landmark(
            points: landmarks.rightEye?.normalizedPoints,
            to: result.boundingBox) {
            faceView.rightEye = rightEye
        }
        
        if let leftEyebrow = landmark(
            points: landmarks.leftEyebrow?.normalizedPoints,
            to: result.boundingBox) {
            faceView.leftEyebrow = leftEyebrow
        }
        
        if let rightEyebrow = landmark(
            points: landmarks.rightEyebrow?.normalizedPoints,
            to: result.boundingBox) {
            faceView.rightEyebrow = rightEyebrow
        }
        
        if let nose = landmark(
            points: landmarks.nose?.normalizedPoints,
            to: result.boundingBox) {
            faceView.nose = nose
        }
        
        if let outerLips = landmark(
            points: landmarks.outerLips?.normalizedPoints,
            to: result.boundingBox) {
            faceView.outerLips = outerLips
        }
        
        if let innerLips = landmark(
            points: landmarks.innerLips?.normalizedPoints,
            to: result.boundingBox) {
            faceView.innerLips = innerLips
        }
        
        if let faceContour = landmark(
            points: landmarks.faceContour?.normalizedPoints,
            to: result.boundingBox) {
            faceView.faceContour = faceContour
        }
    }
    // MARK: - FaceImage
    
    func toBase64String(Image:UIImage) -> String {
        let imageData = Image.jpegData(compressionQuality: 1)
        let imageBase64String = imageData?.base64EncodedString()
        return imageBase64String!
    
    }
    
    func detectedFace(request: VNRequest, error: Error?) {
        // 1
        guard
            let results = request.results as? [VNFaceObservation],
            let result = results.first
            else {
                // 2
                faceView.clear()
                if captureImage == true {
                    DispatchQueue.main.async {
                        self.processImageView.isHidden = true
                        self.scanFaceView.isHidden = false
                        let alert = UIAlertController(title: "No Face!", message: "No face was detected", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                }
                return
        }
        
        if faceViewHidden {
            
        } else {
            updateFaceView(for: result)
        }
    }
    
}
extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width,
                       y: self.y * size.height)
    }
}

