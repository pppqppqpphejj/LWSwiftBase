//
//  ViewController.swift
//  CameraView
//
//  Created by ZeroJ on 16/7/4.
//  Copyright © 2016年 ZeroJ. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var cameraView: CameraView!

    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView.layer.cornerRadius = 100
        cameraView.layer.masksToBounds = true
        let isSuccess = cameraView.prepareCamera()
        
        if !isSuccess {
            print("没有相机")
        }
        
        cameraView.setHandlerWhenCannotAccessTheCamera {
            print("用户未授权访问相机")
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func changeCameraPosition(_ sender: UIButton) {
        let cameraPosition = cameraView.autoChangeCameraPosition()
        switch cameraPosition {
        case .back:
            sender.setTitle("后面", for: UIControlState())
        case .front:
            sender.setTitle("前面", for: UIControlState())
        }
        
    }
    @IBAction func changeFlashType(_ sender: UIButton) {
        
        
        let flashModel = cameraView.autoChangeFlashModel()
        //cameraView.flashModel = CameraView.FlashModel.auto
        //let flashModel = cameraView.flashModel
        switch flashModel {
        case .on:
            sender.setTitle("打开", for: UIControlState())
        case .off:
            sender.setTitle("关闭", for: UIControlState())
        case .auto:
            sender.setTitle("自动", for: UIControlState())
        }
    }
    
    @IBAction func changeMediaQuality(_ sender: UIButton) {
        cameraView.autoChangeQualityType()
        //cameraView.mediaQuality = CameraView.MediaQuality.high
    }
    @IBAction func changeOutputType(_ sender: UIButton) {
        cameraView.autoChangeOutputMediaType()
        //cameraView.outputMediaType = CameraView.OutputMediaType.stillImage
    }
    @IBAction func takePicture(_ sender: UIButton) {
        
        
        if cameraView.outputMediaType == CameraView.OutputMediaType.stillImage {
            // 拍照
            cameraView.getStillImage { (image, error) in
                print(image)
            }
        } else {
            // 录视频
            if sender.isSelected {// 正在录制, 点击停止
                cameraView.stopCapturingVideo(withHandler: { (videoUrl, error) in
                    print(videoUrl)
                })
                sender.isSelected = false
            } else {// 点击开始录制
                sender.isSelected = true
                cameraView.startCapturingVideo()
            }
        }


    }


}

