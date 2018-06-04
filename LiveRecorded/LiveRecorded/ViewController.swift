//
//  ViewController.swift
//  LiveRecorded
//
//  Created by iOS on 2018/5/29.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // 捕获会话
    private var captureSession = AVCaptureSession()
    // 视频设备输入对象
    private var currentVideoDeviceInput: AVCaptureDeviceInput?
    // 音频设备输入对象
    private var currentAudioDeviceInput: AVCaptureDeviceInput?
    private var videoConnection: AVCaptureConnection?
    private var previedLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaputureVideo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController {
    /// 捕获音视频
    func setupCaputureVideo() {
        
        //1.创建捕获会话，必须要强引用，否则会被释放
        
        //2.获取摄像头设备，默认是后置摄像头
        let videoDevice = getVideoDevice(position: .back)
        
        //3.获取声音设备
        let audioDevice = AVCaptureDevice.default(for: .audio)
        
        guard let video = videoDevice, let audio = audioDevice else {
            print("音频或视频设备获取失败")
            return
        }
        do {
            //4.创建对应视频设备输入对象
            let videoDeviceInput = try AVCaptureDeviceInput(device: video)
            currentVideoDeviceInput = videoDeviceInput
            
            //5. 创建对应音频设备输入对象
            let audioDeviceInput = try AVCaptureDeviceInput(device: audio)
            currentAudioDeviceInput = audioDeviceInput
            
            // 6.添加到会话中
            // 注意“最好要判断是否能添加输入，会话不能添加空的
            // 6.1 添加视频
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            } else {
                print("添加视频失败")
            }
            
            // 6.2添加音频
            if captureSession.canAddInput(audioDeviceInput) {
                captureSession.addInput(audioDeviceInput)
            } else {
                print("添加音频失败")
            }
            
            // 7.获取视频数据输出设备
            let videoOutput = AVCaptureVideoDataOutput()
            // 7.1 设置代理，捕获视频样品数据
            // 注意，队列必须是串行队列，才能获取到数据，而且不能为空
            let videoQueue = DispatchQueue(label: "Video Capture Queue")
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            } else {
                print("很遗憾，失败啦")
            }
            
            // 8.获取音频数据输出设备
            let audioOutput = AVCaptureAudioDataOutput()
            // 8.1 设置代理，捕获音频样品数据
            let audioQueue = DispatchQueue(label: "Video Capture Queue")
            audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
            if captureSession.canAddOutput(audioOutput) {
                captureSession.addOutput(audioOutput)
            }
            
            // 9.获取视频输入和输出链接，用于分辨音视频数据
            videoConnection = videoOutput.connection(with: .video)
            // 设置摄像头方向
            videoConnection?.videoOrientation = .portrait
            
            // 10.添加视频预览图层
            let previedLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previedLayer.frame = CGRect(x: 10, y: 10, width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height - 20)
            view.layer.insertSublayer(previedLayer, at: 0)
            self.previedLayer = previedLayer
            
            // 11.启动会话
            captureSession.startRunning()
            
            
        } catch {
            print("发生错误")
        }
        
    }
    
    // 指定摄像头方向获取摄像头
    func getVideoDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: .video)
        for device: AVCaptureDevice in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    /// 获取输入设备数据，视频
    /*
     CMSampleBuffer存放编解码前后的视频图像的容器数据结构，这里存放的就是未经编码的摄像机数据。
     通过CMSampleBufferGetImageBuffer()接口就可以拿到CVImageBuffer编码前的数据，可以送去编码器进行编码的数据。
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if videoConnection == connection {
            print("采集视频数据： ")
        } else {
            print("采集到音频数据")
        }
//        print("output: \(output)")
//        print("sampleBuffer: \(sampleBuffer)")
        
        guard let image = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        // 送去IOS的硬编码器编码,需要使用videoToolbox和audioToolbox
        print("image: \(image)")
    }
}

extension ViewController {
    
}










