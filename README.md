iOS 编码流程和使用方法

这里只会涉及到编码的代码，有些东西可能是和rtmp推流是不适用的。
第一步：

注册编码器
av_register_all();
第二步：

初始化输入码流参数AVFormatContext，它包含的码流参数比较多，主要含有一下部分：
struct AVInputFormat *iformat：输入数据的封装格式
AVIOContext *pb：输入数据的缓存
unsigned int nb_streams：视音频流的个数
AVStream **streams：视音频流
char filename[1024]：文件名
int64_t duration：时长（单位：微秒us，转换为秒需要除以1000000）
int bit_rate：比特率（单位bps，转换为kbps需要除以1000）
AVDictionary *metadata：元数据

初始方法
pFormatConttext = avformat_alloc_context();
第三步：

初始化AVStream，AVStream是存储每一个视频/音频流信息的结构体，它所带参数有以下部分：
int index：标识该视频/音频流
AVCodecContext *codec：指向该视频/音频流的AVCodecContext（它们是一一对应的关系）
AVRational time_base：时基。通过该值可以把PTS，DTS转化为真正的时间。FFMPEG其他结构体中也有这个字段，但是根据我的经验，只有AVStream中的time_base是可用的。PTS*time_base=真正的时间
int64_t duration：该视频/音频流长度
AVDictionary *metadata：元数据信息
AVRational avg_frame_rate：帧率（注：对视频来说，这个挺重要的）
AVPacket attached_pic：附带的图片。比如说一些MP3，AAC音频文件附带的专辑封面。

初始方法：
stream = avformat_new_stream(pFormatConttext, 0);
第四步：

初始化AVCodecContext，AVCodecContext是一个编码信息设置体，编码效果如何都是取决与对它的参数设置。

初始化，这里我是承接上一个参数设置的。
videoCodingContext = stream->codec

下面都是它设置的参数：
//编码器的ID号，这里我们自行指定为264编码器，实际上也可以根据AVStream里的codecID 参数赋值
videoCodingContext->codec_id = AV_CODEC_ID_H264;
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
//目标的码率，即采样的码率；显然，采样码率越大，视频大小越大
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

//新添加
videoCodingContext->dct_algo = 0;
videoCodingContext->me_pre_cmp = 2;//运动场景预判功能的力度，数值越大编码时间越长
videoCodingContext->qmin = 25;//最大和最小量化系数
videoCodingContext->qmax = 40;
videoCodingContext->max_qdiff = 3;
videoCodingContext->gop_size = 250; //关键帧的最大间隔帧数/
videoCodingContext->keyint_min = 10; //关键帧的最小间隔帧数，取值范围10-51
videoCodingContext->refs = 2;    //运动补偿
videoCodingContext->rc_max_rate = 200000;//最大码流，x264中单位kbps，ffmpeg中单位bps
videoCodingContext->rc_min_rate = 512000;//最小码流
//    pCodecCtx->rc_buffer_size = 2000000;
//新增
videoCodingContext->mb_decision = 1;
videoCodingContext->keyint_min = 25;

videoCodingContext->scenechange_threshold = 40;
videoCodingContext->rc_strategy = 2;//码率控制测率，宏定义，查API
第五步

初始化AVCodec，AVCodec是存储编解码器信息的结构体，其主要包含参数
const char *name：编解码器的名字，比较短
const char *long_name：编解码器的名字，全称，比较长
enum AVMediaType type：指明了类型，是视频，音频，还是字幕
enum AVCodecID id：ID，不重复
const AVRational *supported_framerates：支持的帧率（仅视频）
const enum AVPixelFormat *pix_fmts：支持的像素格式（仅视频）
const int *supported_samplerates：支持的采样率（仅音频）
const enum AVSampleFormat *sample_fmts：支持的采样格式（仅音频）
const uint64_t *channel_layouts：支持的声道数（仅音频）
int priv_data_size：私有数据的大小
其初始化也是根据其逻辑来实现的，这里会根据videoCodingContext来进行初始化

初始化代码
codec = avcodec_find_encoder(videoCodingContext->codec_id);
AVDictionary *param = 0;
//初始化编码器
if (avcodec_open2(videoCodingContext, codec, &param) < 0) {
NSLog(@"编码器初始化失败");
return NO;
}
第六步

AVFrame, AVFrame是包含码流参数较多的结构体，AVFrame就是用来保存帧数据的。应为我们编码出的数据是以流的形式存在的所以我们有个流体。如果要做图像识别这里能起到帮助的作用。
uint8_t *data[AV_NUM_DATA_POINTERS]：解码后原始数据（对视频来说是YUV，RGB，对音频来说是PCM）
int linesize[AV_NUM_DATA_POINTERS]：data中“一行”数据的大小。注意：未必等于图像的宽，一般大于图像的宽。
int width, height：视频帧宽和高（1920x1080,1280x720...）
int nb_samples：音频的一个AVFrame中可能包含多个音频帧，在此标记包含了几个
int format：解码后原始数据类型（YUV420，YUV422，RGB24...）
int key_frame：是否是关键帧
enum AVPictureType pict_type：帧类型（I,B,P...）
AVRational sample_aspect_ratio：宽高比（16:9，4:3...）
int64_t pts：显示时间戳
int coded_picture_number：编码帧序号
int display_picture_number：显示帧序号
int8_t *qscale_table：QP表
uint8_t *mbskip_table：跳过宏块表
int16_t (*motion_val[2])[2]：运动矢量表
uint32_t *mb_type：宏块类型表
short *dct_coeff：DCT系数，这个没有提取过
int8_t *ref_index[2]：运动估计参考帧列表（貌似H.264这种比较新的标准才会涉及到多参考帧）
int interlaced_frame：是否是隔行扫描
uint8_t motion_subsample_log2：一个宏块中的运动矢量采样个数，取log的

初始化
codingFrame = av_frame_alloc();

第七步

这里一块主要做的设置我们保存区域有多大。avpicture_fill来把帧和我们新申请的内存来结合，这个函数的使用本质上是为已经分配的空间的结构体AVPicture挂上一段用于保存数据的空间，这个结构体中有一个指针数组data[4]，挂在这个数组里。

代码
avpicture_fill((AVPicture*)codingFrame, picture_buf, videoCodingContext->pix_fmt, videoCodingContext->width, videoCodingContext->height);

这里还要创建一个缓存区， AVPacket本身只是个容器，它data成员引用实际的数据缓冲区。这个缓冲区通常是由av_new_packet创建的，但也可能由 FFMPEG的API创建（如av_read_frame）。当某个AVPacket结构的数据缓冲区不再被使用时，要需要通过调用 av_free_packet释放

代码
av_new_packet(&pkt, picture_size);

以上的步骤都是一个编码流程初始化，以下的步骤才是开始编码。

第八步 编码

这一块主要是将摄像头获取的数据装换为YUV数据。我这里通过摄像头获取的格式为kCVPixelFormatType_420YpCbCr8BiPlanarFullRange，所以下面是我们对上面格式进行的yuv编码。

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

printf("编码从这里开始Succeed to encode frame: %5d\tsize:%5d\n  data:%d", framecnt, pkt.size,pkt.buf);
framecnt++;
pkt.stream_index = stream->index;
av_free_packet(&pkt);
}
以上八个步骤就是对摄像头获取的数据进行编码，编成流，是可以让我们的通过推流方式退出去的。


