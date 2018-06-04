# LiveRecordDemo
swift4，录播学习demo，包括音视频的采集以及硬编码。

说明：

原本打算使用swift写采集以及编码的，但是，搜索资料的时候发现编码中，有定义C语言的方法，在swift文件中兼容性不好，就只用swift写了采集部分就放弃了。

ViewController.swift: 这里包含视频的采集，没有编码。

SecondViewController: OC
包含视频的采集以及编码。
AACEncoder：音频编码。
H264Encoder：视频编码。

环境：
xcode 9.4

供参考。
