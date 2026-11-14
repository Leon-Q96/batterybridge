#import "Protocol.h"
BOOL BBYJXDescriptorMatches(NSData *descriptor) {
    // Exact vendor collection signatures observed on this receiver. Same VID/PID
    // is reused by incompatible YJX products; never probe those by USB ID alone.
    const uint8_t input[]={0x06,0xab,0xff,0x09,0x00,0xa1,0x01,0x85,0xab};
    const uint8_t output[]={0x06,0x01,0xff,0x09,0x10,0xa1,0x01,0x85,0xf0};
    if(![descriptor isKindOfClass:NSData.class])return NO;
    return [descriptor rangeOfData:[NSData dataWithBytes:input length:sizeof input] options:0 range:NSMakeRange(0,descriptor.length)].location!=NSNotFound &&
        [descriptor rangeOfData:[NSData dataWithBytes:output length:sizeof output] options:0 range:NSMakeRange(0,descriptor.length)].location!=NSNotFound;
}
NSData *BBYJXOnlineQuery(void) {
    // Official getDeviceOnline: sendReport(0xF0, [0xED, 1, ...]).
    // This is an online-status read, NOT a fabricated battery command.
    uint8_t payload[63]={0xed,1};return [NSData dataWithBytes:payload length:sizeof payload];
}
NSData *BBYJXBatteryQuery(void) {
    // Same F0/63-byte transport as XUNSHE. Read-only 0x30 query documented
    // by mimuruu/EWEADN-GS02-Pro-Control; no AA/55 transport guessing.
    uint8_t payload[63]={0x30,0xa5,0x0b,0x2e,1,1,1,0,0};
    return [NSData dataWithBytes:payload length:sizeof payload];
}
NSDictionary *BBYJXDecode(NSData *report,uint8_t rid) {
    if(rid!=0xab&&rid!=0xf0)return nil;
    const uint8_t*p=report.bytes;NSUInteger n=report.length;
    if(n&&p[0]==rid){p++;n--;}
    // Official oninputreport parser: command 0x30, battery[7], charge_flag[8].
    // Only these vendor reports are inspected; mouse/key input is discarded.
    if(n<9||p[0]!=0x30||p[7]>100||p[8]>1)return nil;
    return @{@"percent":@(p[7]),@"charging":@(p[8]==1),@"full":@(p[7]==100&&p[8]==0),@"approximate":@NO};
}
NSData *BBQHWQuery(uint8_t sequence) {
    // QHW getBattery 0x0904; WebHID payload excludes the report ID.
    uint8_t b[8]={1,3,0,4,9,0,sequence,0};
    for(int i=1;i<7;i++)b[7]^=b[i];
    return [NSData dataWithBytes:b length:sizeof b];
}
NSDictionary *BBQHWDecode(NSData *report,uint8_t rid,uint8_t sequence) {
    if(rid!=0x4d)return nil;
    const uint8_t *p=report.bytes;NSUInteger n=report.length;
    if(n&&p[0]==rid){p++;n--;}
    if(n<10||p[0]!=1||p[1]!=3||p[2]!=2||p[3]!=4||p[4]!=9||p[5]!=0||p[6]!=sequence)return nil;
    uint8_t checksum=0;for(NSUInteger i=1;i<9;i++)checksum^=p[i];
    if(checksum!=p[9]||p[7]>2||p[8]>100)return nil;
    return @{ @"percent":@(p[8]),@"charging":@(p[7]==1),@"full":@(p[7]==2),@"approximate":@NO };
}
NSDictionary *BBLogitechEnvelope(NSData *report,uint8_t rid) {
    if(rid!=0x10&&rid!=0x11)return nil;
    const uint8_t *p=report.bytes;NSUInteger n=report.length;
    if(n&&p[0]==rid){p++;n--;}
    if(n<(rid==0x10?6:19))return nil;
    return @{@"slot":@(p[0]),@"feature":@(p[1]),@"function":@(p[2]),@"payload":[NSData dataWithBytes:p+3 length:n-3]};
}
NSDictionary *BBLogitechDecodeBattery(NSData *payload,uint16_t feature) {
    const uint8_t *p=payload.bytes;if(payload.length<3)return nil;
    if(feature!=0x1004&&feature!=0x1000)return nil;
    // 1004: state-of-charge, discrete level, charging status. 1000: level, next level, status.
    if(p[0]>100 || p[2]>=4)return nil;
    if(feature==0x1004 && p[0]==0 && p[1]!=0)return nil;
    // 1000 uses zero for an unavailable level. Do not publish a fictitious empty battery.
    if(feature==0x1000&&p[0]==0)return nil;
    return @{@"percent":@(p[0]),@"charging":@(p[2]==1||p[2]==2),@"full":@(p[2]==3),@"approximate":@NO};
}
