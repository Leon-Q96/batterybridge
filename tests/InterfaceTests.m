// Offscreen AppKit checks. Uses in-memory preferences and never installs or registers login items.
#define main BBApplicationMain
#import "../Sources/main.m"
#undef main
static void ensure(BOOL ok,const char*message){if(!ok){fprintf(stderr,"FAIL: %s\n",message);exit(1);}}
int main(int argc,const char*argv[]){@autoreleasepool{
    BBTestingUI=YES;[NSApplication sharedApplication];[BBPreferences() registerDefaults:@{@"ReportInterval":@3600,@"AutoStartEnabled":@YES}];
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    NSArray*fixtures=@[@{@"name":@"G304 X LIGHTSPEED",@"identity":@"test.mouse",@"category":@"Mouse",@"connected":@YES,@"fresh":@YES,@"percent":@94,@"charging":@NO,@"full":@NO,@"updated":@(now),@"mapped":@YES,@"published":@YES,@"status":@"已映射到系统电量",@"selectable":@YES},@{@"name":@"MCHOSE K87 V3",@"identity":@"test.keyboard",@"category":@"Keyboard",@"connected":@YES,@"fresh":@YES,@"percent":@92,@"charging":@NO,@"full":@NO,@"updated":@(now),@"mapped":@YES,@"published":@YES,@"status":@"已映射到系统电量",@"selectable":@YES}];
    BBApp*app=[BBApp new];app.engine=[BBEngine new];app.engine.snapshot=fixtures;app.statusMenu=[NSMenu new];app.statusMenu.autoenablesItems=NO;[app menuNeedsUpdate:app.statusMenu];
    NSMenuItem*device=nil,*period=nil,*startup=nil;
    for(NSMenuItem*i in app.statusMenu.itemArray){if([i.title isEqual:@"映射设备"])device=i;if([i.title isEqual:@"上报周期"])period=i;if([i.title isEqual:@"开机自启"])startup=i;}
    ensure([[app.statusMenu itemAtIndex:0].title containsString:Version],"menu header exposes the running version");
    ensure(device.submenu.numberOfItems==2,"device submenu contains only device entries, no status explanations");
    ensure(period.submenu.numberOfItems==4,"four reporting intervals");ensure(startup.submenu.numberOfItems==2,"startup uses on/off submenu");
    ensure([startup.title isEqual:@"开机自启"]&&[startup.submenu itemAtIndex:0].state==NSControlStateValueOn,"startup enabled state is explicit");
    [app setAutoStart:[startup.submenu itemAtIndex:1]];[app menuNeedsUpdate:app.statusMenu];for(NSMenuItem*i in app.statusMenu.itemArray)if([i.title isEqual:@"开机自启"])startup=i;
    ensure([startup.title isEqual:@"开机自启"]&&[startup.submenu itemAtIndex:1].state==NSControlStateValueOn,"startup disabled state is explicit");
    NSMenuItem*three=[NSMenuItem new];three.representedObject=@10800;[app changeInterval:three];ensure(BBInterval([BBPreferences() objectForKey:@"ReportInterval"])==10800,"interval menu saves three hours");
    NSMenuItem*mapping=[NSMenuItem new];mapping.representedObject=@"test.mouse";[app toggleMapping:mapping];ensure(mappingEnabled(@"test.mouse"),"mapping can be enabled");[app toggleMapping:mapping];ensure(!mappingEnabled(@"test.mouse"),"mapping can be disabled");
    ensure(![app applicationShouldTerminateAfterLastWindowClosed:NSApp],"closing window does not terminate app");
    NSInteger show=-1,mapPosition=-1;BOOL removed=YES;
    for(NSInteger i=0;i<app.statusMenu.numberOfItems;i++){NSString*title=[app.statusMenu itemAtIndex:i].title;if([title isEqual:@"显示主界面"])show=i;if([title isEqual:@"映射设备"])mapPosition=i;if([@[@"立即刷新电量",@"设备电量…",@"输入监控设置…",@"停用并卸载…"] containsObject:title])removed=NO;}
    ensure(show>=0&&show<mapPosition,"show main window is above mapping devices");ensure(removed,"redundant status menu commands removed");
    BBDeviceCard*card=[[BBDeviceCard alloc]initWithFrame:NSMakeRect(0,0,298,184) record:fixtures[0]];card.menuTarget=app;NSMenu*context=[card deviceMenu];NSMenuItem*mapCard=[context itemAtIndex:2];
    ensure(mapCard.submenu.numberOfItems==2,"card mapping has explicit on and off choices");
    [app setDeviceMapping:[mapCard.submenu itemAtIndex:0]];ensure(mappingEnabled(@"test.mouse")&&!mappingEnabled(@"test.keyboard"),"card mapping changes only that device");
    context=[card deviceMenu];ensure([[context itemAtIndex:2].title hasSuffix:@"开启"],"context menu reads current mapping rather than stale card snapshot");
    [app setDeviceMapping:[[context itemAtIndex:2].submenu itemAtIndex:1]];ensure(!mappingEnabled(@"test.mouse"),"card mapping can be disabled");
    app.engine.forcePoll=NO;[app refreshDevice:[context itemAtIndex:3]];ensure([app.engine.refreshTargets containsObject:@"test.mouse"]&&app.engine.refreshTargets.count==1&&!app.engine.forcePoll,"single device refresh does not request a global poll");
    BBDeviceCard*unknown=[[BBDeviceCard alloc]initWithFrame:NSMakeRect(0,0,298,184) record:@{@"name":@"Unknown",@"connected":@YES,@"selectable":@NO}];unknown.menuTarget=app;NSMenu*limited=[unknown deviceMenu];ensure(![limited itemAtIndex:2].enabled&&![limited itemAtIndex:3].enabled,"unsupported device cannot map or query");
    NSImage*brand=BBStatusIcon();ensure(brand.isTemplate&&brand.size.width==20,"brand menu bar icon is a monochrome system template");
    [app buildWindow];
    ensure([app.window.title containsString:Version],"window title exposes the running version");
    ensure((app.window.styleMask&NSWindowStyleMaskResizable)!=0,"window allows both dimensions to resize");
    NSMutableArray*many=[fixtures mutableCopy];for(int i=0;i<7;i++)[many addObject:fixtures[i%2]];app.engine.snapshot=many;
    for(NSNumber*legacy in @[@YES,@NO]){
        app.cardsScroll.scrollerStyle=legacy.boolValue?NSScrollerStyleLegacy:NSScrollerStyleOverlay;
        for(NSValue*size in @[[NSValue valueWithSize:NSMakeSize(380,300)],[NSValue valueWithSize:NSMakeSize(660,330)],[NSValue valueWithSize:NSMakeSize(900,620)],[NSValue valueWithSize:NSMakeSize(1400,700)]]){
            [app.window setContentSize:size.sizeValue];app.cardsSignature=nil;[app refresh];
            CGFloat available=app.cardsScroll.contentSize.width;
            ensure(app.cardsView.subviews.count==many.count,"all device cards remain present after resize");
            for(NSView*v in app.cardsView.subviews)ensure(NSMinX(v.frame)>=0&&NSMaxX(v.frame)<=available+0.5,"card stays within viewport including legacy scrollbar");
            ensure(app.cardsView.frame.size.width<=available+0.5&&!app.cardsScroll.hasHorizontalScroller,"no horizontal document overflow");
            NSUInteger cols=0;for(NSView*v in app.cardsView.subviews)if(NSMinY(v.frame)==0)cols++;
            ensure(cols==(size.sizeValue.width==380?1:(size.sizeValue.width==660?2:(size.sizeValue.width==900?2:4))),"card columns respond to window width");
            ensure(app.cardsScroll.frame.size.height==size.sizeValue.height-122,"card viewport grows with window height");
        }
    }
    app.engine.snapshot=fixtures;[app.window setContentSize:NSMakeSize(660,330)];app.cardsSignature=nil;[app refresh];
    NSDictionary*deniedMouse=@{@"name":@"YJX",@"identity":@"test.yjx",@"connected":@YES,@"selectable":@YES,@"status":@"设备访问被拒绝 0xe00002e2"};
    app.engine.snapshot=@[fixtures[1],deniedMouse];app.cardsSignature=nil;[app refresh];
    ensure(!app.authorizeButton.hidden,"a readable keyboard must not hide the mouse permission action");
    BBDeviceCard*deniedCard=[[BBDeviceCard alloc]initWithFrame:NSMakeRect(0,0,298,184) record:deniedMouse];deniedCard.menuTarget=app;
    BOOL hasPermission=NO;for(NSMenuItem*i in deniedCard.deviceMenu.itemArray)hasPermission=hasPermission||i.action==@selector(permission:);
    ensure(hasPermission,"denied device has its own authorization action");
    // Exercise the device-response -> macOS publication path, not just labels.
    uint8_t chargingFrame[]={0xf0,0x30,0xa5,0x95,0x2e,1,1,1,78,1};
    NSDictionary*reading=BBYJXDecode([NSData dataWithBytes:chargingFrame length:sizeof chargingFrame],0xf0);
    NSDictionary*details=BBPowerDetails(@"test.yjx",@"YJX",@"Mouse",reading);
    ensure([details[@"Is Charging"] boolValue]&&![details[@"Is Charged"] boolValue]&&[details[@"Power Source State"] isEqual:@"AC Power"]&&[details[@"Current Capacity"] intValue]==78,"YJX charging response becomes charging AC accessory source");
    NSMutableDictionary*chargingRecord=[@{@"connected":@YES,@"fresh":@YES,@"charging":reading[@"charging"],@"full":reading[@"full"]} mutableCopy];
    ensure([BBChargeStatus(chargingRecord) isEqual:@"正在充电"],"charging shown independently of connection");
    chargingRecord[@"fresh"]=@NO;ensure([BBChargeStatus(chargingRecord) isEqual:@"充电状态未知"],"stale sample cannot claim a current charging state");
    chargingRecord[@"fresh"]=@YES;chargingRecord[@"connected"]=@NO;ensure([BBChargeStatus(chargingRecord) isEqual:@"充电状态未知"],"disconnected receiver cannot claim not charging");
    chargingFrame[8]=100;chargingFrame[9]=0;reading=BBYJXDecode([NSData dataWithBytes:chargingFrame length:sizeof chargingFrame],0xf0);
    details=BBPowerDetails(@"test.yjx",@"YJX",@"Mouse",reading);
    ensure(![details[@"Is Charging"] boolValue]&&[details[@"Is Charged"] boolValue]&&[details[@"Power Source State"] isEqual:@"Battery Power"],"real observed full/not-charging frame has correct macOS flags");
    chargingRecord[@"connected"]=@YES;chargingRecord[@"charging"]=reading[@"charging"];chargingRecord[@"full"]=reading[@"full"];
    ensure([BBChargeStatus(chargingRecord) isEqual:@"未充电 · 已充满"],"full and charging are distinct states");
    NSMutableDictionary*contradictory=[reading mutableCopy];contradictory[@"charging"]=@YES;
    ensure(![BBPowerDetails(@"test.yjx",@"YJX",@"Mouse",contradictory)[@"Is Charged"] boolValue],"macOS never receives charging and charged simultaneously");
    if(argc>1){
        NSDictionary*pending=@{@"name":@"USB Receiver（YJX 鼠标）",@"identity":@"test.yjx",@"category":@"Mouse",@"connected":@YES,@"selectable":@YES,@"status":@"正在监听官方电量上报"};
        app.engine.snapshot=[fixtures arrayByAddingObject:pending];[app.window setContentSize:NSMakeSize(660,530)];app.cardsSignature=nil;[app refresh];
        app.heading.stringValue=@"示例数据 · 可拉伸窗口与三设备布局";NSView*root=app.window.contentView;
        NSBitmapImageRep*rep=[[NSBitmapImageRep alloc]initWithBitmapDataPlanes:NULL pixelsWide:1320 pixelsHigh:1060 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];rep.size=NSMakeSize(660,530);
        NSGraphicsContext*ctx=[NSGraphicsContext graphicsContextWithBitmapImageRep:rep];[NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:ctx];[NSColor.windowBackgroundColor setFill];NSRectFill(root.bounds);[root displayRectIgnoringOpacity:root.bounds inContext:ctx];[NSGraphicsContext restoreGraphicsState];
        NSData*png=[rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];ensure([png writeToFile:[NSString stringWithUTF8String:argv[1]] atomically:YES],"offscreen preview saved");
    }
    puts("PASS: menu, card, lifecycle and responsive window checks (8 resize scenarios)");
}}
