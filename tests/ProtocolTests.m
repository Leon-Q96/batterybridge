#import "Protocol.h"
static void require(BOOL pass,NSString *name){if(!pass){fprintf(stderr,"FAIL %s\n",name.UTF8String);exit(1);}}
int main(){@autoreleasepool{
NSData*q=BBQHWQuery(201);const uint8_t*b=q.bytes;require(q.length==8&&b[7]==199,@"QHW request framing and checksum");
uint8_t response[32]={0x4d,1,3,2,4,9,0,201,0,92,0};for(int i=2;i<10;i++)response[10]^=response[i];
NSData*r=[NSData dataWithBytes:response length:32];NSDictionary*d=BBQHWDecode(r,0x4d,201);require([d[@"percent"] intValue]==92&&! [d[@"charging"] boolValue],@"valid QHW battery");
require(!BBQHWDecode(r,0x4d,200),@"reject unrelated sequence");response[10]^=1;require(!BBQHWDecode([NSData dataWithBytes:response length:32],0x4d,201),@"reject bad checksum");
require(!BBQHWDecode([NSData dataWithBytes:response length:4],0x4d,201),@"reject short report");
uint8_t unified[]={94,8,0};d=BBLogitechDecodeBattery([NSData dataWithBytes:unified length:3],0x1004);require([d[@"percent"] intValue]==94,@"unified percent");
unified[2]=1;require([BBLogitechDecodeBattery([NSData dataWithBytes:unified length:3],0x1004)[@"charging"] boolValue],@"charging");
unified[0]=255;require(!BBLogitechDecodeBattery([NSData dataWithBytes:unified length:3],0x1004),@"reject invalid percent");
unified[0]=0;require(!BBLogitechDecodeBattery([NSData dataWithBytes:unified length:3],0x1000),@"legacy unknown is not zero");
uint8_t h[]={0x11,1,6,0x1d,94,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0};d=BBLogitechEnvelope([NSData dataWithBytes:h length:20],0x11);require([d[@"slot"] intValue]==1&&[d[@"feature"] intValue]==6&&[d[@"function"] intValue]==0x1d,@"HID++ native framing");
require(!BBLogitechEnvelope([NSData dataWithBytes:h length:4],0x11),@"reject incomplete HID++");

uint8_t bad[]={0,8,0};require(!BBLogitechDecodeBattery([NSData dataWithBytes:bad length:3],0x1004),@"discrete-only level is not precise zero");
bad[0]=40;bad[2]=4;require(!BBLogitechDecodeBattery([NSData dataWithBytes:bad length:3],0x1004),@"invalid battery status is not published");
response[10]^=1;response[9]=101;response[10]=0;for(int i=2;i<10;i++)response[10]^=response[i];require(!BBQHWDecode([NSData dataWithBytes:response length:32],0x4d,201),@"QHW invalid battery rejected");
require(!BBQHWDecode(r,0x4e,201),@"wrong QHW report ID ignored");
// Official XUNSHE/YJX event format, not the unrelated G7 AA/55 framing.
uint8_t y[]={0xab,0x30,0,0,0,0,0,0,46,0};
d=BBYJXDecode([NSData dataWithBytes:y length:sizeof y],0xab);require([d[@"percent"] intValue]==46&&![d[@"charging"] boolValue],@"YJX native report framing");
y[9]=1;require([BBYJXDecode([NSData dataWithBytes:y+1 length:9],0xf0)[@"charging"] boolValue],@"YJX WebHID payload charging");
y[8]=101;require(!BBYJXDecode([NSData dataWithBytes:y length:sizeof y],0xab),@"YJX rejects out-of-range percent");
y[8]=0;y[9]=0;require([BBYJXDecode([NSData dataWithBytes:y length:sizeof y],0xab)[@"percent"] isEqual:@0],@"YJX accepts explicit zero in valid status frame");
y[9]=255;require(!BBYJXDecode([NSData dataWithBytes:y length:sizeof y],0xab),@"YJX rejects unknown charging flag");
y[9]=0;require(!BBYJXDecode([NSData dataWithBytes:y length:8],0xab),@"YJX rejects truncated status");
require(!BBYJXDecode([NSData dataWithBytes:y length:sizeof y],5),@"mouse input reports never become battery readings");
y[1]=0xed;require(!BBYJXDecode([NSData dataWithBytes:y length:sizeof y],0xab),@"online status is not battery");
uint8_t aa[]={0xaa,0x30,0xa5,0x0b,0x0a,1,1,1,46,0};require(!BBYJXDecode([NSData dataWithBytes:aa length:sizeof aa],0xab),@"other YJX firmware framing is not assumed compatible");
q=BBYJXOnlineQuery();b=q.bytes;require(q.length==63&&b[0]==0xed&&b[1]==1&&b[62]==0,@"official read-only online request");
NSData*descriptor=[[NSData alloc]initWithBase64EncodedString:@"BQEJAqEBCQGhAIUFBQkZASkQFQAlAZUQdQGBAgUBCTAJMRYBgCb/f5UCdRCBBgk4FYElf5UBdQiBBgUMCjgClQGBBsDABQEJBqEBhQKVcHUBFQAlAQUHGQAq/wCBAsAFDAkBoQGFAxkBKv8DFQEm/wOVAXUQgQDABQEJgKEBhQQZgSmDFQAlAZUDdQGBApUFgQHABqv/CQChAYWrFQAm/wAZACr/AJU9dQiBAhkAKv8AlT11CJECwAYB/wkQoQGF8BUAJv8AGQEpCJU/dQiBAhkBKQiRAsA=" options:0];
require(BBYJXDescriptorMatches(descriptor),@"confirmed receiver descriptor matches");
require(!BBYJXDescriptorMatches([NSData data])&&!BBYJXDescriptorMatches(nil),@"shared USB identifier without exact transport is refused");
q=BBYJXBatteryQuery();b=q.bytes;uint8_t expected[]={0x30,0xa5,0x0b,0x2e,1,1,1,0,0};
require(q.length==63&&!memcmp(b,expected,sizeof expected),@"F0 battery query matches documented read-only command");
BOOL padding=YES;for(NSUInteger i=sizeof expected;i<q.length;i++)padding=padding&&b[i]==0;require(padding,@"battery request contains no trailing configuration data");
printf("PASS: 29 protocol checks\n");
}}
