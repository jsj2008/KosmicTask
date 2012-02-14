/*
 *  MGSMotherModes.h
 *  Mother
 *
 *  Created by Jonathan on 08/02/2008.
 *  Copyright 2008 Mugginsoft. All rights reserved.
 *
 */

// Mother in run action  or edit action mode
typedef enum _eMGSMotherRunMode {
	kMGSMotherRunModePublic = 0,
	kMGSMotherRunModeAuthenticatedUser,
	kMGSMotherRunModeConfigure,
}  eMGSMotherRunMode;

typedef enum _eMGSMotherEditMode {
	kMGSMotherEditModeConfigure = 0,
	kMGSMotherEditModeScript = 1,
	kMGSMotherEditModeRun = 2,
}  eMGSMotherEditMode;

typedef enum _eMGSMotherWindowSizeMode {
	kMGSMotherSizeModeNormal = 0,
	kMGSMotherSizeModeMinimal = 1,
}  eMGSMotherWindowSizeMode;

// mother view config ID
typedef enum _eMGSMotherViewConfig {
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
}  eMGSMotherViewConfig;

// mother result view toggles
typedef enum _eMGSMotherResultView {
	kMGSMotherResultViewFirst = 0,
	kMGSMotherResultViewDocument = kMGSMotherResultViewFirst,
	kMGSMotherResultViewIcon = 1,
	kMGSMotherResultViewList = 2,
    kMGSMotherResultViewLog = 3,
	kMGSMotherResultViewLast = kMGSMotherResultViewLog,
}  eMGSMotherResultView;

typedef enum _eMGSMainBrowserMode {
	kMGSMainBrowseModeHidden = 0,
	kMGSMainBrowseModeTasks,
	kMGSMainBrowseModeSearch,
	kMGSMainBrowseModeSharing,
}  eMGSMainBrowserMode;

typedef enum _eMGSViewState {
	kMGSViewStateShow = 0,
	kMGSViewStateHide,
	kMGSViewStateToggleVisibility,
	kMGSViewStateNormalSize,
	kMGSViewStateMinimalSize,
}  eMGSViewState;
