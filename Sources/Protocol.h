#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSData *BBQHWQuery(uint8_t sequence);
FOUNDATION_EXPORT NSDictionary *BBQHWDecode(NSData *report, uint8_t reportID, uint8_t sequence);
FOUNDATION_EXPORT NSDictionary *BBLogitechDecodeBattery(NSData *payload, uint16_t feature);
FOUNDATION_EXPORT NSDictionary *BBLogitechEnvelope(NSData *report, uint8_t reportID);
FOUNDATION_EXPORT BOOL BBYJXDescriptorMatches(NSData *descriptor);
FOUNDATION_EXPORT NSData *BBYJXOnlineQuery(void);
FOUNDATION_EXPORT NSData *BBYJXBatteryQuery(void);
FOUNDATION_EXPORT NSDictionary *BBYJXDecode(NSData *report, uint8_t reportID);
// AULA F75 on the Compx 2.4 GHz receiver (3554:FA09): vendor page 0xFF02,
// report 0x13, 20 bytes. Learned from ushineko/sanshoku aula package.
FOUNDATION_EXPORT BOOL BBCompxDescriptorMatches(NSData *descriptor);
FOUNDATION_EXPORT NSData *BBCompxQuery(void);
FOUNDATION_EXPORT NSDictionary *BBCompxDecode(NSData *report, uint8_t reportID);
