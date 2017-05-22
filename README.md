# AJ-Squid-ACL-Helper
This is a single acl helper, compatible with big black lists, just to match urls with acls, keep use of other squid config, like http_access, and other matchs acls in default config.
This keep centralized config in squid with high performance and no reload for new urls, nice to big lists ^_^.

# Load in squid.conf with:
        external_acl_type aj_acl %ACL %DST %URI /path/of/file/aj_helper.pl
# Use to match:
        acl porn external aj_acl
        acl mylist external aj_acl
# Mange lists with 
        acl.pl add porn url sexy.com
        acl.pl del porn url sexy.com
        acl.pl purge porn
        acl.pl purge porn domain
        acl.pl list
        acl.pl list porn er
