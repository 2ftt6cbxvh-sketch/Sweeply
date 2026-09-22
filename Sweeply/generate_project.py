import os
import uuid

def gen_id():
    return uuid.uuid4().hex[:24].upper()

def main():
    proj_dir = "/Users/ganeshvarma/Desktop/assignment_maail/Sweeply"
    app_dir = os.path.join(proj_dir, "Sweeply")
    tests_dir = os.path.join(proj_dir, "SweeplyTests")
    
    app_files = []
    for root, _, filenames in os.walk(app_dir):
        for f in filenames:
            if f.endswith(".swift"):
                rel_path = os.path.relpath(os.path.join(root, f), proj_dir)
                app_files.append((f, rel_path))
            elif f == "Assets.xcassets":
                pass
    
    xcassets_rel = "Sweeply/Resources/Assets.xcassets"
    infoplist_rel = "Sweeply/App/Info.plist"
    
    test_files = []
    for root, _, filenames in os.walk(tests_dir):
        for f in filenames:
            if f.endswith(".swift"):
                rel_path = os.path.relpath(os.path.join(root, f), proj_dir)
                test_files.append((f, rel_path))
                
    # File refs
    filerefs = {} # path -> (file_id, build_id)
    for fname, fpath in app_files:
        filerefs[fpath] = (gen_id(), gen_id())
    for fname, fpath in test_files:
        filerefs[fpath] = (gen_id(), gen_id())
        
    xcassets_file_id = gen_id()
    xcassets_build_id = gen_id()
    
    infoplist_file_id = gen_id()
    
    app_product_id = gen_id()
    test_product_id = gen_id()
    
    app_target_id = gen_id()
    test_target_id = gen_id()
    
    app_sources_build_phase = gen_id()
    app_resources_build_phase = gen_id()
    app_frameworks_build_phase = gen_id()
    
    test_sources_build_phase = gen_id()
    test_resources_build_phase = gen_id()
    test_frameworks_build_phase = gen_id()
    
    container_item_proxy_id = gen_id()
    target_dependency_id = gen_id()
    
    main_group_id = gen_id()
    app_group_id = gen_id()
    tests_group_id = gen_id()
    products_group_id = gen_id()
    
    proj_config_debug = gen_id()
    proj_config_release = gen_id()
    proj_config_list = gen_id()
    
    app_config_debug = gen_id()
    app_config_release = gen_id()
    app_config_list = gen_id()
    
    test_config_debug = gen_id()
    test_config_release = gen_id()
    test_config_list = gen_id()
    
    project_id = gen_id()
    
    pbx = []
    pbx.append("// !$*UTF8*$!")
    pbx.append("{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 56;\n\tobjects = {")
    
    # PBXBuildFile
    pbx.append("/* Begin PBXBuildFile section */")
    for fpath, (fid, bid) in filerefs.items():
        fname = os.path.basename(fpath)
        pbx.append(f"\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */; }};")
    pbx.append(f"\t\t{xcassets_build_id} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {xcassets_file_id} /* Assets.xcassets */; }};")
    pbx.append("/* End PBXBuildFile section */\n")
    
    # PBXContainerItemProxy
    pbx.append("/* Begin PBXContainerItemProxy section */")
    pbx.append(f"\t\t{container_item_proxy_id} /* PBXContainerItemProxy */ = {{\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = {project_id} /* Project object */;\n\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = {app_target_id};\n\t\t\tremoteInfo = Sweeply;\n\t\t}};")
    pbx.append("/* End PBXContainerItemProxy section */\n")
    
    # PBXFileReference
    pbx.append("/* Begin PBXFileReference section */")
    pbx.append(f"\t\t{app_product_id} /* Sweeply.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Sweeply.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    pbx.append(f"\t\t{test_product_id} /* SweeplyTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = SweeplyTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
    for fpath, (fid, bid) in filerefs.items():
        fname = os.path.basename(fpath)
        pbx.append(f"\t\t{fid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{fpath}\"; sourceTree = \"<group>\"; }};")
    pbx.append(f"\t\t{xcassets_file_id} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = \"{xcassets_rel}\"; sourceTree = \"<group>\"; }};")
    pbx.append(f"\t\t{infoplist_file_id} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = \"{infoplist_rel}\"; sourceTree = \"<group>\"; }};")
    pbx.append("/* End PBXFileReference section */\n")
    
    # PBXFrameworksBuildPhase
    pbx.append("/* Begin PBXFrameworksBuildPhase section */")
    pbx.append(f"\t\t{app_frameworks_build_phase} /* Frameworks */ = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};")
    pbx.append(f"\t\t{test_frameworks_build_phase} /* Frameworks */ = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};")
    pbx.append("/* End PBXFrameworksBuildPhase section */\n")
    
    # PBXGroup
    pbx.append("/* Begin PBXGroup section */")
    
    # Main group
    pbx.append(f"\t\t{main_group_id} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{app_group_id} /* Sweeply */,\n\t\t\t\t{tests_group_id} /* SweeplyTests */,\n\t\t\t\t{products_group_id} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")
    
    # Products group
    pbx.append(f"\t\t{products_group_id} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{app_product_id} /* Sweeply.app */,\n\t\t\t\t{test_product_id} /* SweeplyTests.xctest */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")
    
    # App Group
    app_children = [filerefs[p][0] for _, p in app_files]
    app_children.append(xcassets_file_id)
    app_children.append(infoplist_file_id)
    app_children_str = ",\n\t\t\t\t".join(app_children)
    pbx.append(f"\t\t{app_group_id} /* Sweeply */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{app_children_str},\n\t\t\t);\n\t\t\tname = Sweeply;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")
    
    # Tests Group
    test_children = [filerefs[p][0] for _, p in test_files]
    test_children_str = ",\n\t\t\t\t".join(test_children)
    pbx.append(f"\t\t{tests_group_id} /* SweeplyTests */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{test_children_str},\n\t\t\t);\n\t\t\tname = SweeplyTests;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")
    
    pbx.append("/* End PBXGroup section */\n")
    
    # PBXNativeTarget
    pbx.append("/* Begin PBXNativeTarget section */")
    
    # App target
    app_sources_list = [filerefs[p][1] for _, p in app_files]
    app_sources_str = ",\n\t\t\t\t".join(app_sources_list)
    pbx.append(f"\t\t{app_target_id} /* Sweeply */ = {{\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = {app_config_list} /* Build configuration list for PBXNativeTarget \"Sweeply\" */;\n\t\t\tbuildPhases = (\n\t\t\t\t{app_sources_build_phase} /* Sources */,\n\t\t\t\t{app_frameworks_build_phase} /* Frameworks */,\n\t\t\t\t{app_resources_build_phase} /* Resources */,\n\t\t\t);\n\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n\t\t\t);\n\t\t\tname = Sweeply;\n\t\t\tproductName = Sweeply;\n\t\t\tproductReference = {app_product_id} /* Sweeply.app */;\n\t\t\tproductType = \"com.apple.product-type.application\";\n\t\t}};")
    
    # Test target
    test_sources_list = [filerefs[p][1] for _, p in test_files]
    test_sources_str = ",\n\t\t\t\t".join(test_sources_list)
    pbx.append(f"\t\t{test_target_id} /* SweeplyTests */ = {{\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = {test_config_list} /* Build configuration list for PBXNativeTarget \"SweeplyTests\" */;\n\t\t\tbuildPhases = (\n\t\t\t\t{test_sources_build_phase} /* Sources */,\n\t\t\t\t{test_frameworks_build_phase} /* Frameworks */,\n\t\t\t\t{test_resources_build_phase} /* Resources */,\n\t\t\t);\n\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n\t\t\t\t{target_dependency_id} /* PBXTargetDependency */,\n\t\t\t);\n\t\t\tname = SweeplyTests;\n\t\t\tproductName = SweeplyTests;\n\t\t\tproductReference = {test_product_id} /* SweeplyTests.xctest */;\n\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";\n\t\t}};")
    
    pbx.append("/* End PBXNativeTarget section */\n")
    
    # PBXProject
    pbx.append("/* Begin PBXProject section */")
    pbx.append(f"""\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{app_target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t\t{test_target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t\tTestTargetID = {app_target_id};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {proj_config_list} /* Build configuration list for PBXProject "Sweeply" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{app_target_id} /* Sweeply */,
\t\t\t\t{test_target_id} /* SweeplyTests */,
\t\t\t);
\t\t}};""")
    pbx.append("/* End PBXProject section */\n")
    
    # PBXResourcesBuildPhase
    pbx.append("/* Begin PBXResourcesBuildPhase section */")
    pbx.append(f"\t\t{app_resources_build_phase} /* Resources */ = {{\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t{xcassets_build_id} /* Assets.xcassets in Resources */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};")
    pbx.append(f"\t\t{test_resources_build_phase} /* Resources */ = {{\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};")
    pbx.append("/* End PBXResourcesBuildPhase section */\n")
    
    # PBXSourcesBuildPhase
    pbx.append("/* Begin PBXSourcesBuildPhase section */")
    pbx.append(f"\t\t{app_sources_build_phase} /* Sources */ = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t{app_sources_str},\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};")
    pbx.append(f"\t\t{test_sources_build_phase} /* Sources */ = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t{test_sources_str},\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};")
    pbx.append("/* End PBXSourcesBuildPhase section */\n")
    
    # PBXTargetDependency
    pbx.append("/* Begin PBXTargetDependency section */")
    pbx.append(f"\t\t{target_dependency_id} /* PBXTargetDependency */ = {{\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = {app_target_id} /* Sweeply */;\n\t\t\ttargetProxy = {container_item_proxy_id} /* PBXContainerItemProxy */;\n\t\t}};")
    pbx.append("/* End PBXTargetDependency section */\n")
    
    # XCBuildConfiguration
    pbx.append("/* Begin XCBuildConfiguration section */")
    pbx.append(f"""\t\t{proj_config_debug} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};""")
    pbx.append(f"""\t\t{proj_config_release} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = "wholemodule";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};""")
    pbx.append(f"""\t\t{app_config_debug} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = Sweeply/App/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.appfactory.Sweeply;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};""")
    pbx.append(f"""\t\t{app_config_release} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = Sweeply/App/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.appfactory.Sweeply;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Release;
\t\t}};""")
    pbx.append(f"""\t\t{test_config_debug} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.appfactory.SweeplyTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Sweeply.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Sweeply";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};""")
    pbx.append(f"""\t\t{test_config_release} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.appfactory.SweeplyTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Sweeply.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Sweeply";
\t\t\t}};
\t\t\tname = Release;
\t\t}};""")
    pbx.append("/* End XCBuildConfiguration section */\n")
    
    # XCConfigurationList
    pbx.append("/* Begin XCConfigurationList section */")
    pbx.append(f"""\t\t{proj_config_list} /* Build configuration list for PBXProject "Sweeply" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{proj_config_debug} /* Debug */,
\t\t\t\t{proj_config_release} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};""")
    pbx.append(f"""\t\t{app_config_list} /* Build configuration list for PBXNativeTarget "Sweeply" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{app_config_debug} /* Debug */,
\t\t\t\t{app_config_release} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};""")
    pbx.append(f"""\t\t{test_config_list} /* Build configuration list for PBXNativeTarget "SweeplyTests" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{test_config_debug} /* Debug */,
\t\t\t\t{test_config_release} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};""")
    pbx.append("/* End XCConfigurationList section */\n")
    
    pbx.append("\t};\n\trootObject = " + project_id + " /* Project object */;\n}")
    
    xcodeproj_dir = os.path.join(proj_dir, "Sweeply.xcodeproj")
    os.makedirs(xcodeproj_dir, exist_ok=True)
    pbx_file = os.path.join(xcodeproj_dir, "project.pbxproj")
    with open(pbx_file, "w") as f:
        f.write("\n".join(pbx))
    print(f"Wrote {pbx_file}")

    # Shared scheme
    scheme_dir = os.path.join(xcodeproj_dir, "xcshareddata", "xcschemes")
    os.makedirs(scheme_dir, exist_ok=True)
    scheme_file = os.path.join(scheme_dir, "Sweeply.xcscheme")
    scheme_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{app_target_id}"
               BuildableName = "Sweeply.app"
               BlueprintName = "Sweeply"
               ReferencedContainer = "container:Sweeply.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{test_target_id}"
               BuildableName = "SweeplyTests.xctest"
               BlueprintName = "SweeplyTests"
               ReferencedContainer = "container:Sweeply.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target_id}"
            BuildableName = "Sweeply.app"
            BlueprintName = "Sweeply"
            ReferencedContainer = "container:Sweeply.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target_id}"
            BuildableName = "Sweeply.app"
            BlueprintName = "Sweeply"
            ReferencedContainer = "container:Sweeply.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    with open(scheme_file, "w") as f:
        f.write(scheme_content)
    print(f"Wrote {scheme_file}")

if __name__ == "__main__":
    main()
