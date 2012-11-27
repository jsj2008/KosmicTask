/*
 *  MGSApplicationMenu.h
 *  KosmicTask
 *
 *  Created by Jonathan on 13/12/2009.
 *  Copyright 2009 mugginsoft.com. All rights reserved.
 *
 */

// view menu tags
enum _MGSViewMenuModeTag {
	kMGS_MENU_TAG_VIEW_MODE_PUBLIC = 0,
	kMGS_MENU_TAG_VIEW_MODE_TRUSTED,
	kMGS_MENU_TAG_VIEW_MODE_CONFIGURATION,
};
typedef NSInteger eMGSViewMenuModeTag;

enum _MGSViewMenuEditModeTag {
	kMGS_MENU_TAG_VIEW_EDIT_MODE_CONFIGURE = 0,
	kMGS_MENU_TAG_VIEW_EDIT_MODE_SCRIPT,
	kMGS_MENU_TAG_VIEW_EDIT_MODE_RUN,
};
typedef NSInteger MGSViewMenuEditModeTag;

enum _MGSViewMenuShowTag {
	kMGS_MENU_TAG_VIEW_SHOW_TOP_BROWSER = 0,
	kMGS_MENU_TAG_VIEW_SHOW_BOTTOM_DETAIL,
	kMGS_MENU_TAG_VIEW_SHOW_SIDEBAR,
};
typedef NSInteger eMGSViewMenuShowTag;

enum _MGSViewMenuViewAsTag {
	kMGS_MENU_TAG_VIEW_DOCUMENT = 0,
	kMGS_MENU_TAG_VIEW_ICON,
	kMGS_MENU_TAG_VIEW_LIST,
    kMGS_MENU_TAG_VIEW_LOG,
};
typedef NSInteger eMGSViewMenuViewAsTag;
