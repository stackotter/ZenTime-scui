#!/usr/bin/env python3
"""Generate a minimal, valid ZenTime.xcodeproj/project.pbxproj (macOS app, no deps)."""
import os, hashlib

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.join(ROOT, "ZenTime")
PROJ = "ZenTime"
BUNDLE_ID = "com.zentime.ZenTime"

def uid(seed):
    """Deterministic 24-char uppercase-hex id from a seed string."""
    return hashlib.sha1(seed.encode()).hexdigest()[:24].upper()

# Collect sources & resources.
swift_files = sorted(f for f in os.listdir(SRC_DIR) if f.endswith(".swift"))
resources = ["Assets.xcassets"]
entitlements = "ZenTime.entitlements"

# IDs
proj_id = uid("project")
target_id = uid("target")
product_id = uid("product")
main_group = uid("maingroup")
src_group = uid("srcgroup")
products_group = uid("productsgroup")
sources_phase = uid("sourcesphase")
resources_phase = uid("resourcesphase")
frameworks_phase = uid("frameworksphase")
proj_cfg_list = uid("projcfglist")
target_cfg_list = uid("targetcfglist")
proj_debug = uid("projdebug")
proj_release = uid("projrelease")
target_debug = uid("targetdebug")
target_release = uid("targetrelease")

file_refs = {}   # path -> id
build_files = {} # path -> id
for f in swift_files + resources + [entitlements]:
    file_refs[f] = uid("ref:" + f)
for f in swift_files:
    build_files[f] = uid("build:" + f)
for f in resources:
    build_files[f] = uid("buildres:" + f)

L = []
def w(s): L.append(s)

w("// !$*UTF8*$!")
w("{")
w("\tarchiveVersion = 1;")
w("\tclasses = {")
w("\t};")
w("\tobjectVersion = 56;")
w("\tobjects = {")

# PBXBuildFile
w("\n/* Begin PBXBuildFile section */")
for f in swift_files:
    w(f'\t\t{build_files[f]} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {f} */; }};')
for f in resources:
    w(f'\t\t{build_files[f]} /* {f} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {f} */; }};')
w("/* End PBXBuildFile section */")

# PBXFileReference
w("\n/* Begin PBXFileReference section */")
w(f'\t\t{product_id} /* {PROJ}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {PROJ}.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
for f in swift_files:
    w(f'\t\t{file_refs[f]} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{f}"; sourceTree = "<group>"; }};')
for f in resources:
    w(f'\t\t{file_refs[f]} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "{f}"; sourceTree = "<group>"; }};')
w(f'\t\t{file_refs[entitlements]} /* {entitlements} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = "{entitlements}"; sourceTree = "<group>"; }};')
w("/* End PBXFileReference section */")

# PBXFrameworksBuildPhase
w("\n/* Begin PBXFrameworksBuildPhase section */")
w(f"\t\t{frameworks_phase} /* Frameworks */ = {{")
w("\t\t\tisa = PBXFrameworksBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXFrameworksBuildPhase section */")

# PBXGroup
w("\n/* Begin PBXGroup section */")
w(f"\t\t{main_group} = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w(f"\t\t\t\t{src_group} /* {PROJ} */,")
w(f"\t\t\t\t{products_group} /* Products */,")
w("\t\t\t);")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

w(f"\t\t{src_group} /* {PROJ} */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
for f in swift_files:
    w(f"\t\t\t\t{file_refs[f]} /* {f} */,")
for f in resources:
    w(f"\t\t\t\t{file_refs[f]} /* {f} */,")
w(f"\t\t\t\t{file_refs[entitlements]} /* {entitlements} */,")
w("\t\t\t);")
w(f"\t\t\tpath = {PROJ};")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

w(f"\t\t{products_group} /* Products */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w(f"\t\t\t\t{product_id} /* {PROJ}.app */,")
w("\t\t\t);")
w("\t\t\tname = Products;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")
w("/* End PBXGroup section */")

# PBXNativeTarget
w("\n/* Begin PBXNativeTarget section */")
w(f"\t\t{target_id} /* {PROJ} */ = {{")
w("\t\t\tisa = PBXNativeTarget;")
w(f"\t\t\tbuildConfigurationList = {target_cfg_list} /* Build configuration list for PBXNativeTarget \"{PROJ}\" */;")
w("\t\t\tbuildPhases = (")
w(f"\t\t\t\t{sources_phase} /* Sources */,")
w(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
w(f"\t\t\t\t{resources_phase} /* Resources */,")
w("\t\t\t);")
w("\t\t\tbuildRules = (")
w("\t\t\t);")
w("\t\t\tdependencies = (")
w("\t\t\t);")
w(f"\t\t\tname = {PROJ};")
w(f"\t\t\tproductName = {PROJ};")
w(f"\t\t\tproductReference = {product_id} /* {PROJ}.app */;")
w("\t\t\tproductType = \"com.apple.product-type.application\";")
w("\t\t};")
w("/* End PBXNativeTarget section */")

# PBXProject
w("\n/* Begin PBXProject section */")
w(f"\t\t{proj_id} /* Project object */ = {{")
w("\t\t\tisa = PBXProject;")
w("\t\t\tattributes = {")
w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
w("\t\t\t\tLastSwiftUpdateCheck = 1600;")
w("\t\t\t\tLastUpgradeCheck = 1600;")
w("\t\t\t\tTargetAttributes = {")
w(f"\t\t\t\t\t{target_id} = {{")
w("\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;")
w("\t\t\t\t\t};")
w("\t\t\t\t};")
w("\t\t\t};")
w(f"\t\t\tbuildConfigurationList = {proj_cfg_list} /* Build configuration list for PBXProject \"{PROJ}\" */;")
w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
w("\t\t\tdevelopmentRegion = en;")
w("\t\t\thasScannedForEncodings = 0;")
w("\t\t\tknownRegions = (")
w("\t\t\t\ten,")
w("\t\t\t\tBase,")
w("\t\t\t);")
w(f"\t\t\tmainGroup = {main_group};")
w(f"\t\t\tproductRefGroup = {products_group} /* Products */;")
w("\t\t\tprojectDirPath = \"\";")
w("\t\t\tprojectRoot = \"\";")
w("\t\t\ttargets = (")
w(f"\t\t\t\t{target_id} /* {PROJ} */,")
w("\t\t\t);")
w("\t\t};")
w("/* End PBXProject section */")

# PBXResourcesBuildPhase
w("\n/* Begin PBXResourcesBuildPhase section */")
w(f"\t\t{resources_phase} /* Resources */ = {{")
w("\t\t\tisa = PBXResourcesBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
for f in resources:
    w(f"\t\t\t\t{build_files[f]} /* {f} in Resources */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXResourcesBuildPhase section */")

# PBXSourcesBuildPhase
w("\n/* Begin PBXSourcesBuildPhase section */")
w(f"\t\t{sources_phase} /* Sources */ = {{")
w("\t\t\tisa = PBXSourcesBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
for f in swift_files:
    w(f"\t\t\t\t{build_files[f]} /* {f} in Sources */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXSourcesBuildPhase section */")

# XCBuildConfiguration
def proj_common():
    return [
        "ALWAYS_SEARCH_USER_PATHS = NO;",
        "CLANG_ANALYZER_NONNULL = YES;",
        "CLANG_ENABLE_MODULES = YES;",
        "CLANG_ENABLE_OBJC_ARC = YES;",
        "COPY_PHASE_STRIP = NO;",
        "ENABLE_STRICT_OBJC_MSGSEND = YES;",
        "GCC_NO_COMMON_BLOCKS = YES;",
        "MACOSX_DEPLOYMENT_TARGET = 13.0;",
        "SDKROOT = macosx;",
        "SWIFT_VERSION = 5.0;",
    ]

def target_common():
    return [
        "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
        "CODE_SIGN_IDENTITY = \"-\";",
        "CODE_SIGN_STYLE = Automatic;",
        f"CODE_SIGN_ENTITLEMENTS = {PROJ}/{entitlements};",
        "COMBINE_HIDPI_IMAGES = YES;",
        "CURRENT_PROJECT_VERSION = 1;",
        "ENABLE_HARDENED_RUNTIME = YES;",
        "GENERATE_INFOPLIST_FILE = YES;",
        "INFOPLIST_KEY_LSApplicationCategoryType = \"public.app-category.education\";",
        "INFOPLIST_KEY_NSHumanReadableCopyright = \"\";",
        "INFOPLIST_KEY_NSMainNibFile = \"\";",
        "INFOPLIST_KEY_NSPrincipalClass = NSApplication;",
        "MARKETING_VERSION = 1.0;",
        f"PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};",
        "PRODUCT_NAME = \"$(TARGET_NAME)\";",
        "SWIFT_EMIT_LOC_STRINGS = YES;",
    ]

def emit_config(cfg_id, name, settings, is_debug):
    w(f"\t\t{cfg_id} /* {name} */ = {{")
    w("\t\t\tisa = XCBuildConfiguration;")
    w("\t\t\tbuildSettings = {")
    for s in settings:
        w(f"\t\t\t\t{s}")
    w("\t\t\t};")
    w(f"\t\t\tname = {name};")
    w("\t\t};")

w("\n/* Begin XCBuildConfiguration section */")
proj_debug_settings = proj_common() + [
    "DEBUG_INFORMATION_FORMAT = dwarf;",
    "ENABLE_TESTABILITY = YES;",
    "GCC_DYNAMIC_NO_PIC = NO;",
    "GCC_OPTIMIZATION_LEVEL = 0;",
    "GCC_PREPROCESSOR_DEFINITIONS = (\"DEBUG=1\", \"$(inherited)\");",
    "MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;",
    "ONLY_ACTIVE_ARCH = YES;",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS = \"DEBUG $(inherited)\";",
    "SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";",
]
proj_release_settings = proj_common() + [
    "DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";",
    "ENABLE_NS_ASSERTIONS = NO;",
    "MTL_ENABLE_DEBUG_INFO = NO;",
    "SWIFT_COMPILATION_MODE = wholemodule;",
]
emit_config(proj_debug, "Debug", proj_debug_settings, True)
emit_config(proj_release, "Release", proj_release_settings, False)
emit_config(target_debug, "Debug", target_common(), True)
emit_config(target_release, "Release", target_common(), False)
w("/* End XCBuildConfiguration section */")

# XCConfigurationList
w("\n/* Begin XCConfigurationList section */")
w(f"\t\t{proj_cfg_list} /* Build configuration list for PBXProject \"{PROJ}\" */ = {{")
w("\t\t\tisa = XCConfigurationList;")
w("\t\t\tbuildConfigurations = (")
w(f"\t\t\t\t{proj_debug} /* Debug */,")
w(f"\t\t\t\t{proj_release} /* Release */,")
w("\t\t\t);")
w("\t\t\tdefaultConfigurationIsVisible = 0;")
w("\t\t\tdefaultConfigurationName = Release;")
w("\t\t};")
w(f"\t\t{target_cfg_list} /* Build configuration list for PBXNativeTarget \"{PROJ}\" */ = {{")
w("\t\t\tisa = XCConfigurationList;")
w("\t\t\tbuildConfigurations = (")
w(f"\t\t\t\t{target_debug} /* Debug */,")
w(f"\t\t\t\t{target_release} /* Release */,")
w("\t\t\t);")
w("\t\t\tdefaultConfigurationIsVisible = 0;")
w("\t\t\tdefaultConfigurationName = Release;")
w("\t\t};")
w("/* End XCConfigurationList section */")

w("\t};")
w(f"\trootObject = {proj_id} /* Project object */;")
w("}")

os.makedirs(os.path.join(ROOT, f"{PROJ}.xcodeproj"), exist_ok=True)
out = os.path.join(ROOT, f"{PROJ}.xcodeproj", "project.pbxproj")
with open(out, "w") as fh:
    fh.write("\n".join(L) + "\n")
print("Wrote", out)
print("Sources:", ", ".join(swift_files))
