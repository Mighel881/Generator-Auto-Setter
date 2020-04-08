#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void usage()
{
    printf("Usage:\tsetgenerator [generator]\n");
}

bool modifyPlist(NSString *filename, void (^function)(id))
{
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil) {
        return false;
    }
    NSPropertyListFormat format = 0;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    if (plist == nil) {
        return false;
    }
    if (function) {
        function(plist);
    }
    NSData *newData = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:&error];
    if (newData == nil) {
        return false;
    }
    if (![data isEqual:newData]) {
        if (![newData writeToFile:filename atomically:YES]) {
            return false;
        }
    }
    return true;
}

int main(int argc, char **argv)
{
    if (getuid() != 0) {
        setuid(0);
    }
    
    if (getuid() != 0) {
        printf("Can't set uid as 0.\n");
        return 1;
    }
    
    if (argc > 2) {
        usage();
        return 2;
    }
    
    if (argc == 2) {
        if (argv[1][0] != '0' || argv[1][1] != 'x' || strlen(argv[1]) != 18) {
            usage();
            return 2;
        } else {
            if (access("/var/mobile/Library/Preferences/com.michael.generator.plist", F_OK) == 0) {
                remove("/var/mobile/Library/Preferences/com.michael.generator.plist");
            }
            FILE *fp = fopen("/var/mobile/Library/Preferences/com.michael.generator.plist","a+");
            fprintf(fp, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
            fprintf(fp, "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
            fprintf(fp, "<plist version=\"1.0\">\n");
            fprintf(fp, "<dict>\n");
            fprintf(fp, "</dict>\n");
            fprintf(fp, "</plist>\n");
            fclose(fp);
            modifyPlist(@"/var/mobile/Library/Preferences/com.michael.generator.plist", ^(id plist) {
                plist[@"generator"] = [NSString stringWithUTF8String:argv[1]];
            });
        }
    }
    
    int ret = 0;
    if (access("/var/mobile/Library/Preferences/com.michael.generator.plist", F_OK) == 0) {
        NSString *const generatorPlist = @"/var/mobile/Library/Preferences/com.michael.generator.plist";
        NSDictionary *const generator = [NSDictionary dictionaryWithContentsOfFile:generatorPlist];
        ret = system([NSString stringWithFormat:@"dimentio %@", generator[@"generator"]].UTF8String);
    } else {
        ret = system("dimentio 0x1111111111111111");
    }
    
    return ret;
}
