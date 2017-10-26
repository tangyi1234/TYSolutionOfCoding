//
//  TYStartCodec.m
//  TYSolutionOfCoding
//
//  Created by 汤义 on 2017/9/25.
//  Copyright © 2017年 汤义. All rights reserved.
//

#import "TYStartCodec.h"
#import "TYStoreAddress.h"
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libavutil/opt.h>
#import <libavutil/imgutils.h>
#import <libswscale/swscale.h>
@interface TYStartCodec(){
    AVCodecContext                          *videoCodecContext;              //编解码器的参数配置
    AVFrame                                 *frame;                          //储存原始数据的对象
    char                                    *out_file;
    int                                     framecnt;
    int                                     encoder_h264_frame_width; // 编码的图像宽度
    int                                     encoder_h264_frame_height; // 编码的图像高度
    AVFormatContext                         *pFormatConttext;          //格式参数
    AVOutputFormat                          *outputFormat;             //输出信息对象
    AVStream                                *stream;                   //流
    AVCodecContext                          *videoCodingContext;       //编码器参数配置
    AVCodec                                 *codec;                    //编解器
    AVFrame                                 *codingFrame;              //编码原始数据对象
    uint8_t                                 *picture_buf;
    AVPacket                                pkt;                       //是用来输出和输入数据包对象
    int                                     picture_size;
    int                                     y_size;
    AVPicture                               picture;                   //解码图片
}
@end
@implementation TYStartCodec
-(instancetype)initScreenSize:(CGSize)size {
    self = [super init];
    if (self) {
        [self initDecodingSize:size];
        [self implementationCoding:size];
    }
    return self;
}
//初始化解码
- (void)initDecodingSize:(CGSize)size {
    //注册编解码器的函数
    av_register_all();
    avcodec_register_all();
    
    
    AVFrame *pFrame = NULL;
    //查找视频编解码器
    AVCodec *videoCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    
    if (!videoCodec) {
        NSLog(@"没有查找视频编解码器");
        return;
    }
    
    //初始化编解码器的上下文
    videoCodecContext = avcodec_alloc_context3(videoCodec);
    //设置上下文的参数
    videoCodecContext->time_base.num = 1;
    videoCodecContext->frame_number = 1;
    videoCodecContext->codec_type = AVMEDIA_TYPE_VIDEO;
    videoCodecContext->bit_rate = 1500000;
    videoCodecContext->time_base.den = 15;
    videoCodecContext->width = size.width;
    videoCodecContext->height = size.height;
    //avcodec_open2是用于编解器的初始化
    if (avcodec_open2(videoCodecContext, videoCodec, nil) >= 0) {
        //AVFrame结构体保存的是解码后和原始的音视频信息
        frame = av_frame_alloc();
    }else{
        return;
    }
}

//开始进行编码
- (BOOL)implementationCoding:(CGSize)size {
    //获取本地地址
    TYStoreAddress *address = [[TYStoreAddress alloc] init];
    out_file = [address nsstring2char];
    //预备一些数据
    framecnt = 0;
    encoder_h264_frame_height = size.height;
    encoder_h264_frame_width = size.width;
    //注册编码器
    av_register_all();
    //初始化输出信息对象
    outputFormat = av_guess_format(NULL, out_file, NULL);
    //初始化格式上下文
    pFormatConttext = avformat_alloc_context();
    pFormatConttext->oformat = outputFormat;
    //初始化输出url
    if (avio_open(&pFormatConttext->pb, out_file, AVIO_FLAG_READ_WRITE) < 0) {
        NSLog(@"输出url错误了");
        return NO;
    }
    //创建流和设置一些属性
    stream = avformat_new_stream(pFormatConttext, 0);
    stream->time_base.num = 1;
    stream->time_base.den = 15;
    
    if (stream == NULL){
        NSLog(@"流创建失败");
        return NO;
    }
    videoCodingContext = stream->codec;   /*AVCodecContext 相当于虚基类，需要用具体的编码器实现来给他赋值*/
    //编码器的ID号，这里我们自行指定为264编码器，实际上也可以根据AVStream里的codecID 参数赋值
    videoCodingContext->codec_id = outputFormat->video_codec;
    //编码器编码的数据类型
    videoCodingContext->codec_type = AVMEDIA_TYPE_VIDEO;
    //像素的格式，也就是说采用什么样的色彩空间来表明一个像素点
    videoCodingContext->pix_fmt = AV_PIX_FMT_YUV420P;
    //编码目标的视频帧大小，以像素为单位
    videoCodingContext->width = encoder_h264_frame_width;
    videoCodingContext->height = encoder_h264_frame_height;
    //帧率的基本单位，我们用分数来表示，
    //用分数来表示的原因是，有很多视频的帧率是带小数的eg：NTSC 使用的帧率是29.97
    videoCodingContext->time_base.num = 1;
    videoCodingContext->time_base.den = 15;
    videoCodingContext->bit_rate = 1500000;
    //每250帧插入1个I帧，I帧越少，视频越小
    videoCodingContext->gop_size = 250;
    //最大和最小量化系数
    videoCodingContext->qmin = 10;
    videoCodingContext->qmax = 51;
    //两个非B帧之间允许出现多少个B帧数
    //设置0表示不使用B帧
    //b 帧越多，图片越小
    videoCodingContext->max_b_frames = 3;
    
    AVDictionary *param = 0;
    
    if (videoCodingContext->codec_id == AV_CODEC_ID_H264) {
        av_dict_set(&param, "preset", "slow", 0);
        av_dict_set(&param, "tune", "zerolatency", 0);
    }
    //打印一些信息
    av_dump_format(pFormatConttext, 0, out_file, 1);
    //查找编码器
    codec = avcodec_find_encoder(videoCodingContext->codec_id);
    if (!codec) {
        NSLog(@"实例化编码器失败");
        return NO;
    }
    //初始化编码器
    if (avcodec_open2(videoCodingContext, codec, &param) < 0) {
        NSLog(@"编码器初始化失败");
        return NO;
    }
    //初始化储存数据对象,AVFrame就是用来保存帧数据的
    codingFrame = av_frame_alloc();
    //avpicture_fill来把帧和我们新申请的内存来结合
    avpicture_fill((AVPicture*)codingFrame, picture_buf, videoCodingContext->pix_fmt, videoCodingContext->width, videoCodingContext->height);
    //写视频文件头
    avformat_write_header(pFormatConttext, NULL);
    /*
     AVPacket本身只是个容器，它data成员引用实际的数据缓冲区。这个缓冲区通常是由av_new_packet创建的，但也可能由 FFMPEG的API创建（如av_read_frame）。当某个AVPacket结构的数据缓冲区不再被使用时，要需要通过调用 av_free_packet释放
     */
    av_new_packet(&pkt, picture_size);
    y_size = videoCodingContext->width * videoCodingContext->height;
    return YES;
}

- (void)videoCodingBuf:(CMSampleBufferRef)bufferRef {
    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(bufferRef);
    
    if (CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess) {
        UInt8 *bufferbasePtr = (UInt8 *)CVPixelBufferGetBaseAddress(imageBuffer);
        UInt8 *bufferPtr = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
        UInt8 *bufferPtr1 = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,1);
        size_t buffeSize = CVPixelBufferGetDataSize(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t bytesrow0 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
        size_t bytesrow1  = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,1);
        size_t bytesrow2 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,2);
        UInt8 *yuv420_data = (UInt8 *)malloc(width * height *3/ 2); // buffer to store YUV with layout YYYYYYYYUUVV
        
        /* convert NV12 data to YUV420*/
        UInt8 *pY = bufferPtr ;
        UInt8 *pUV = bufferPtr1;
        UInt8 *pU = yuv420_data + width*height;
        UInt8 *pV = pU + width*height/4;
        for(int i =0;i<height;i++)
        {
            memcpy(yuv420_data+i*width,pY+i*bytesrow0,width);
        }
        
        for(int j = 0;j<height/2;j++)
        {
            for(int i =0;i<width/2;i++)
            {
                //                NSLog(@"这里的i是多少:%d pUV是什么:%s",i,pUV);
                *(pU++) = pUV[i<<1];
                *(pV++) = pUV[(i<<1) + 1];
            }
            pUV+=bytesrow1;
        }
        
        //Read raw YUV data
        picture_buf = yuv420_data;
        codingFrame->data[0] = picture_buf;              // Y
        codingFrame->data[1] = picture_buf+ y_size;      // U
        codingFrame->data[2] = picture_buf+ y_size*5/4;  // V
        
        // PTS
        codingFrame->pts = framecnt;
        int got_picture = 0;
        
        // Encode
        codingFrame->width = encoder_h264_frame_width;
        codingFrame->height = encoder_h264_frame_height;
        codingFrame->format = AV_PIX_FMT_YUV420P;
        /*
         该函数用于编码一帧视频数据.
         该函数每个参数的含义在注释里面已经写的很清楚了，在这里用中文简述一下：
         avctx：编码器的AVCodecContext。
         avpkt：编码输出的AVPacket。
         frame：编码输入的AVFrame。
         got_packet_ptr：成功编码一个AVPacket的时候设置为1。
         函数返回0代表编码成功
         */
        int ret = avcodec_encode_video2(videoCodingContext, &pkt, codingFrame, &got_picture);
        if(ret < 0) {
            
            NSLog(@"编码出错了");
            
        }
        if (got_picture==1) {
            
            printf("Succeed to encode frame: %5d\tsize:%5d\n  data:%d", framecnt, pkt.size,pkt.buf);
            framecnt++;
            pkt.stream_index = stream->index;
            ret = av_write_frame(pFormatConttext, &pkt);
            av_free_packet(&pkt);
        }
        
        free(yuv420_data);
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

@end
