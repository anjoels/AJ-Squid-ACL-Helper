# AJ-Squid-ACL-Helper
http://www.squid-cache.org/Misc/general.html

This is a simple acl helper, compatible with big black lists, just to match urls with acls, keep use of other squid config, like http_access, and other matchs acls in default config.
This keep centralized config in squid with high performance and no reload for new urls, nice to big lists ^_^, like DansGuardian lists or SquidGuard (http://www.squidguard.org/blacklists.html) lists and others ( https://www.malwarepatrol.net/ ).

# Load in squid.conf with:
        external_acl_type aj_acl %ACL %DST %URI /path/of/file/aj_helper.pl
# Use to match, in squid.conf:
        acl porn external aj_acl
        acl mylist external aj_acl
# Manage lists in shell with 
        #> ./acl.pl add porn url sexy.com
        #> ./acl.pl del porn url sexy.com
        #> ./acl.pl purge porn
        #> ./acl.pl purge porn domain
        #> ./acl.pl list
        #> ./acl.pl list porn er
