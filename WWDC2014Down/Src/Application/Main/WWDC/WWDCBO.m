//
//  WWDCBO.m
//  WWDC2014Down
//
//  Created by @iosxtools on Twitter on 14-5-28.
//  Copyright (c) 2014 http://www.iosxtools.com All rights reserved.
//

#import "WWDCBO.h"
#import "WWDCCategoryTransformer.h"
#import "WWDCDownloadTransformer.h"
#import "WWDCDAO.h"
#import "WWDC.h"
#import "Track.h"
#import "TrackDAO.h"
#import "WWDCDownload.h"
#import "WWDCDownloadDAO.h"
#import "WWDC+Download_Selection.h"

#define  LocalTest

@interface WWDCBO ()
@property(nonatomic,strong)NSValueTransformer *categoryTransformer;
@property(nonatomic,strong)NSValueTransformer *downloadTransformer;
@property(nonatomic,strong)WWDCDAO *wwdcDAO;
@property(nonatomic,strong)WWDCDownloadDAO *wwdcDownloadDAO;
@property(nonatomic,strong)TrackDAO *trackDAO;
@end

@implementation WWDCBO



- (void)parseWWDCDownloadLink
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self clearAll];
        
        
       
        //NSString * string = [[NSString alloc]initWithContentsOfURL:url];
        
#ifdef LocalTest
        NSString *path = [[NSBundle mainBundle] pathForResource:@"wwdc2014" ofType:@"html"];
        
        NSString *webContent = [NSString  stringWithContentsOfFile:path usedEncoding:NULL error:NULL];
#else
        
        NSURL * url = [NSURL URLWithString:@"https://developer.apple.com/videos/wwdc/2014/"];
        
        NSString *webContent = [[NSString alloc] initWithContentsOfURL:url usedEncoding:NULL error:NULL];
        
        
        if(!webContent){
            NSLog(@"wwdc link error!");
            return ;
        }
#endif
        
        OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:webContent];
        // OCGumboElement *root = document.rootElement;
        
        NSArray *session=document.Query(@"li.session");
        NSInteger ID = 1;
        NSInteger downID = 1;
        for(OCGumboElement *elm in session){
            //NSLog(@"elm=%@",elm.t);
            //elm.Query(@"<ul>")
            
            NSArray *videoNodes = elm.Query(@"ul").children(@"li");
            
            NSArray *downloadHREFNodes = elm.Query(@"p.download").children(@"a");
            
            NSInteger videoNodeCount = [videoNodes count];
            
            if(videoNodeCount<=2)
            {
                continue;
            }
            
            
            OCGumboElement *divDescParentNode = elm.Query(@"div.description")[0];
            OCGumboText *descNode = divDescParentNode.Query(@"p").first().childNodes[0];
            
            NSString *desc = [descNode data].trim;
            
            //OCGumboText *titleNode = elm.Query(@"ul").children(@"li").first().childNodes[0];
            OCGumboText *titleNode  = [videoNodes[0] childNodes][0];
            
            NSString *title = [titleNode data].trim;
            
            OCGumboText *categoryNode  = [videoNodes[1] childNodes][0];
            NSString *category= [categoryNode data].trim;
            
            OCGumboText *platformNode  = [videoNodes[2] childNodes][0];
            NSString *platform= [platformNode data].trim;
            
            NSLog(@"title=%@ track=%@ platform=%@",title,category,platform);
            
            
            NSInteger downloadHREfNodeCount = [downloadHREFNodes count];
            
            if(downloadHREfNodeCount<=1)
            {
                continue;
            }
            
            NSString *hdLink;
            NSString *sdLink;
            NSString *pdfLink;
            
            for(OCGumboElement *linkElm in downloadHREFNodes){
                //OCGumboNode *link = linkElm;
                NSLog(@"from:[%@](%@)",linkElm.text().trim, linkElm.attr(@"href"));
                NSString *type = linkElm.text().trim;
                NSString *link = linkElm.attr(@"href").trim;
                if([type isEqualToString:@"HD"]){
                    hdLink = link;
                }
                if([type isEqualToString:@"SD"]){
                    sdLink = link;
                }
                if([type isEqualToString:@"PDF"]){
                    pdfLink = link;
                }
            }
            
            WWDC *wwdc = [[WWDC alloc]init];
            wwdc.ID = ID;
            wwdc.title = title;
            wwdc.category = category;
            wwdc.platform = platform;
            wwdc.hdLink = hdLink;
            wwdc.sdLink = sdLink;
            wwdc.pdfLink = pdfLink;
            wwdc.wwdcYear =@"2014";
            
            if(desc.length>0)
            {
                wwdc.details = desc;
            }
            
            
            BOOL ret = [wwdc save];
            
            DLog(@"wwdc save %d",ret);
            
            Track *track = [[Track alloc]init];
            track.name = category;
            track.ID =ID;
            [track save];
            
           
            
            //download link save
            WWDCDownload *download = [[WWDCDownload alloc]init];
            
            if(hdLink)
            {
                download.wwdcID = ID;
                download.type = WWDCVedioHDType;
                download.ID = downID++;
                [download save];
            }
           
            
            if(sdLink)
            {
                download.type = WWDCVedioSDType;
                download.ID = downID++;
                [download save];
            }
            
            
            if(pdfLink)
            {
                download.type = WWDCVedioPDFType;
                download.ID = downID++;
                [download save];
            }

            
            ID++;
            
        }
        //<li class="session
        
        //Parse Completed,Notify Observer
        dispatch_async(dispatch_get_main_queue(),^
                       {
                           [[NSNotificationCenter defaultCenter]postNotificationName:kDownloadURLParserFinishedNotification object:nil];
                           
                       }
                       );
        
        
    });
    
    //parse finished notify
    
}

- (void)clearAll
{
    [self.wwdcDAO clearAll];
    [self.wwdcDownloadDAO clearAll];
    [self.trackDAO clearAll];
    
}
- (NSArray*)categoryTreeNodes:(NSArray*)cateModels
{
    return [self.categoryTransformer transformedValue:cateModels];
}



- (NSArray*)wwdcItemsByTrack:(NSString*)trackName;
{
    if(!trackName || trackName.length<=0)
    {
        return nil;
    }

    NSArray *items = [self.wwdcDAO findByAttributes:@{@"category":trackName}];
    [self updateLinkSelection:items];
    return items;
}

- (NSArray*)wwdcItemsByFilter:(NSString*)filter;
{
    if(!filter || filter.length<=0)
    {
        return nil;
    }
    NSArray *originalitems = [self.wwdcDAO  findAll];
    NSMutableArray *items = [NSMutableArray arrayWithArray:originalitems];
    NSString *search = [NSString stringWithFormat:@"SELF.title contains[c] '%@'",filter];
    NSPredicate *sPredicate = [NSPredicate predicateWithFormat:search];
    [items filterUsingPredicate:sPredicate];
    [self updateLinkSelection:items];
    return items;
}

- (NSArray*)wwdcAllVedioItems
{
    NSArray *items = [self.wwdcDAO  findAll];
    [self updateLinkSelection:items];
    return items;
}

- (void)updateLinkSelection:(NSArray*)items
{
    for(WWDC *wwdc in items)
    {
        wwdc.isSelectedHD = YES;
        wwdc.isSelectedSD = YES;
        wwdc.isSelectedPDF = YES;
    }

}

- (NSArray*)wwdcAllDownloadTableItems
{
    return [self.downloadTransformer transformedValue:[self wwdcAllDownloadItems]];
}

- (NSArray*)wwdcAllDownloadItems
{
    return [self.wwdcDownloadDAO findAll];
}

- (WWDC*)wwdcWithID:(NSInteger)ID
{
    return [self.wwdcDAO findByKey:@{@"ID":@(ID)}];
}

- (WWDCDownload*)wwdcDownloadWithWWDCID:(NSInteger)ID type:(WWDCVedioType)type
{
    NSArray *items = [self.wwdcDownloadDAO findByAttributes:@{@"wwdcID":@(ID),@"type":@(type)}];
    if([items count]>0){
        return items[0];
    }
    return nil;
}

- (NSArray*)wwdcAllDownloadTableItemsFromWWDCS:(NSArray*)wwdcs;
{
    return [self.downloadTransformer transformedValue:wwdcs];
}

- (NSValueTransformer*)categoryTransformer{
    if(!_categoryTransformer){
        _categoryTransformer = [NSValueTransformer valueTransformerForName:WWDCCategoryTransformerName];
    }
    return _categoryTransformer;
}

- (NSValueTransformer*)downloadTransformer{
    if(!_downloadTransformer){
        _downloadTransformer = [NSValueTransformer valueTransformerForName:WWDCDownloadTransformerName];
    }
    return _downloadTransformer;
}

- (WWDCDAO*)wwdcDAO
{
    if(!_wwdcDAO){
        _wwdcDAO = [[WWDCDAO alloc]init];
    }
    return _wwdcDAO;
}

- (WWDCDownloadDAO*)wwdcDownloadDAO
{
    if(!_wwdcDownloadDAO){
        _wwdcDownloadDAO = [[WWDCDownloadDAO alloc]init];
    }
    return _wwdcDownloadDAO;
}

- (TrackDAO*)trackDAO
{
    if(!_trackDAO){
        _trackDAO = [[TrackDAO alloc]init];
    }
    return _trackDAO;
}
@end
