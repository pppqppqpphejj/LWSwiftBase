//
//  CameraView.swift
//  CameraView
//
//  Created by ZeroJ on 16/7/6.
//  Copyright © 2016年 ZeroJ. All rights reserved.
//

import UIKit

import AVFoundation
import Photos
open class CameraView: UIView {
    
    // MARK:- public property
    public enum OutputMediaType : Int {
        case video, stillImage
    }
    
    public enum CameraPosition : Int {
        case back, front
    }
    
    public enum FlashModel : Int {
        case on, off, auto
        
        func changeToAvFlashModel() -> AVCaptureDevice.FlashMode {
            switch self {
            case .auto:
                return .auto
            case .on:
                return .on
            case .off:
                return .off
            }
        }
    }
    
    public enum MediaQuality : Int {
        case high, medium, low
        
        func changeToAvPreset() -> String {
            switch self {
            case .high:
                return AVCaptureSession.Preset.high.rawValue
            case .low:
                return AVCaptureSession.Preset.low.rawValue
            case .medium:
                return AVCaptureSession.Preset.medium.rawValue
            }
        }
    }
    
    /// set this to true will automaticly save the captured data to the system library
    open var isSaveTheFileToLibrary = true
    
    // set mediaQuality default is high
    open var mediaQuality: MediaQuality! = nil {
        didSet {
            if oldValue != mediaQuality {
                
                if oldValue == nil {
                    change(mediaQuality: mediaQuality)

                } else {
                    
                    session.beginConfiguration()
                    change(mediaQuality: mediaQuality)
                    session.commitConfiguration()
                }
            }
        }
    }
    
    // set mediaType default is stillImage
    open var outputMediaType: OutputMediaType! = nil {
        didSet {
            
            if oldValue != outputMediaType {
                if oldValue == nil {
                    //switch to the new mediaType
                    change(mediaType: outputMediaType)
                    
                } else {
                    session.beginConfiguration()
                    change(mediaType: outputMediaType)
                    session.commitConfiguration()
                }
            }
        }
    }
    
    // set cameraPosition default is back
    open var cameraPosition: CameraPosition! = nil {
        didSet {
            if oldValue != cameraPosition {
                // switch to the new cameraPosition
                if oldValue == nil {// prepareCamera
                    change(cameraPosion: cameraPosition)
                } else {
                    self.sessionQueue.async(execute: {
                        self.session.beginConfiguration()
                        self.change(cameraPosion: self.cameraPosition)
                        self.session.commitConfiguration()
                    })
                }
            }
        }
    }
    
    // set flashModel default is auto
    open var flashModel: FlashModel! = nil {
        didSet {
            if oldValue != flashModel {
                // switch to the new flashModel
                
                if oldValue == nil {
                    //switch to the new mediaType
                    change(flashModel: flashModel)
                    
                } else {
                    session.beginConfiguration()
                    change(flashModel: flashModel)
                    session.commitConfiguration()
                }
            }
        }
    }
    
    
    // MARK:- private property
    fileprivate var videoCompleteHandler:((_ videoFileUrl: URL?, _ error: NSError?) -> ())?
    fileprivate var lastScale:CGFloat = 1.0
    
    fileprivate lazy var session = AVCaptureSession()
    
    fileprivate var currentDeviceInput: AVCaptureDeviceInput?
    
    fileprivate lazy var movieFileOutput: AVCaptureMovieFileOutput? = {
        return AVCaptureMovieFileOutput()
    }()
    
    fileprivate lazy var stillImageOutput: AVCaptureStillImageOutput? = {
        return AVCaptureStillImageOutput()
    }()
    
    fileprivate lazy var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    
    fileprivate var cannotAccessTheCameraHandler:(() -> Void)?
    
    //DISPATCH_QUEUE_SERIAL -> use the queue strategy to ensure FIFO
    fileprivate lazy var sessionQueue: DispatchQueue = DispatchQueue(label: "cameraViewSessionQueue", attributes: [])
    
    fileprivate lazy var frontDeviceInput: AVCaptureDeviceInput? = {
        self.deviceInput(forDevicePosition: .front)
    }()
    
    fileprivate lazy var backDeviceInput: AVCaptureDeviceInput? = {
        self.deviceInput(forDevicePosition: .back)
    }()
    
    // scale and adjust focus via pinGesture when the media type is stillImage
    fileprivate lazy var pinchGes:UIPinchGestureRecognizer = {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinGesture(_:)))
        return pinch
    }()
    // attention that for the movie the extension should't be 'jpg'
    
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    fileprivate func commonInit() {
        // set the resize model
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        // add the previewLayer
        layer.addSublayer(previewLayer)
        clipsToBounds = true

        // tapGesture is always useful
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(_:)))
        addGestureRecognizer(tapGes)
        addGestureRecognizer(pinchGes)
        
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        // to fit the orientation
        previewLayer.frame = bounds
        
    }
    
    deinit {
        session.stopRunning()
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK:- private Helper
extension CameraView {
    
    fileprivate func change(mediaQuality: MediaQuality) {
        let preset:String
        
        switch mediaQuality {
        case .high:
            if outputMediaType == .stillImage {
            
                preset = AVCaptureSession.Preset.photo.rawValue
            } else {
                preset = AVCaptureSession.Preset.high.rawValue
                
            }
        case .low:
            preset = AVCaptureSession.Preset.low.rawValue
        case .medium:
            preset = AVCaptureSession.Preset.medium.rawValue
        }
        if session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: preset)) {
            session.sessionPreset = AVCaptureSession.Preset(rawValue: preset)
        }
    }
    
    fileprivate func change(flashModel: FlashModel) {
        let avFlashModel = flashModel.changeToAvFlashModel()
        
        if let trueVideoDevice = currentDeviceInput?.device, trueVideoDevice.hasFlash && trueVideoDevice.isFlashModeSupported(avFlashModel) {
            
            do {
                try trueVideoDevice.lockForConfiguration()
                trueVideoDevice.flashMode = avFlashModel
                trueVideoDevice.unlockForConfiguration()
            } catch {
                print("can not lock the device for configuration!! ---\(error)")
            }
            
        }
    }
    
    fileprivate func change(mediaType: OutputMediaType) {
        if mediaType == .stillImage {
            self.session.removeOutput(movieFileOutput!)
            self.session.addOutput(stillImageOutput!)
        } else {
            self.session.removeOutput(stillImageOutput!)
            self.session.addOutput(movieFileOutput!)
            
        }
    }
    
    fileprivate func change(cameraPosion posion: CameraPosition) {
        if self.currentDeviceInput != nil {
            self.session.removeInput(self.currentDeviceInput!)
        }
        
        switch posion {
        case .back:
            self.currentDeviceInput = self.backDeviceInput
        case .front:
            self.currentDeviceInput = self.frontDeviceInput
        }
        self.add(inputDevice: self.currentDeviceInput)
    }
    
    fileprivate func add(inputDevice: AVCaptureDeviceInput!) {
        if self.session.canAddInput(inputDevice) {
            self.session.addInput(inputDevice)
        } else {
            print("can not add the input devices-- \(String(describing: inputDevice))")
        }
        
    }
    
    fileprivate func add(stillImageOutput: AVCaptureStillImageOutput!) {
        if self.session.canAddOutput(stillImageOutput) {
            self.session.addOutput(stillImageOutput)
        } else {
            print("can not add stillImageOutput !!")
            
        }
    }
    
    fileprivate func add(movieFileOutput: AVCaptureMovieFileOutput!) {
        if self.session.canAddOutput(movieFileOutput) {
            self.session.addOutput(movieFileOutput)
        } else {
            print("can not add movieFileOutput !!")
        }
    }
    
    fileprivate func askForAccessDevice(withCompleteHandler completeHandler:((_ succeed: Bool) -> Void)?) {
        // suspend the queue untill the request end
        self.sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (succeed) in
            
            if succeed {
                completeHandler?(succeed)
            } else {
                completeHandler?(false)
            }
            
            self.sessionQueue.resume()
        })
        
    }
    
    fileprivate func deviceInput(forDevicePosition position: AVCaptureDevice.Position) -> AVCaptureDeviceInput? {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        var deviceInput: AVCaptureDeviceInput? = nil
        for device in devices {
            if device.position == position {
                deviceInput = try? AVCaptureDeviceInput(device: device)
                break
            }
        }
        // cause it cannot be failed so we use try!
        
        return deviceInput
    }
    
    fileprivate func change(focusModel: AVCaptureDevice.FocusMode, exposureModel: AVCaptureDevice.ExposureMode, at point: CGPoint, isMonitor: Bool) {
        if let device = currentDeviceInput?.device {
            do {
                // must lock it or it may causes crashing
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusModel) {
                    device.focusPointOfInterest = point
                    device.focusMode = focusModel
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureModel) {
                    // only when setting the exposureMode after setting exposurePointOFInterest can be successful
                    device.exposurePointOfInterest = point
                    device.exposureMode = exposureModel
                }
                // only when set it true can we receive the AVCaptureDeviceSubjectAreaDidChangeNotification
                device.isSubjectAreaChangeMonitoringEnabled = isMonitor
                device.unlockForConfiguration()
                
                
            } catch {
                print("cannot change the focusModel")
            
            }
        }
    }
    
    fileprivate func addObserver() {
        let notiCenter = NotificationCenter.default
        notiCenter.addObserver(self, selector: #selector(self.handleSubjectAreaChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: currentDeviceInput?.device)
    }
}

// MARK:- public Helper
extension CameraView {
    
    
    /// this closure will be invoked when can not access the camera
    /// and you can show some messages to the users
    /// and setting it is always been suggested
    public func setHandlerWhenCannotAccessTheCamera(_ handler: (() -> Void)?) {
        self.cannotAccessTheCameraHandler = handler
    }
    
    /// call this method to get and handle the captured still image after you have called prepareCamra()
    public func getStillImage(_ handler:@escaping ((_ image: UIImage?, _ error: NSError?) -> Void)) -> Bool {
        
        if !hasCamera() {
            print("no avilable camera")
            return false
        }
        // capturing the still image
        self.sessionQueue.async {
            
            self.session.beginConfiguration()
            self.outputMediaType = .stillImage
            let connection = self.stillImageOutput?.connection(with: AVMediaType.video)
            connection?.videoOrientation = (self.previewLayer.connection?.videoOrientation)!
            self.session.commitConfiguration()
            
            self.stillImageOutput?.captureStillImageAsynchronously(from: connection!, completionHandler: { (buffer, error) in
                // got the data
                if buffer != nil {
                    
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer!)
                    let image = UIImage(data: imageData!)
                    handler(image, nil)
                    if self.isSaveTheFileToLibrary {
                        let tempFileName = "\(ProcessInfo().globallyUniqueString).jpg"
                        let tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(tempFileName)
                        let tempImageURL = URL(fileURLWithPath: tempFilePath)
                        
                        PHPhotoLibrary.requestAuthorization({ (status) in
                            if status == .authorized {
                                PHPhotoLibrary.shared().performChanges({
                                    do {
                                        // write to tempPath
                                        try imageData?.write(to: tempImageURL, options: NSData.WritingOptions.atomicWrite)
                                        // write to album
                                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tempImageURL)
                                    } catch {
                                        print("failed to save the picture to album")
                                    }
                                    }, completionHandler: { (succeed, error) in
                                        
                                        do {
                                            try FileManager.default.removeItem(at: tempImageURL)
                                        } catch {
                                            print("failed to save the picture to album")
                                        }
                                })
                            }
                        })
                    }
                    
                    
                } else {
                    handler(nil, error! as NSError)
                    
                }
                
                
            })
        }
        
        return true
        
    }
    
    /// if you call this method then it will automaticly change the flashModel to the next model in order
    /// if you want to switch to a particular flashModel you may need to set the flashModel property
    public func autoChangeFlashModel() -> FlashModel {
        flashModel = flashModel == nil ? FlashModel.auto : flashModel
        // automaticly change the flash model by this way
        if let newFlashModel = FlashModel(rawValue: (flashModel.rawValue + 1)%3) {
            // change the flash model
            flashModel = newFlashModel
        }
        return flashModel
    }
    
    /// if you call this method then it will automaticly change the camera' position to the next position in order
    /// if you want to switch to a particular position you may need to set the cameraPosition property
    public func autoChangeCameraPosition() -> CameraPosition {

        cameraPosition = cameraPosition == nil ? CameraPosition.back : cameraPosition
        if let newPosition = CameraPosition(rawValue: (cameraPosition.rawValue + 1)%2) {
            cameraPosition = newPosition
        }
        return cameraPosition
    }
    
    /// if you call this method then it will automaticly change the outputMediaType in order
    /// if you want to switch to a particular outputMediaType you may need to set the outputMediaType property
    public func autoChangeOutputMediaType() -> OutputMediaType {
        outputMediaType = outputMediaType == nil ? OutputMediaType.stillImage : outputMediaType
        if let newMediaType = OutputMediaType(rawValue: (outputMediaType.rawValue + 1)%2) {
            outputMediaType = newMediaType
        }
        return outputMediaType
    }
    
    public func autoChangeQualityType() -> MediaQuality {
        mediaQuality = mediaQuality == nil ? MediaQuality.high : mediaQuality
        if let newQuality = MediaQuality(rawValue: (mediaQuality.rawValue + 1)%3) {
            mediaQuality = newQuality
        }
        
        return mediaQuality
    }
    
    // call this method to start recoding video after you have called prepareCamra()
    public func startCapturingVideo() -> Bool {
        
        
        session.beginConfiguration()
        outputMediaType = .video
        if !hasCamera() {
            return false
        }
        let connection = movieFileOutput?.connection(with: AVMediaType.video)
        connection?.videoOrientation = (previewLayer.connection?.videoOrientation)!
        session.commitConfiguration()
        
        let tempFileName = "\(ProcessInfo().globallyUniqueString).mov"
        let tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(tempFileName)
        let tempVideoURL = URL(fileURLWithPath: tempFilePath)
        
        movieFileOutput?.startRecording(to: tempVideoURL, recordingDelegate: self)
        return true
    }
    
    // you may need to call this method to see if there are cameras now
    // or you can alse use the prepareCamera() return value
    public func hasCamera() -> Bool {
        if frontDeviceInput != nil || backDeviceInput != nil {
            return true
        } else {
            print("no avilable camera")
            return false
        }
    }
    // you are supposed to call this method first to prepare camera
    public func prepareCamera() -> Bool {
        
        
        if !hasCamera() {
            return false
        }

        // do not block the main queue
        sessionQueue.async {
            
            self.askForAccessDevice(withCompleteHandler: { (succeed) in
                if !succeed {
                    DispatchQueue.main.async(execute: {
                        self.cannotAccessTheCameraHandler?()
                    })
                    return
                }
                
                // add inputs and outputs
                self.session.beginConfiguration()
                
                // this will add current device
                self.cameraPosition = .back
                // default is stillImage
                self.outputMediaType = .stillImage
                // setting flashModel
                self.flashModel = .auto
                // setting mediaQuality
                self.mediaQuality = .high
                self.session.commitConfiguration()
                self.addObserver()
                self.session.startRunning()
                
            })
        }
        
        return true
    }
    
    // call this method to stop and handle the captured video
    public func stopCapturingVideo(withHandler handler: @escaping (_ videoUrl: URL?, _ error: NSError?) -> ()) {
        videoCompleteHandler = handler
        movieFileOutput?.stopRecording()
    }
    
    public func resumeCapturing() {
        
    }
}

// MARK:- selector
extension CameraView {
    
    @objc func handlePinGesture(_ pinGes: UIPinchGestureRecognizer) {
        
        var beginScale: CGFloat = 1.0
        
        switch pinGes.state {
        case .began:
            beginScale = pinGes.scale
            
        case .changed:
            if let device = currentDeviceInput?.device {
                do {
                    
                    // only when preset = photo is the videoMaxZoomFactor != 1.0
                    // and can zoom
                    let maxScale = min(20.0, device.activeFormat.videoMaxZoomFactor)
                    // do not change too fast
                    let tempScale = min(lastScale + 0.3*(pinGes.scale - beginScale), maxScale)
                    lastScale = max(1.0, tempScale)
                    
                    try device.lockForConfiguration()
                    device.videoZoomFactor = lastScale
                    device.unlockForConfiguration()
                } catch {
                    print("cannot lock ")
                }
            }

        default :
            break
        }
        
        
    }
    
    @objc func handleTapGesture(_ tapGes: UITapGestureRecognizer) {
        let location = tapGes.location(in: tapGes.view)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: location)
        sessionQueue.async { 
            self.change(focusModel: .autoFocus, exposureModel: .autoExpose, at: devicePoint, isMonitor: true)
        }
        
    }
    
    @objc func handleSubjectAreaChange(_ noti: Notification) {
        // reset to center (0.0---1.0)
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        // set false
        sessionQueue.async { 
            // set to continuous and do not monitor
            self.change(focusModel: .continuousAutoFocus, exposureModel: .continuousAutoExposure, at: devicePoint, isMonitor: false)
        }
    }
    
}

// MARK:- public AVCaptureFileOutputRecordingDelegate
extension CameraView: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
    }
    
    public func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
    }
    
    public func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        let success = true
        if error != nil {// sometimes there may be error but the video is caputed successfully
            
            //success = error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as! Bool
        }
        
        if (success) {
            if isSaveTheFileToLibrary {
                
                PHPhotoLibrary.requestAuthorization({ (status) in
                    if status == PHAuthorizationStatus.authorized {
                        
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                            
                            }, completionHandler: {[unowned self] (succeed, error) in
                                if succeed {
                                    self.videoCompleteHandler?(outputFileURL, error! as NSError)
                                    
                                } else {
                                    self.videoCompleteHandler?(outputFileURL, error! as NSError)
                                }
                                do {
                                    try FileManager.default.removeItem(at: outputFileURL)
                                } catch {
                                    print("can not save video to alblum")
                                }
                            })
                    }
                })
                
            } else {
                videoCompleteHandler?(outputFileURL, error! as? NSError)
                
            }
        }
    }
}
