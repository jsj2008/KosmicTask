/*
 *  MGSMotherModes.h
 *  Mother
 *
 *  Created by Jonathan on 08/02/2008.
 *  Copyright 2008 Mugginsoft. All rights reserved.
 *
 */

// Mother in run action  or edit action mode
enum _eMGSMotherRunMode {
	kMGSMotherRunModePublic = 0,
	kMGSMotherRunModeAuthenticatedUser,
	kMGSMotherRunModeConfigure,
};
typedef NSInteger eMGSMotherRunMode;

enum _eMGSMotherEditMode {
	kMGSMotherEditModeConfigure = 0,
	kMGSMotherEditModeScript = 1,
	kMGSMotherEditModeRun = 2,
};
typedef NSInteger eMGSMotherEditMode;

enum _eMGSMotherWindowSizeMode {
	kMGSMotherSizeModeNormal = 0,
	kMGSMotherSizeModeMinimal = 1,
};
typedef NSInteger eMGSMotherWindowSizeMode;

// mother view config ID
enum _eMGSMotherViewConfig {
	kMGSMotherViewConfigSidebar = 0,
	kMGSMotherViewConfigGroupList = 1,
	kMGSMotherViewConfigBrowser = 2,
	kMGSMotherViewConfigDetail = 3,
	kMGSMotherViewConfigActionTabs = 4,
	kMGSMotherViewConfigMinimal = 5,
	kMGSMotherViewConfigDocument = 6,
	kMGSMotherViewConfigIcon = 7,
	kMGSMotherViewConfigList = 8,
	kMGSMotherViewConfigScript = 9,
    kMGSMotherViewConfigLog = 10,
};
typedef NSInteger eMGSMotherViewConfig;

// mother result view toggles
enum _eMGSMotherResultView {
	kMGSMotherResultViewFirst = 0,
	kMGSMotherResultViewDocument = kMGSMotherResultViewFirst,
	kMGSMotherResultViewIcon = 1,
	kMGSMotherResultViewList = 2,
    kMGSMotherResultViewLog = 3,
	kMGSMotherResultViewLast = kMGSMotherResultViewLog,
};
typedef NSInteger eMGSMotherResultView;

enum _eMGSMainBrowserMode {
	kMGSMainBrowseModeHidden = 0,
	kMGSMainBrowseModeTasks,
	kMGSMainBrowseModeSearch,
	kMGSMainBrowseModeSharing,
};
typedef NSInteger eMGSMainBrowserMode;

enum _eMGSViewState {
	kMGSViewStateShow = 0,
	kMGSViewStateHide,
	kMGSViewStateToggleVisibility,
	kMGSViewStateNormalSize,
	kMGSViewStateMinimalSize,
};
typedef NSInteger eMGSViewState;
