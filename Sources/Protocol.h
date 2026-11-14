#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSData *BBQHWQuery(uint8_t sequence);
FOUNDATION_EXPORT NSDictionary *BBQHWDecode(NSData *report, uint8_t reportID, uint8_t sequence);
FOUNDATION_EXPORT NSDictionary *BBLogitechDecodeBattery(NSData *payload, uint16_t feature);
FOUNDATION_EXPORT NSDictionary *BBLogitechEnvelope(NSData *report, uint8_t reportID);
FOUNDATION_EXPORT BOOL BBYJXDescriptorMatches(NSData *descriptor);
FOUNDATION_EXPORT NSData *BBYJXOnlineQuery(void);
FOUNDATION_EXPORT NSData *BBYJXBatteryQuery(void);
FOUNDATION_EXPORT NSDictionary *BBYJXDecode(NSData *report, uint8_t reportID);
