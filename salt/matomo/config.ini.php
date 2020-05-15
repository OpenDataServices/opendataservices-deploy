; <?php exit; ?> DO NOT REMOVE THIS LINE
; file automatically generated or modified by Matomo; you can manually override the default values in global.ini.php by redefining them in this file.
[database]
host = "127.0.0.1"
username = "piwik"
password = "450727aaee3671a4c6a89ef8837ed49d5490b11bdc51696771fb67c62e5956d3"
dbname = "piwik"
tables_prefix = "piwik_"

[General]
salt = "c47047b8f9d0c90043dccc39fb463875"
trusted_hosts[] = "mon.opendataservices.coop"
trusted_hosts[] = "piwik.opendataservices.coop"
trusted_hosts[] = "mon-4.default.opendataservices.uk0.bigv.io"
enable_processing_unique_visitors_day = 1
enable_processing_unique_visitors_week = 1
enable_processing_unique_visitors_month = 1
enable_processing_unique_visitors_year = 1
enable_processing_unique_visitors_range = 1
delete_logs_older_than = 400
; planio#12371 -- https://piwik.org/faq/how-to/faq_54/#faq_54
; maximum number of rows for any of the Referers tables (keywords, search engines, campaigns, etc.), and Custom variables names
datatable_archiving_maximum_rows_referers = 50000
; maximum number of rows for any of the Referers subtable (search engines by keyword, keyword by campaign, etc.), and Custom variables values
datatable_archiving_maximum_rows_subtable_referers = 50000
; maximum number of rows for any of the Actions tables (pages, downloads, outlinks)
datatable_archiving_maximum_rows_actions = 50000
; maximum number of rows for pages in categories (sub pages, when clicking on the + for a page category)
datatable_archiving_maximum_rows_subtable_actions = 50000
; maximum number of rows for any of the Events tables (Categories, Actions, Names)
datatable_archiving_maximum_rows_events = 5000
; maximum number of rows for sub-tables of the Events tables (eg. for the subtables Categories>Actions or Categories>Names).
datatable_archiving_maximum_rows_subtable_events = 1000
; maximum number of rows for the Custom Variables names report
datatable_archiving_maximum_rows_custom_variables = 50000
; maximum number of rows for the Custom Variables values reports
datatable_archiving_maximum_rows_subtable_custom_variables = 50000

[PluginsInstalled]
PluginsInstalled[] = "Diagnostics"
PluginsInstalled[] = "Login"
PluginsInstalled[] = "CoreAdminHome"
PluginsInstalled[] = "UsersManager"
PluginsInstalled[] = "SitesManager"
PluginsInstalled[] = "Installation"
PluginsInstalled[] = "Monolog"
PluginsInstalled[] = "Intl"
PluginsInstalled[] = "CorePluginsAdmin"
PluginsInstalled[] = "CoreHome"
PluginsInstalled[] = "WebsiteMeasurable"
PluginsInstalled[] = "IntranetMeasurable"
PluginsInstalled[] = "CoreVisualizations"
PluginsInstalled[] = "Proxy"
PluginsInstalled[] = "API"
PluginsInstalled[] = "Widgetize"
PluginsInstalled[] = "Transitions"
PluginsInstalled[] = "LanguagesManager"
PluginsInstalled[] = "Actions"
PluginsInstalled[] = "Dashboard"
PluginsInstalled[] = "MultiSites"
PluginsInstalled[] = "Referrers"
PluginsInstalled[] = "UserLanguage"
PluginsInstalled[] = "DevicesDetection"
PluginsInstalled[] = "Goals"
PluginsInstalled[] = "Ecommerce"
PluginsInstalled[] = "SEO"
PluginsInstalled[] = "Events"
PluginsInstalled[] = "UserCountry"
PluginsInstalled[] = "GeoIp2"
PluginsInstalled[] = "VisitsSummary"
PluginsInstalled[] = "VisitFrequency"
PluginsInstalled[] = "VisitTime"
PluginsInstalled[] = "VisitorInterest"
PluginsInstalled[] = "RssWidget"
PluginsInstalled[] = "Feedback"
PluginsInstalled[] = "TwoFactorAuth"
PluginsInstalled[] = "CoreUpdater"
PluginsInstalled[] = "CoreConsole"
PluginsInstalled[] = "ScheduledReports"
PluginsInstalled[] = "UserCountryMap"
PluginsInstalled[] = "Live"
PluginsInstalled[] = "CustomVariables"
PluginsInstalled[] = "PrivacyManager"
PluginsInstalled[] = "ImageGraph"
PluginsInstalled[] = "Annotations"
PluginsInstalled[] = "MobileMessaging"
PluginsInstalled[] = "Overlay"
PluginsInstalled[] = "SegmentEditor"
PluginsInstalled[] = "Insights"
PluginsInstalled[] = "Morpheus"
PluginsInstalled[] = "Contents"
PluginsInstalled[] = "TestRunner"
PluginsInstalled[] = "BulkTracking"
PluginsInstalled[] = "Resolution"
PluginsInstalled[] = "DevicePlugins"
PluginsInstalled[] = "Heartbeat"
PluginsInstalled[] = "Marketplace"
PluginsInstalled[] = "ProfessionalServices"
PluginsInstalled[] = "UserId"
PluginsInstalled[] = "CustomPiwikJs"
PluginsInstalled[] = "Tour"

