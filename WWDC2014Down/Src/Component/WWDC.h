/*
 WWDC.h
 project
 Created by author on 09/06/2014 05:18AM.
 Copyright (c) 2014 author. All rights reserved.
 */
@interface WWDC : XXXDataModel
@property (nonatomic, assign) NSInteger ID;
@property (nonatomic, strong) NSString *wwdcYear;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSString *platform;
@property (nonatomic, strong) NSString *hdLink;
@property (nonatomic, strong) NSString *sdLink;
@property (nonatomic, strong) NSString *pdfLink;
@property (nonatomic, strong) NSString *details;
@property (nonatomic, assign) NSInteger sortOrder;
/*init property member var by parsing NSDictionary parameter*/
- (id)initWithDictionary:(NSDictionary *)dictionary;
/*save new model object*/
- (BOOL)save;
/*save updated model object*/
- (BOOL)update;
/*delete current model object*/
- (BOOL)delete;
@end