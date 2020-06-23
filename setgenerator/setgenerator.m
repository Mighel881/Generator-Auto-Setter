#include <CoreFoundation/CoreFoundation.h>

void usage()
{
    printf("Usage:\tsetgenerator [generator]\n");
    printf("\t-s\tShow current setting.\n");
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
        return 2;
    }

    if (argc > 2) {
        usage();
        return 3;
    }

    if (argc == 2) {
        if (strcmp(argv[1], "-s") == 0) {
            if (access("/var/mobile/Library/Preferences/com.michael.generator.plist", F_OK) == 0) {
                printf("The currently set generator is %s.\n", [[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.michael.generator.plist"][@"generator"] UTF8String]);
            } else {
                printf("The currently set generator is 0x1111111111111111.\n");
            }
            return 0;
        } else if (argv[1][0] != '0' || argv[1][1] != 'x' || strlen(argv[1]) != 18) {
            usage();
            return 3;
        } else {
            if (access("/var/mobile/Library/Preferences/com.michael.generator.plist", F_OK) == 0) {
                remove("/var/mobile/Library/Preferences/com.michael.generator.plist");
            }
            [[NSDictionary dictionary] writeToFile:@"/var/mobile/Library/Preferences/com.michael.generator.plist" atomically:NO];
            modifyPlist(@"/var/mobile/Library/Preferences/com.michael.generator.plist", ^(id plist) {
                plist[@"generator"] = [NSString stringWithUTF8String:argv[1]];
            });
        }
    }

    int ret = 1;
    if (access("/var/mobile/Library/Preferences/com.michael.generator.plist", F_OK) == 0) {
        ret = system([[NSString stringWithFormat:@"dimentio %@", [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.michael.generator.plist"][@"generator"]] UTF8String]);
    } else {
        ret = system("dimentio 0x1111111111111111");
    }

    return ret;
}